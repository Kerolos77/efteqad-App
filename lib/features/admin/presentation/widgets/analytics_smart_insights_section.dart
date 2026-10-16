import 'package:efteqad/core/errors/app_failure.dart';
import 'package:efteqad/core/localization/app_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/attendance_session_model.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/models/visit_model.dart';
import '../../../../core/services/attendance_analytics_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../common/widgets/record_visit_sheet.dart';

class AnalyticsSmartInsightsSection extends StatefulWidget {
  final List<MakhdomModel> makhdomeen;
  final List<AttendanceSessionModel> sessions;
  final List<AtRiskStudentInfo> atRiskList;
  final List<VisitModel> windowVisits;
  final DateTime? from;
  final DateTime asOf;
  final bool isDark;
  final Future<void> Function(String phone) onMakeCall;
  final Future<void> Function(String phone) onOpenWhatsApp;

  const AnalyticsSmartInsightsSection({
    super.key,
    required this.makhdomeen,
    required this.sessions,
    required this.atRiskList,
    required this.windowVisits,
    required this.from,
    required this.asOf,
    required this.isDark,
    required this.onMakeCall,
    required this.onOpenWhatsApp,
  });

  @override
  State<AnalyticsSmartInsightsSection> createState() =>
      _AnalyticsSmartInsightsSectionState();
}

