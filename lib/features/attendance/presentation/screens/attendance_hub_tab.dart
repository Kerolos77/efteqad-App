import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/attendance_session_model.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/repositories/attendance_repository.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/session/session_cubit.dart';
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

  String _gradeLabel(BuildContext context, String grade) {
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
          backgroundColor: AppConstants.errorColor,
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
          .getTasksForGradeStream(_selectedGrade)
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
      Navigator.of(context).push(
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
      Navigator.of(context).push(
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

    return StreamBuilder<List<AttendanceSessionModel>>(
      stream: _repository.watchGradeAttendance(grade: _selectedGrade),
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
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 85),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان القسم والفرقة
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryLight.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.how_to_reg_rounded,
                      color: AppConstants.primaryLight,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الحضور والغياب (${_gradeLabel(context, _selectedGrade)})',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppConstants.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'رصد مباشر لخدام الفرقة مع قفل تلقائي لمنع التضارب ودمج ذكي للأوفلاين',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppConstants.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (isStageAdmin) ...[
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final g in [
                        AppConstants.grade1st,
                        AppConstants.grade2nd,
                        AppConstants.grade3rd,
                      ])
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: ChoiceChip(
                            label: Text(
                              _gradeLabel(context, g),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: _selectedGrade == g
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.white70
                                          : AppConstants.textDark),
                              ),
                            ),
                            selected: _selectedGrade == g,
                            selectedColor: AppConstants.primaryLight,
                            onSelected: (_) =>
                                setState(() => _selectedGrade = g),
                          ),
                        ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // شريط اختيار تاريخ الجلسة
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppConstants.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? AppConstants.cardBorderDark
                        : AppConstants.cardBorderLight,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      color: AppConstants.primaryLight,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تاريخ جلسة الرصد',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppConstants.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            AppFormatters(
                              Localizations.localeOf(context),
                            ).formatDayAndDate(_selectedDate),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                      label: const Text(
                        'تغيير اليوم',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // بطاقتا رصد الخدمة والقداس لليوم المحدد
              if (MediaQuery.sizeOf(context).width >= 800)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildSessionActionCard(
                        context: context,
                        title: 'حضور اجتماع الخدمة',
                        subtitle:
                            'رصد حضور المخدومين وأعذار الغياب في اجتماع الخدمة',
                        icon: Icons.fact_check_rounded,
                        accentColor: const Color(0xFF8B5CF6),
                        sessionType: 'khedma',
                        session: todayKhedma,
                        currentUid: currentUid,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildSessionActionCard(
                        context: context,
                        title: 'حضور القداس الإلهي',
                        subtitle:
                            'رصد حضور المخدومين وأعذار الغياب في القداس',
                        icon: Icons.church_rounded,
                        accentColor: AppConstants.accentGold,
                        sessionType: 'qoddas',
                        session: todayQoddas,
                        currentUid: currentUid,
                        isDark: isDark,
                      ),
                    ),
                  ],
                )
              else ...[
                _buildSessionActionCard(
                  context: context,
                  title: 'حضور اجتماع الخدمة',
                  subtitle: 'رصد حضور المخدومين وأعذار الغياب في اجتماع الخدمة',
                  icon: Icons.fact_check_rounded,
                  accentColor: const Color(0xFF8B5CF6),
                  sessionType: 'khedma',
                  session: todayKhedma,
                  currentUid: currentUid,
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _buildSessionActionCard(
                  context: context,
                  title: 'حضور القداس الإلهي',
                  subtitle: 'رصد حضور المخدومين وأعذار الغياب في القداس',
                  icon: Icons.church_rounded,
                  accentColor: AppConstants.accentGold,
                  sessionType: 'qoddas',
                  session: todayQoddas,
                  currentUid: currentUid,
                  isDark: isDark,
                ),
              ],

              const SizedBox(height: 20),

              // سجل الجلسات السابقة
              Text(
                'سجل جلسات الحضور السابقة',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppConstants.textDark,
                ),
              ),
              const SizedBox(height: 8),

              if (snapshot.connectionState == ConnectionState.waiting &&
                  sessions.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (sessions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppConstants.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppConstants.cardBorderDark
                          : AppConstants.cardBorderLight,
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.history_toggle_off_rounded,
                        size: 36,
                        color: AppConstants.textMuted,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'لا توجد جلسات حضور مسجلة بعد لهذه الفرقة',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.textMuted,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...sessions.take(15).map(
                      (s) => _buildHistorySessionTile(
                        context: context,
                        session: s,
                        currentUid: currentUid,
                        isDark: isDark,
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSessionActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required String sessionType,
    required AttendanceSessionModel? session,
    required String currentUid,
    required bool isDark,
  }) {
    final lockedByOther = session?.isLockedByOther(currentUid) ?? false;
    final holderName = session?.lockedByKhademName ?? 'خادم آخر';
    final attendedCount = session?.attendedCount ?? 0;
    final excusedCount = session?.excusedCount ?? 0;
    final isFinalized = session?.isFinalized ?? false;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: lockedByOther
              ? AppConstants.warningColor.withValues(alpha: 0.6)
              : accentColor.withValues(alpha: 0.35),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppConstants.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppConstants.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (session != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isFinalized
                        ? AppConstants.successColor.withValues(alpha: 0.14)
                        : accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'حاضر: $attendedCount${excusedCount > 0 ? ' • بعذر: $excusedCount' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isFinalized
                          ? AppConstants.successColor
                          : accentColor,
                    ),
                  ),
                ),
            ],
          ),
          if (lockedByOther) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppConstants.warningColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_person_rounded,
                    size: 16,
                    color: AppConstants.warningColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'يقوم حالياً "$holderName" بتسجيل الغياب في هذه الجلسة',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppConstants.warningColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: lockedByOther
                    ? AppConstants.warningColor
                    : accentColor,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _openSession(
                date: _selectedDate,
                sessionType: sessionType,
              ),
              icon: Icon(
                lockedByOther
                    ? Icons.visibility_rounded
                    : (isFinalized
                          ? Icons.fact_check_outlined
                          : Icons.how_to_reg_rounded),
                size: 18,
              ),
              label: Text(
                lockedByOther
                    ? 'مشاهدة الرصد المباشر ($holderName)'
                    : (isFinalized
                          ? 'مراجعة سجل الجلسة المعتمدة'
                          : 'فتح شاشة رصد الحضور والغياب'),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySessionTile({
    required BuildContext context,
    required AttendanceSessionModel session,
    required String currentUid,
    required bool isDark,
  }) {
    final parsedDate = DateTime.tryParse(session.date) ?? _selectedDate;
    final lockedByOther = session.isLockedByOther(currentUid);
    final isMass = session.isMass;
    final accent = isMass ? AppConstants.accentGold : const Color(0xFF8B5CF6);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? AppConstants.cardBorderDark
              : AppConstants.cardBorderLight,
        ),
      ),
      child: ListTile(
        onTap: () => _openSession(
          date: parsedDate,
          sessionType: session.type,
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isMass ? Icons.church_rounded : Icons.fact_check_rounded,
            color: accent,
            size: 20,
          ),
        ),
        title: Text(
          '${isMass ? "حضور القداس" : "حضور الخدمة"} — ${session.date}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          lockedByOther
              ? '🔒 يرصد الآن: ${session.lockedByKhademName ?? "خادم آخر"}'
              : 'حاضر: ${session.attendedCount} • بعذر: ${session.excusedCount} • ${session.isFinalized ? "معتمد" : "قيد الرصد"}',
          style: TextStyle(
            fontSize: 11.5,
            color: lockedByOther
                ? AppConstants.warningColor
                : AppConstants.textMuted,
            fontWeight: lockedByOther ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      ),
    );
  }
}
