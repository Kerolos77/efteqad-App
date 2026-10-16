import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/models/attendance_session_model.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/repositories/attendance_repository.dart';
import '../../../../core/services/attendance_roster_repository.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../core/widgets/async_content.dart';
import '../../application/attendance_access.dart';
import '../../application/attendance_action_handler.dart';
import '../../application/attendance_cubit.dart';
import '../../application/attendance_grade_helper.dart';
import '../../application/attendance_roster_loader.dart';
import '../widgets/attendance_app_bar_actions.dart';
import '../widgets/attendance_app_bar_title.dart';
import '../widgets/attendance_roster_content.dart';

class AttendanceScreen extends StatefulWidget {
  final TaskModel task;
  final AttendanceRepository? repository;
  final Future<List<AttendanceRosterRow>> Function(String)? loadRoster;
  final bool isDirectSession;

  const AttendanceScreen({
    super.key,
    required this.task,
    this.repository,
    this.loadRoster,
    this.isDirectSession = false,
  });

  factory AttendanceScreen.direct({
    Key? key,
    required String grade,
    required DateTime date,
    required String sessionType,
    AttendanceRepository? repository,
  }) {
    final dayStr = DateFormat('yyyy-MM-dd').format(date);
    return AttendanceScreen(
      key: key,
      isDirectSession: true,
      repository: repository,
      task: TaskModel(
        id: 'direct_${dayStr}_${sessionType}_$grade',
        title: sessionType == 'qoddas' ? 'حضور القداس' : 'حضور الخدمة',
        assignedKhademId: '',
        assignedKhademName: '',
        grade: grade,
        createdById: '',
        createdByName: '',
        type: sessionType == 'qoddas'
            ? 'attendance_qoddas'
            : 'attendance_khedma',
        dueDate: date,
        attendanceDay: dayStr,
        status: 'active',
        isCompleted: false,
        createdAt: date,
      ),
    );
  }

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with WidgetsBindingObserver {
  late final DateTime _dueDate;
  late final String _sessionDate;
  late final String _sessionType;
  late final String _sessionGrade;
  late final String _sessionId;

  late final AttendanceRepository _attendanceRepository;
  late final AttendanceCubit _attendanceCubit;
  late Stream<List<AttendanceRosterRow>> _makhdomeenStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _dueDate = widget.task.dueDate ?? _getNextFriday();
    _sessionDate = widget.task.attendanceDay ??
        DateFormat('yyyy-MM-dd').format(_dueDate.toUtc());
    _sessionType = widget.task.isMassAttendance ? 'qoddas' : 'khedma';
    _sessionGrade = widget.task.grade;

    _sessionId = AttendanceSessionModel.generateSessionId(
      date: _sessionDate,
      type: _sessionType,
      grade: _sessionGrade,
    );

    _attendanceRepository =
        widget.repository ?? FirestoreAttendanceRepository();

    final sessionCubit = context.read<SessionCubit>();
    final session = sessionCubit.state;
    final khademName = session.profile?.name ?? '';

    _attendanceCubit = AttendanceCubit(
      repository: _attendanceRepository,
      sessionId: _sessionId,
      grade: _sessionGrade,
      date: _sessionDate,
      type: _sessionType,
      khademId: session.userId ?? '',
      khademName: khademName,
      taskId: widget.isDirectSession ? null : widget.task.id,
      userId: () => sessionCubit.state.userId ?? '',
    );

    _makhdomeenStream = _rosterForCurrentTask();

    if (_isUserAuthorized()) {
      unawaited(_attendanceCubit.acquireLockAndStartHeartbeat());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      unawaited(_attendanceCubit.releaseLock());
    } else if (state == AppLifecycleState.resumed) {
      if (_isUserAuthorized() && !_attendanceCubit.state.isFinalized) {
        unawaited(_attendanceCubit.acquireLockAndStartHeartbeat());
      }
    }
  }

  Stream<List<AttendanceRosterRow>> _rosterForCurrentTask() {
    if (!widget.isDirectSession &&
        (widget.task.isCompleted || widget.task.status != 'active')) {
      return Stream.value([]);
    }
    return AttendanceRosterLoader.load(
      context: context,
      task: widget.task,
      sessionGrade: _sessionGrade,
      isDirectSession: widget.isDirectSession,
      customLoader: widget.loadRoster,
    ).asStream();
  }