class _AnalyticsSmartInsightsSectionState
    extends State<AnalyticsSmartInsightsSection> {
  String _behaviorFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final impact = AttendanceAnalyticsService.calculateVisitationImpact(
      makhdomeen: widget.makhdomeen,
      sessions: widget.sessions,
      visits: widget.windowVisits,
      from: widget.from,
      asOf: widget.asOf,
    );

    final segmentation = AttendanceAnalyticsService.segmentStudents(
      makhdomeen: widget.makhdomeen,
      sessions: widget.sessions,
      asOf: widget.asOf,
      from: widget.from,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ------------------ كارت إنذارات الغياب المتكرر ------------------
        Container(
          padding: EdgeInsets.all(18.r),
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(
              color: widget.atRiskList.isNotEmpty
                  ? AppColors.errorColor.withValues(alpha: 0.35)
                  : AppColors.successColor.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        widget.atRiskList.isNotEmpty
                            ? Icons.warning_rounded
                            : Icons.check_circle_outline,
                        color: widget.atRiskList.isNotEmpty
                            ? AppColors.errorColor
                            : AppColors.successColor,
                        size: 22.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        context.tr.absenceAlertsHeader,
                        style: TextStyle(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w900,
                          color: widget.atRiskList.isNotEmpty
                              ? AppColors.errorColor
                              : AppColors.successColor,
                        ),
                      ),
                    ],
                  ),
                  if (widget.atRiskList.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.errorColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        context.tr.messageStudents(
                          (widget.atRiskList.length).toString(),
                        ),
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.errorColor,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                context.tr.absenceAlertsSubtitle,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.textMuted,
                ),
              ),
              SizedBox(height: 14.h),

              if (widget.atRiskList.isEmpty)
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: AppColors.successColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Center(
                    child: Text(
                      AttendanceAnalyticsService.calculateOverallAttendanceRate(
                                makhdomeen: widget.makhdomeen,
                                sessions: widget.sessions,
                                asOf: widget.asOf,
                                from: widget.from,
                              ) ==
                              null
                          ? context.tr.insufficientAttendanceData
                          : context.tr.noAbsenceAlerts,
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.successColor,
                      ),
                    ),
                  ),
                )
              else
                ...widget.atRiskList.map((info) {
                  final m = info.makhdom;
                  final badgeColor = info.isCritical
                      ? AppColors.errorColor
                      : AppColors.warningColor;

                  return Container(
                    margin: EdgeInsets.only(bottom: 10.h),
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? const Color(0xFF131D31)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: badgeColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                m.fullName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5.sp,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                info.isCritical
                                    ? context.tr.criticalAbsenceBadge
                                    : context.tr.warningAbsenceBadge,
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                  color: badgeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Text(
                              context.tr.missedFridaysCount(
                                info.consecutiveAbsences,
                              ),
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                              ),
                            ),
                            if (m.isAssigned) ...[
                              Text(
                                ' • ',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp),
                              ),
                              Text(
                                context.tr.assignedToKhademLabel(
                                  m.assignedKhademName!,
                                ),
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 8.h),

                        // أزرار الإجراء الفوري المباشر (اتصال، واتساب، تسجيل افتقاد)
                        Row(
                          children: [
                            if (m.phone.isNotEmpty) ...[
                              InkWell(
                                onTap: () => widget.onMakeCall(m.phone),
                                borderRadius: BorderRadius.circular(8.r),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 6.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.successColor.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.call,
                                        size: 13.sp,
                                        color: AppColors.successColor,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        context.tr.callAction,
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.successColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              InkWell(
                                onTap: () => widget.onOpenWhatsApp(m.phone),
                                borderRadius: BorderRadius.circular(8.r),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 6.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF25D366).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        FontAwesomeIcons.whatsapp,
                                        size: 13.sp,
                                        color: const Color(0xFF25D366),
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        context.tr.whatsappAction,
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF25D366),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            if (m.isAssigned) ...[
                              InkWell(
                                onTap: () => _notifyKhadem(context, info),
                                borderRadius: BorderRadius.circular(8.r),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 6.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.notifications_active_outlined,
                                        size: 13.sp,
                                        color: Colors.amber,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        context.tr.messageNotify,
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                            ],
                            // زر تسجيل افتقاد مباشر
                            ElevatedButton.icon(
                              onPressed: () {
                                RecordVisitSheet.show(context, makhdom: m);
                              },
                              icon: Icon(Icons.add_task, size: 14.sp),
                              label: Text(
                                context.tr.visitAction,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentIndigo,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 6.h,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        SizedBox(height: 18.h),

        // ------------------ كارت أثر الافتقاد على الحضور ------------------
        if (!impact.hasSufficientData)
          Text(context.tr.insufficientAttendanceData)
        else
          Container(
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              color: widget.isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                color: AppColors.accentGold.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_rounded,
                      color: AppColors.accentGold,
                      size: 22.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      context.tr.visitationImpactHeader,
                      style: TextStyle(
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  context.tr.visitationImpactSubtitle,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textMuted,
                  ),
                ),
                SizedBox(height: 14.h),

                Row(
                  children: [
                    // المفتقدون
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: AppColors.successColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: AppColors.successColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              context.tr.messageVisitedStudents,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              '${AppFormatters(Localizations.localeOf(context)).formatNumber(impact.visitedAttendanceRate!, decimalDigits: 1)}%',
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w900,
                                color: AppColors.successColor,
                              ),
                            ),
                            Text(
                              context.tr.messageStudents705(
                                (impact.visitedStudentsCount).toString(),
                              ),
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    // غير المفتقدين
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: AppColors.errorColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: AppColors.errorColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              context.tr.messageUnvisitedStudents,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              '${AppFormatters(Localizations.localeOf(context)).formatNumber(impact.unvisitedAttendanceRate!, decimalDigits: 1)}%',
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w900,
                                color: AppColors.errorColor,
                              ),
                            ),
                            Text(
                              context.tr.messageStudents708(
                                (impact.unvisitedStudentsCount).toString(),
                              ),
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // شريط النتيجة الإحصائية
                if (impact.hasSufficientData)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          color: AppColors.accentGold,
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            context.tr.visitationImpactValue(
                              impact.impactPercentage!,
                            ),
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accentGold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        SizedBox(height: 18.h),

        // ------------------ كارت التصنيف السلوكي للأولاد ------------------
        Container(
          padding: EdgeInsets.all(18.r),
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(
              color: widget.isDark
                  ? AppColors.cardBorderDark
                  : AppColors.cardBorderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.psychology_outlined,
                    color: AppColors.primaryLight,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    context.tr.messageStudentAttendanceGroups,
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 14.h),

              // الأزرار الثلاثة للاختيار
              Row(
                children: [
                  Expanded(
                    child: _buildBehaviorChip(
                      label: context.tr.segmentConsistent,
                      count: segmentation.consistent.length,
                      color: AppColors.successColor,
                      key: 'consistent',
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _buildBehaviorChip(
                      label: context.tr.segmentIrregular,
                      count: segmentation.irregular.length,
                      color: AppColors.warningColor,
                      key: 'irregular',
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _buildBehaviorChip(
                      label: context.tr.segmentAtRisk,
                      count: segmentation.atRisk.length,
                      color: AppColors.errorColor,
                      key: 'atRisk',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),

              _buildBehaviorChip(
                label: context.tr.insufficientAttendanceData,
                count: segmentation.insufficient.length,
                color: Colors.blueGrey,
                key: 'insufficient',
              ),
              // عرض قائمة أسماء المجموعة المختارة
              _buildSelectedBehaviorList(segmentation, widget.isDark),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _notifyKhadem(BuildContext context, AtRiskStudentInfo info) async {
    final messenger = ScaffoldMessenger.of(context);
    final tr = context.tr;
    final m = info.makhdom;
    try {
      final receipt = await NotificationService().notifyKhadem(
        recipientId: m.assignedKhademId!,
        recipientName: m.assignedKhademName ?? '',
        title: tr.messageAbsenceAlert(m.fullName),
        body: tr.messageStudentMissedFridaysPleaseVisitSoon(
          (info.consecutiveAbsences).toString(),
        ),
        type: 'absence_alert',
        data: {
          'makhdomId': m.id,
          'consecutiveAbsences': info.consecutiveAbsences,
          'grade': m.grade,
        },
      );
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              tr.messageUrgentAlertSentTo(
                receipt['recipientName'] as String? ?? '',
              ),
            ),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              AppFailure.fromException(e).localizedMessage(tr),
            ),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildBehaviorChip({
    required String label,
    required int count,
    required Color color,
    required String key,
  }) {
    final isSelected = _behaviorFilter == key;

    return InkWell(
      onTap: () {
        setState(() {
          _behaviorFilter = isSelected ? 'all' : key;
        });
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color, width: isSelected ? 1.5.w : 1.w),
        ),
        child: Column(
          children: [
            Text(
              AppFormatters(Localizations.localeOf(context)).formatNumber(count),
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : color,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedBehaviorList(
    BehavioralSegmentation segmentation,
    bool isDark,
  ) {
    List<MakhdomModel> list;
    if (_behaviorFilter == 'consistent') {
      list = segmentation.consistent;
    } else if (_behaviorFilter == 'irregular') {
      list = segmentation.irregular;
    } else if (_behaviorFilter == 'atRisk') {
      list = segmentation.atRisk;
    } else if (_behaviorFilter == 'insufficient') {
      list = segmentation.insufficient;
    } else {
      return const SizedBox.shrink();
    }

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: Text(
            context.tr.messageNoStudentsInThisGroup,
            style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted),
          ),
        ),
      );
    }

    return Column(
      children: list.take(8).map((m) {
        return Container(
          margin: EdgeInsets.only(bottom: 6.h),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131D31) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                m.fullName,
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                m.isAssigned
                    ? m.assignedKhademName!
                    : context.tr.unassignedBadge,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
