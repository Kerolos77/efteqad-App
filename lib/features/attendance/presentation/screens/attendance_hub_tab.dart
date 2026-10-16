import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/attendance_session_model.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/repositories/attendance_repository.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/session/session_cubit.dart';
import '../widgets/attendance_active_sessions_section.dart';
import '../widgets/attendance_date_selector_bar.dart';
import '../widgets/attendance_history_section.dart';
import '../widgets/attendance_hub_header.dart';
import 'attendance_screen.dart';

class AttendanceHubTab extends StatefulWidget {
  final String? fixedGrade;
  final AttendanceRepository? repository;

  const AttendanceHubTab({super.key, this.fixedGrade, this.repository});

  @override
  State<AttendanceHubTab> createState() => _AttendanceHubTabState();
}

class _AttendanceHubTabState extends State<AttendanceHubTab> {
  late final AttendanceRepository _repository =
      widget.repository ?? FirestoreAttendanceRepository();
  late String _selectedGrade;
  late DateTime _selectedDate = _defaultSessionDate();
  bool _initializedGrade = false;

  static DateTime _defaultSessionDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    _selectedGrade = widget.fixedGrade ?? AppConstants.grade1st;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedGrade) {
      final session = context.read<SessionCubit>().state;
      if (widget.fixedGrade != null) {
        _selectedGrade = widget.fixedGrade!;
      } else if (!session.isStageAdmin &&
          session.grade != null &&
          session.grade!.isNotEmpty) {
        _selectedGrade = session.grade!;
      }
      _initializedGrade = true;
    }
  }

  @override
  void didUpdateWidget(covariant AttendanceHubTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fixedGrade != null && widget.fixedGrade != _selectedGrade) {
      _selectedGrade = widget.fixedGrade!;
    }
  }

  String _gradeLabel(BuildContext context, String grade, [ServiceModel? service]) {
    if (service != null) {
      final found = service.grades.where((g) => g.id == grade).firstOrNull;
      if (found != null && found.name.isNotEmpty) return found.name;
    }
    switch (grade) {
      case AppConstants.grade1st:
        return context.tr.grade1stName;
      case AppConstants.grade2nd:
        return context.tr.grade2ndName;
      case AppConstants.grade3rd:
        return context.tr.grade3rdName;
      default:
        return grade;
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = _selectedDate.isAfter(today) ? today : _selectedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2, 1, 1),
      lastDate: today,
    );
    if (picked != null && mounted) {
      final pickedDay = DateTime(picked.year, picked.month, picked.day);
      setState(() {
        _selectedDate = pickedDay.isAfter(today) ? today : pickedDay;
      });
    }
  }

  Future<void> _openSession({
    required DateTime date,
    required String sessionType,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(date.year, date.month, date.day);
    if (targetDay.isAfter(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يمكن رصد الحضور والغياب ليوم قادم بعد اليوم الحالي'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }
    final sessionCubit = context.read<SessionCubit>();
    final session = sessionCubit.state;
    final dayStr = DateFormat('yyyy-MM-dd').format(targetDay);
    final expectedTaskType =
        sessionType == 'qoddas' ? 'attendance_qoddas' : 'attendance_khedma';

    TaskModel? matchingTask;
    try {
      final tasks = await FirestoreService()
          .getTasksForGradeStream(_selectedGrade, serviceId: session.serviceId)
          .first
          .timeout(const Duration(seconds: 2));
      matchingTask = tasks.where((t) {
        if (t.isCompleted || t.status != 'active') return false;
        if (t.type != expectedTaskType) return false;
        final tDay = t.attendanceDay ??
            (t.dueDate != null
                ? DateFormat('yyyy-MM-dd').format(t.dueDate!)
                : null);
        if (tDay != dayStr) return false;
        if (session.isServant && t.assignedKhademId != session.userId) {
          return false;
        }
        return true;
      }).firstOrNull;
    } catch (_) {}

    if (!mounted) return;

    if (matchingTask != null) {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => BlocProvider.value(
            value: sessionCubit,
            child: AttendanceScreen(
              task: matchingTask!,
              repository: _repository,
            ),
          ),
        ),
      );
    } else {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => BlocProvider.value(
            value: sessionCubit,
            child: AttendanceScreen.direct(
              grade: _selectedGrade,
              date: targetDay,
              sessionType: sessionType,
              repository: _repository,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = context.watch<SessionCubit>().state;
    final currentUid = session.userId ?? '';
    final isStageAdmin = widget.fixedGrade == null && session.isStageAdmin;
    final dayStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return StreamBuilder<ServiceModel?>(
      stream: FirestoreService().watchService(session.serviceId),
      builder: (context, serviceSnap) {
        final service = serviceSnap.data;
        final grades = (service != null && service.grades.isNotEmpty)
            ? service.grades.map((g) => g.id).toList()
            : [
                AppConstants.grade1st,
                AppConstants.grade2nd,
                AppConstants.grade3rd,
              ];

        return StreamBuilder<List<AttendanceSessionModel>>(
          stream: _repository.watchGradeAttendance(
            grade: _selectedGrade,
            serviceId: session.serviceId,
          ),
          builder: (context, snapshot) {
            final sessions = snapshot.data ?? const <AttendanceSessionModel>[];
            final khedmaId = AttendanceSessionModel.generateSessionId(
              date: dayStr,
              type: 'khedma',
              grade: _selectedGrade,
            );
            final qoddasId = AttendanceSessionModel.generateSessionId(
              date: dayStr,
              type: 'qoddas',
              grade: _selectedGrade,
            );

            AttendanceSessionModel? findSession(String id, String type) {
              for (final s in sessions) {
                if (s.id == id || (s.date == dayStr && s.type == type)) {
                  return s;
                }
              }
              return null;
            }

            final todayKhedma = findSession(khedmaId, 'khedma');
            final todayQoddas = findSession(qoddasId, 'qoddas');

            return SingleChildScrollView(
              padding: EdgeInsetsDirectional.fromSTEB(16.w, 12.h, 16.w, 85.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AttendanceHubHeader(
                    gradeLabel: _gradeLabel(context, _selectedGrade, service),
                    isStageAdmin: isStageAdmin,
                    grades: grades,
                    selectedGrade: _selectedGrade,
                    getGradeLabel: (g) => _gradeLabel(context, g, service),
                    onGradeSelected: (g) => setState(() => _selectedGrade = g),
                    isDark: isDark,
                  ),
                  SizedBox(height: 14.h),
                  AttendanceDateSelectorBar(
                    selectedDate: _selectedDate,
                    onPickDate: _pickDate,
                    isDark: isDark,
                  ),
                  SizedBox(height: 14.h),
                  AttendanceActiveSessionsSection(
                    todayKhedma: todayKhedma,
                    todayQoddas: todayQoddas,
                    currentUid: currentUid,
                    isDark: isDark,
                    onOpenKhedma: () => _openSession(
                      date: _selectedDate,
                      sessionType: 'khedma',
                    ),
                    onOpenQoddas: () => _openSession(
                      date: _selectedDate,
                      sessionType: 'qoddas',
                    ),
                  ),
                  SizedBox(height: 20.h),
                  AttendanceHistorySection(
                    sessions: sessions,
                    isLoading: snapshot.connectionState == ConnectionState.waiting,
                    currentUid: currentUid,
                    isDark: isDark,
                    onOpenSession: (s) => _openSession(
                      date: DateTime.tryParse(s.date) ?? _selectedDate,
                      sessionType: s.type,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