  @override
  void didUpdateWidget(covariant AttendanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id == widget.task.id &&
        oldWidget.task.isCompleted != widget.task.isCompleted) {
      _makhdomeenStream = _rosterForCurrentTask();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_attendanceCubit.releaseLock());
    _attendanceCubit.close();
    super.dispose();
  }

  DateTime _getNextFriday() {
    final now = DateTime.now();
    int daysUntilFriday = (DateTime.friday - now.weekday) % 7;
    return now.add(Duration(days: daysUntilFriday));
  }

  bool _isUserAuthorized() {
    return canAuthorizeAttendanceSession(
      session: context.read<SessionCubit>().state,
      task: widget.task,
      sessionGrade: _sessionGrade,
      isDirectSession: widget.isDirectSession,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = context.read<SessionCubit>().state;
    final currentUid = session.userId ?? '';
    final isAuthorized = _isUserAuthorized();
    final canReopen = canReopenAttendanceSession(
      session: session,
      task: widget.task,
      sessionGrade: _sessionGrade,
    );
    final isAdmin = isAttendanceAdminUser(
      session: session,
      sessionGrade: _sessionGrade,
    );

    final actionHandler = AttendanceActionHandler(
      context: context,
      cubit: _attendanceCubit,
      currentUid: currentUid,
      taskId: widget.isDirectSession ? null : widget.task.id,
    );

    return BlocProvider.value(
      value: _attendanceCubit,
      child: BlocBuilder<AttendanceCubit, AttendanceState>(
        builder: (context, attendanceState) {
          final isLockedByOther = attendanceState.isLockedByOther(currentUid);
          final canEdit =
              isAuthorized && !attendanceState.isFinalized && !isLockedByOther;

          return Scaffold(
            backgroundColor: isDark
                ? AppColors.backgroundDark
                : AppColors.backgroundLight,
            appBar: AppBar(
              toolbarHeight: 56.h *
                  MediaQuery.textScalerOf(context).scale(1) *
                  MediaQuery.textScalerOf(context).scale(1),
              title: AttendanceAppBarTitle(
                sessionType: _sessionType,
                gradeLabel:
                    AttendanceGradeHelper.getGradeLabel(context, _sessionGrade),
                dueDate: _dueDate,
              ),
              actions: [
                AttendanceAppBarActions(
                  canReopen: canReopen,
                  canFinalize: canEdit &&
                      attendanceState.hasLoadedRemote &&
                      attendanceState.saveErrors.isEmpty &&
                      attendanceState.pendingById.isEmpty &&
                      attendanceState.pendingExcusesById.isEmpty,
                  attendanceState: attendanceState,
                  onReopen: () => actionHandler.reopenAttendance(
                    sessionId: _sessionId,
                    sessionGrade: _sessionGrade,
                    repository: _attendanceRepository,
                  ),
                  onFinalize: actionHandler.finalizeAttendance,
                ),
              ],
            ),
            body: StreamBuilder<List<AttendanceRosterRow>>(
              stream: _makhdomeenStream,
              builder: (context, makhdomeenSnap) {
                if (!attendanceState.hasLoadedRemote &&
                    attendanceState.status == 'error') {
                  return AsyncContent<void>(
                    isLoading: false,
                    error: const AppFailure(
                      code: 'attendance-load',
                      message: 'Attendance could not load.',
                      retryable: true,
                    ),
                    onRetry: _attendanceCubit.retryLoading,
                    builder: (_, _) => const SizedBox.shrink(),
                  );
                }
                if (makhdomeenSnap.connectionState == ConnectionState.waiting &&
                    !makhdomeenSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (makhdomeenSnap.hasError) {
                  return AsyncContent<List<AttendanceRosterRow>>(
                    isLoading: false,
                    error: makhdomeenSnap.error,
                    onRetry: () => setState(() {
                      _makhdomeenStream = _rosterForCurrentTask();
                    }),
                    builder: (_, rows) => const SizedBox.shrink(),
                  );
                }

                final allMakhdomeen = makhdomeenSnap.data ?? [];

                return AttendanceRosterContent(
                  allMakhdomeen: allMakhdomeen,
                  attendanceState: attendanceState,
                  isLockedByOther: isLockedByOther,
                  canEdit: canEdit,
                  isAuthorized: isAuthorized,
                  isAdmin: isAdmin,
                  isDark: isDark,
                  sessionType: _sessionType,
                  getGradeLabel: (g) =>
                      AttendanceGradeHelper.getGradeLabel(context, g),
                  getGradeShortLabel: (g) =>
                      AttendanceGradeHelper.getGradeShortLabel(context, g),
                  onToggleAttendance: actionHandler.toggleAttendance,
                  onExcuseTap: actionHandler.showExcuseDialog,
                  onTakeOverLock: () => _attendanceCubit
                      .acquireLockAndStartHeartbeat(force: true),
                  onFinalizeAttendance: actionHandler.finalizeAttendance,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
