import 'dart:async';
import 'package:efteqad/core/widgets/async_content.dart';
import 'package:efteqad/core/localization/app_formatters.dart';
import 'package:efteqad/core/errors/app_failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/attendance_session_model.dart';
import '../../../../core/services/attendance_roster_repository.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/repositories/attendance_repository.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/trusted_mutations.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../core/utils/color_generator.dart';
import '../../application/attendance_cubit.dart';
import '../../application/attendance_access.dart';

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
    required String sessionType, // 'khedma' or 'qoddas'
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
  late final String _sessionType; // 'khedma' or 'qoddas'
  late final String _sessionGrade; // '1st', '2nd', '3rd', or 'all'
  late final String _sessionId;

  late final AttendanceRepository _attendanceRepository;
  late final AttendanceCubit _attendanceCubit;
  late Stream<List<AttendanceRosterRow>> _makhdomeenStream;

  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'present', 'absent', 'excused'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _dueDate = widget.task.dueDate ?? _getNextFriday();
    _sessionDate =
        widget.task.attendanceDay ??
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

    // Acquire the online Lease Lock and start the 20s heartbeat if authorized.
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
      // Immediately release the flag if the phone locks or app goes to background.
      unawaited(_attendanceCubit.releaseLock());
    } else if (state == AppLifecycleState.resumed) {
      if (_isUserAuthorized() && !_attendanceCubit.state.isFinalized) {
        unawaited(_attendanceCubit.acquireLockAndStartHeartbeat());
      }
    }
  }

  Future<List<AttendanceRosterRow>> _loadGradeRoster(String taskId) async {
    if (widget.loadRoster != null) {
      return widget.loadRoster!(taskId);
    }
    final session = context.read<SessionCubit>().state;

    // 1. If it's a real assigned task, try loading through AttendanceRosterRepository:
    if (!widget.isDirectSession &&
        taskId.isNotEmpty &&
        !taskId.startsWith('direct_')) {
      try {
        final all = await AttendanceRosterRepository().load(taskId);
        if (_sessionGrade == 'all') return all;
        return all.where((r) => r.grade == _sessionGrade).toList();
      } catch (_) {
        // Fall back below if roster callable fails or is offline
      }
    }

    // 2. Direct session or fallback loading based on role:
    try {
      if (session.isStageAdmin ||
          (session.isGradeAdmin &&
              (session.grade == _sessionGrade || _sessionGrade == 'all'))) {
        final list = _sessionGrade == 'all'
            ? await FirestoreService().getMakhdomeenStream().first
            : await FirestoreService().getMakhdomeenByGrade(_sessionGrade);
        return list
            .where((m) => m.active)
            .map(
              (m) => AttendanceRosterRow(
                id: m.id,
                fullName: m.fullName,
                grade: m.grade,
                active: m.active,
              ),
            )
            .toList();
      } else if (session.userId != null) {
        // Normal servant: load their assigned students for this grade
        final list = await FirestoreService()
            .getMakhdomeenForKhademStream(session.userId!)
            .first;
        return list
            .where((m) =>
                m.active &&
                (_sessionGrade == 'all' || m.grade == _sessionGrade))
            .map(
              (m) => AttendanceRosterRow(
                id: m.id,
                fullName: m.fullName,
                grade: m.grade,
                active: m.active,
              ),
            )
            .toList();
      }
    } catch (_) {
      return [];
    }
    return [];
  }

  Stream<List<AttendanceRosterRow>> _rosterForCurrentTask() {
    if (!widget.isDirectSession &&
        (widget.task.isCompleted || widget.task.status != 'active')) {
      return Stream.value([]);
    }
    return _loadGradeRoster(widget.task.id).asStream();
  }

  @override
  void didUpdateWidget(covariant AttendanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The router replaces state for identity/scope/date changes, but retains
    // this screen across completion changes from another administrator.
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
    final session = context.read<SessionCubit>().state;
    if (widget.isDirectSession) {
      return canManageGradeAttendance(session, _sessionGrade, session.userId);
    }
    if (!widget.task.isCompleted && widget.task.status == 'active') {
      return canManageGradeAttendance(session, _sessionGrade, session.userId) ||
          canManageAttendance(session, widget.task, session.userId);
    }
    return canManageAttendance(session, widget.task, session.userId);
  }

  bool get _canReopen {
    final session = context.read<SessionCubit>().state;
    return session.isActive &&
        widget.task.status != 'cancelled' &&
        (session.isStageAdmin ||
            (session.isGradeAdmin && session.grade == _sessionGrade));
  }

  bool get _isAdmin {
    final session = context.read<SessionCubit>().state;
    return session.isActive &&
        (session.isStageAdmin ||
            (session.isGradeAdmin && session.grade == _sessionGrade));
  }

  Future<void> _handleReopenAttendance() async {
    var reason = '';
    final operationId = newOperationId('reopen');
    var saving = false;
    Object? error;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(context.tr.reopenAttendance),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) => reason = value,
                enabled: !saving && error == null,
                maxLength: 500,
                decoration: InputDecoration(labelText: context.tr.reopenReason),
              ),
              if (error != null)
                Text(
                  AppFailure.fromException(error!).localizedMessage(context.tr),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: Text(context.tr.messageCancel),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (reason.trim().isEmpty) return;
                      setDialogState(() {
                        saving = true;
                      });
                      try {
                        await _attendanceRepository.reopenAttendance(
                          sessionId: _sessionId,
                          grade: _sessionGrade,
                          reason: reason.trim(),
                          operationId: operationId,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        if (ctx.mounted) {
                          setDialogState(() {
                            saving = false;
                            error = e;
                          });
                        }
                      }
                    },
              child: Text(context.tr.reopenAttendanceAction),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleAttendance(
    AttendanceRosterRow makhdom,
    bool isPresent,
  ) async {
    final currentUid = context.read<SessionCubit>().state.userId ?? '';
    if (_attendanceCubit.state.isLockedByOther(currentUid)) {
      final holder = _attendanceCubit.state.lockedByKhademName ?? 'خادم آخر';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يقوم حالياً $holder برصد الغياب لهذه الفرقة.'),
          backgroundColor: AppConstants.warningColor,
        ),
      );
      return;
    }

    if (_attendanceCubit.state.isFinalized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr.messageThisSessionHasBeenFinalizedAndCannot),
          backgroundColor: AppConstants.warningColor,
        ),
      );
      return;
    }

    try {
      await _attendanceCubit.setPresence(
        makhdomId: makhdom.id,
        isPresent: isPresent,
      );
      if (mounted && _attendanceCubit.state.saveErrors.containsKey(makhdom.id)) {
        final err = _attendanceCubit.state.saveErrors[makhdom.id];
        if (err != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppFailure.fromException(err).localizedMessage(context.tr),
              ),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppFailure.fromException(e).localizedMessage(context.tr),
            ),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _showExcuseDialog(
    AttendanceRosterRow makhdom,
    AttendanceExcuse? existingExcuse,
  ) async {
    final controller = TextEditingController(text: existingExcuse?.note ?? '');
    const quickReasons = ['مريض', 'مسافر', 'امتحانات', 'ظروف عائلية'];

    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.assignment_late_outlined,
                color: AppConstants.accentGold,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تسجيل عذر غياب — ${makhdom.fullName}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'اختر سبباً سريعاً أو اكتب تفاصيل العذر:',
                style: TextStyle(fontSize: 12, color: AppConstants.textMuted),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: quickReasons.map((reason) {
                  final selected = controller.text.trim() == reason;
                  return ActionChip(
                    label: Text(
                      reason,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: selected
                            ? Colors.white
                            : AppConstants.primaryLight,
                      ),
                    ),
                    backgroundColor: selected
                        ? AppConstants.primaryLight
                        : AppConstants.primaryLight.withValues(alpha: 0.1),
                    onPressed: () {
                      setDialogState(() {
                        controller.text = reason;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 2,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'اكتب سبب الاعتذار هنا...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            if (existingExcuse != null)
              TextButton.icon(
                onPressed: () => Navigator.pop(ctx, '__CLEAR__'),
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppConstants.errorColor,
                ),
                label: const Text(
                  'إلغاء العذر',
                  style: TextStyle(color: AppConstants.errorColor),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text(context.tr.messageCancel),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                Navigator.pop(ctx, text);
              },
              child: const Text('حفظ العذر'),
            ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;
    try {
      await _attendanceCubit.setExcuse(
        makhdomId: makhdom.id,
        note: result == '__CLEAR__' ? null : result,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppFailure.fromException(e).localizedMessage(context.tr),
            ),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _handleFinalizeAttendance() async {
    if (_attendanceCubit.state.pendingById.isNotEmpty ||
        _attendanceCubit.state.pendingExcusesById.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr.messagePleaseWaitForPendingSavesToFinish),
          backgroundColor: AppConstants.warningColor,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr.messageFinalizeAttendance),
        content: Text(context.tr.messageAreYouSureYouWantToFinalize),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr.messageCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppConstants.successColor,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr.messageConfirmFinalization),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _attendanceCubit.finalizeAttendance(
          taskId: widget.isDirectSession ? null : widget.task.id,
        );
        await _attendanceCubit.releaseLock();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr.messageAttendanceFinalizedSuccessfully),
              backgroundColor: AppConstants.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppFailure.fromException(e).localizedMessage(context.tr),
              ),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
      }
    }
  }

  String _getGradeLabel(String grade) {
    switch (grade) {
      case AppConstants.grade1st:
        return context.tr.grade1stName;
      case AppConstants.grade2nd:
        return context.tr.grade2ndName;
      case AppConstants.grade3rd:
        return context.tr.grade3rdName;
      default:
        return context.tr.messageSecondary;
    }
  }

  Widget _buildStatusBadge(AttendanceState state) {
    if (!state.hasLoadedRemote) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 8,
              height: 8,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                context.tr.messageLoading,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state.isFinalized) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppConstants.primaryNavy.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppConstants.primaryNavy.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_rounded,
              size: 12,
              color: AppConstants.primaryNavy,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                context.tr.messageFinalized,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryNavy,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state.status == 'saving' ||
        state.pendingById.isNotEmpty ||
        state.pendingExcusesById.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppConstants.warningColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppConstants.warningColor.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 8,
              height: 8,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppConstants.warningColor,
              ),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                context.tr.messageSaving,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.warningColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state.status == 'error' || state.saveErrors.isNotEmpty) {
      return InkWell(
        onTap: () {
          final firstError = state.saveErrors.values.firstOrNull;
          if (firstError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppFailure.fromException(firstError).localizedMessage(context.tr),
                ),
                backgroundColor: AppConstants.errorColor,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppConstants.errorColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppConstants.errorColor.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 10,
                color: AppConstants.errorColor,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  context.tr.messageSaveError,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.errorColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppConstants.successColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppConstants.successColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppConstants.successColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              context.tr.autoSavedNotice,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppConstants.successColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAuthorized = _isUserAuthorized();
    final currentUid = context.read<SessionCubit>().state.userId ?? '';

    return BlocProvider.value(
      value: _attendanceCubit,
      child: BlocBuilder<AttendanceCubit, AttendanceState>(
        builder: (context, attendanceState) {
          final isLockedByOther = attendanceState.isLockedByOther(currentUid);
          final canEdit =
              isAuthorized && !attendanceState.isFinalized && !isLockedByOther;

          return Scaffold(
            backgroundColor: isDark
                ? AppConstants.backgroundDark
                : AppConstants.backgroundLight,
            appBar: AppBar(
              toolbarHeight:
                  56 *
                  MediaQuery.textScalerOf(context).scale(1) *
                  MediaQuery.textScalerOf(context).scale(1),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _sessionType == 'qoddas'
                        ? context.tr.attendanceScreenTitleMass
                        : '${context.tr.attendanceScreenTitleService} (${_getGradeLabel(_sessionGrade)})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    AppFormatters(
                      Localizations.localeOf(context),
                    ).formatDayAndDate(_dueDate),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppConstants.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                if (_canReopen &&
                    attendanceState.isFinalized &&
                    attendanceState.hasLoadedRemote)
                  IconButton(
                    icon: const Icon(Icons.lock_open_rounded),
                    tooltip: context.tr.reopenAttendance,
                    onPressed: _handleReopenAttendance,
                  ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.35,
                  ),
                  child: _buildStatusBadge(attendanceState),
                ),
                if (canEdit &&
                    attendanceState.hasLoadedRemote &&
                    attendanceState.saveErrors.isEmpty &&
                    attendanceState.pendingById.isEmpty &&
                    attendanceState.pendingExcusesById.isEmpty)
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline, size: 22),
                    tooltip: context.tr.messageFinalizeAttendance,
                    onPressed: _handleFinalizeAttendance,
                  ),
                const SizedBox(width: 4),
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
                      _makhdomeenStream = _loadGradeRoster(
                        widget.task.id,
                      ).asStream();
                    }),
                    builder: (_, rows) => const SizedBox.shrink(),
                  );
                }
                final allMakhdomeen = makhdomeenSnap.data ?? [];
                final attendedList = allMakhdomeen
                    .where((m) => attendanceState.isAttended(m.id))
                    .toList();
                final excusedList = allMakhdomeen
                    .where((m) => attendanceState.isExcused(m.id))
                    .toList();
                final absentCount =
                    (allMakhdomeen.length -
                            attendedList.length -
                            excusedList.length)
                        .clamp(0, allMakhdomeen.length);

                final filteredList = allMakhdomeen.where((m) {
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    if (!m.fullName.toLowerCase().contains(q)) return false;
                  }
                  if (_statusFilter == 'present') {
                    return attendanceState.isAttended(m.id);
                  }
                  if (_statusFilter == 'excused') {
                    return attendanceState.isExcused(m.id);
                  }
                  if (_statusFilter == 'absent') {
                    return !attendanceState.isAttended(m.id) &&
                        !attendanceState.isExcused(m.id);
                  }
                  return true;
                }).toList();

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      children: [
                    // شريط القفل الذكي إذا كان هناك خادم آخر يرصد حالياً
                    if (isLockedByOther)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 14,
                        ),
                        color: AppConstants.warningColor.withValues(
                          alpha: 0.16,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lock_person_rounded,
                              size: 18,
                              color: AppConstants.warningColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'يقوم حالياً "${attendanceState.lockedByKhademName ?? 'خادم آخر'}" برصد الغياب (وضع المشاهدة اللحظية)',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppConstants.warningColor,
                                ),
                              ),
                            ),
                            if (_isAdmin)
                              TextButton(
                                onPressed: () => _attendanceCubit
                                    .acquireLockAndStartHeartbeat(force: true),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'استلام الرصد',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                    // غير مصرح بالتعديل تنبيه
                    if (!isAuthorized)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        color: AppConstants.warningColor.withValues(
                          alpha: 0.15,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppConstants.warningColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                context.tr.notAuthorizedAttendance,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.warningColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // تنبيه جلسة معتمدة
                    if (attendanceState.isFinalized)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        color: AppConstants.successColor.withValues(
                          alpha: 0.15,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lock_outline,
                              size: 16,
                              color: AppConstants.successColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                context
                                    .tr
                                    .messageAttendanceSessionIsFinalizedAndLockedRead,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.successColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // =================== الجزء العلوي المدمج ===================
                    _buildTopAttendedSection(
                      attendedList: attendedList,
                      excusedCount: excusedList.length,
                      absentCount: absentCount,
                      totalCount: allMakhdomeen.length,
                      isDark: isDark,
                      isAuthorized: canEdit,
                    ),

                    // =================== البحث وشرائح الفلترة السريعة ===================
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        8,
                        16,
                        4,
                      ),
                      child: TextField(
                        onChanged: (val) =>
                            setState(() => _searchQuery = val.trim()),
                        decoration: InputDecoration(
                          hintText: context.tr.messageSearchByName,
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 20,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () =>
                                      setState(() => _searchQuery = ''),
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        2,
                        16,
                        6,
                      ),
                      child: Row(
                        children: [
                          _buildFilterChip(
                            key: 'all',
                            label: 'الكل (${allMakhdomeen.length})',
                            isDark: isDark,
                          ),
                          const SizedBox(width: 6),
                          _buildFilterChip(
                            key: 'absent',
                            label: 'غائب ($absentCount)',
                            isDark: isDark,
                          ),
                          const SizedBox(width: 6),
                          _buildFilterChip(
                            key: 'present',
                            label: 'حاضر (${attendedList.length})',
                            isDark: isDark,
                          ),
                          const SizedBox(width: 6),
                          _buildFilterChip(
                            key: 'excused',
                            label: 'بعذر (${excusedList.length})',
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),

                    // =================== قائمة المخدومين ===================
                    Expanded(
                      child: filteredList.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 44,
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    context.tr.noSearchResults,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                16,
                                0,
                                16,
                                30,
                              ),
                              itemCount: filteredList.length,
                              itemBuilder: (context, index) {
                                final makhdom = filteredList[index];
                                final isAttended = attendanceState.isAttended(
                                  makhdom.id,
                                );
                                final excuse = attendanceState.excuseFor(
                                  makhdom.id,
                                );
                                final isPending = attendanceState.isPending(
                                  makhdom.id,
                                );
                                final hasError = attendanceState.hasError(
                                  makhdom.id,
                                );
                                return _buildMakhdomAttendanceRow(
                                  makhdom: makhdom,
                                  isAttended: isAttended,
                                  excuse: excuse,
                                  isPending: isPending,
                                  hasError: hasError,
                                  isDark: isDark,
                                  isAuthorized: canEdit,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String key,
    required String label,
    required bool isDark,
  }) {
    final selected = _statusFilter == key;
    return InkWell(
      onTap: () => setState(() => _statusFilter = key),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? AppConstants.primaryLight
              : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected
                ? Colors.white
                : (isDark ? Colors.white70 : AppConstants.textDark),
          ),
        ),
      ),
    );
  }

  Widget _buildTopAttendedSection({
    required List<AttendanceRosterRow> attendedList,
    required int excusedCount,
    required int absentCount,
    required int totalCount,
    required bool isDark,
    required bool isAuthorized,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 86, maxHeight: 135),
      margin: const EdgeInsetsDirectional.fromSTEB(16, 6, 16, 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: attendedList.isNotEmpty
              ? AppConstants.primaryLight.withValues(alpha: 0.35)
              : (isDark
                    ? AppConstants.cardBorderDark
                    : AppConstants.cardBorderLight),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppConstants.primaryLight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.how_to_reg_rounded,
                  size: 15,
                  color: AppConstants.primaryLight,
                ),
              ),
              Text(
                context.tr.selectedAttendedHeader,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppConstants.primaryNavy,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  context.tr.totalAttendedCount(
                    attendedList.length,
                    totalCount,
                  ),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              if (excusedCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.accentGold.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'بعذر: $excusedCount',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppConstants.accentGold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 1),
          const SizedBox(height: 6),
          Flexible(
            child: attendedList.isEmpty
                ? Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          size: 16,
                          color: isDark
                              ? Colors.white38
                              : AppConstants.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            context.tr.noAttendedYetHint,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white38
                                  : AppConstants.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: attendedList.map((m) {
                        return Padding(
                          padding: const EdgeInsetsDirectional.only(end: 6),
                          child: _buildAttendedChip(m, isDark, isAuthorized),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendedChip(
    AttendanceRosterRow m,
    bool isDark,
    bool isAuthorized,
  ) {
    final color = ColorGenerator.getColorForId(m.id);

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(6, 4, 10, 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAuthorized)
            InkWell(
              onTap: () => _toggleAttendance(m, false),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(2),
                margin: const EdgeInsetsDirectional.only(start: 4),
                decoration: BoxDecoration(
                  color: AppConstants.errorColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: AppConstants.errorColor,
                ),
              ),
            ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              m.fullName,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppConstants.textDark,
              ),
            ),
          ),
          if (_sessionType == 'qoddas') ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _getGradeShortLabel(m.grade),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getGradeShortLabel(String grade) {
    switch (grade) {
      case AppConstants.grade1st:
        return context.tr.message1st;
      case AppConstants.grade2nd:
        return context.tr.message2nd;
      case AppConstants.grade3rd:
        return context.tr.message3rd;
      default:
        return '';
    }
  }

  Widget _buildMakhdomAttendanceRow({
    required AttendanceRosterRow makhdom,
    required bool isAttended,
    required AttendanceExcuse? excuse,
    required bool isPending,
    required bool hasError,
    required bool isDark,
    required bool isAuthorized,
  }) {
    final khademColor = ColorGenerator.getColorForId(makhdom.id);
    final isExcused = !isAttended && excuse != null;

    return InkWell(
      onTap: isAuthorized && !isPending
          ? () => _toggleAttendance(makhdom, !isAttended)
          : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isAttended
              ? AppConstants.primaryLight.withValues(alpha: isDark ? 0.2 : 0.08)
              : isExcused
              ? AppConstants.accentGold.withValues(alpha: isDark ? 0.16 : 0.08)
              : (isDark ? AppConstants.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasError
                ? AppConstants.errorColor
                : isAttended
                ? AppConstants.primaryLight
                : isExcused
                ? AppConstants.accentGold
                : (isDark
                      ? AppConstants.cardBorderDark
                      : AppConstants.cardBorderLight),
            width: isAttended || isExcused || hasError ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            if (isPending)
              const SizedBox(
                width: 24,
                height: 24,
                child: Padding(
                  padding: EdgeInsets.all(4.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Checkbox(
                value: isAttended,
                activeColor: AppConstants.primaryLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                onChanged: isAuthorized
                    ? (val) => _toggleAttendance(makhdom, val ?? false)
                    : null,
              ),
            const SizedBox(width: 8),

            CircleAvatar(
              radius: 16,
              backgroundColor: khademColor.withValues(alpha: 0.15),
              child: Text(
                makhdom.fullName.isNotEmpty
                    ? makhdom.fullName[0]
                    : context.tr.messageM,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: khademColor,
                ),
              ),
            ),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          makhdom.fullName,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: isAttended || isExcused
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : AppConstants.textDark,
                          ),
                        ),
                      ),
                      if (hasError)
                        InkWell(
                          onTap: () {
                            final err = _attendanceCubit.state.saveErrors[makhdom.id];
                            if (err != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppFailure.fromException(err).localizedMessage(context.tr),
                                  ),
                                  backgroundColor: AppConstants.errorColor,
                                ),
                              );
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.error_outline,
                              size: 16,
                              color: AppConstants.errorColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (excuse != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.event_available_outlined,
                          size: 12,
                          color: AppConstants.accentGold,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'عذر: ${excuse.note}${excuse.byKhademName.isNotEmpty ? ' (${excuse.byKhademName})' : ''}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppConstants.accentGold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_sessionType == 'qoddas')
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: khademColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            _getGradeLabel(makhdom.grade),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: khademColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ),
                ],
              ),
            ),

            if (isAuthorized && !isPending)
              IconButton(
                onPressed: () => _showExcuseDialog(makhdom, excuse),
                tooltip: 'تسجيل عذر غياب',
                icon: Icon(
                  excuse != null
                      ? Icons.speaker_notes_rounded
                      : Icons.edit_note_rounded,
                  size: 20,
                  color: excuse != null
                      ? AppConstants.accentGold
                      : AppConstants.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
