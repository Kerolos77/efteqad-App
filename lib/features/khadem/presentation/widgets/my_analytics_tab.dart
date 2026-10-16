import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/attendance_session_model.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/models/visit_model.dart';
import '../../../../core/responsive/responsive_breakpoints.dart';
import '../../../../core/services/attendance_analytics_service.dart';
import 'absence_alerts_section.dart';
import 'analytics_stat_card.dart';
import 'behavioral_segmentation_section.dart';
import 'visitation_impact_card.dart';

class MyAnalyticsTab extends StatefulWidget {
  final List<MakhdomModel> myMakhdomeen;
  final List<AttendanceSessionModel> sessions;
  final List<VisitModel> visits;
  final DateTime? from, asOf;
  final VoidCallback? onVisitRecorded;

  const MyAnalyticsTab({
    super.key,
    required this.myMakhdomeen,
    required this.sessions,
    this.visits = const [],
    this.from,
    this.asOf,
    this.onVisitRecorded,
  });

  @override
  State<MyAnalyticsTab> createState() => _MyAnalyticsTabState();
}

class _MyAnalyticsTabState extends State<MyAnalyticsTab> {
  String _behaviorFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatters = AppFormatters(Localizations.localeOf(context));

    if (widget.myMakhdomeen.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.query_stats_rounded,
                size: 48.sp,
                color: isDark ? Colors.white30 : Colors.grey.shade400,
              ),
              SizedBox(height: 12.h),
              Text(
                context.tr.noMakhdomeenAssignedTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                context.tr.noMakhdomeenAssignedSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final attendanceRate =
        AttendanceAnalyticsService.calculateOverallAttendanceRate(
          makhdomeen: widget.myMakhdomeen,
          sessions: widget.sessions,
          from: widget.from,
          asOf: widget.asOf,
        );
    final visitedIds = widget.visits.map((v) => v.makhdomId).toSet();
    final visitedCount = widget.myMakhdomeen
        .where((m) => visitedIds.contains(m.id) || m.visitCount > 0)
        .length;
    final totalCount = widget.myMakhdomeen.length;
    final visitRate = totalCount > 0 ? (visitedCount / totalCount * 100) : 0.0;

    final impact = AttendanceAnalyticsService.calculateVisitationImpact(
      makhdomeen: widget.myMakhdomeen,
      sessions: widget.sessions,
      visits: widget.visits,
      from: widget.from,
      asOf: widget.asOf,
    );

    final segmentation = AttendanceAnalyticsService.segmentStudents(
      makhdomeen: widget.myMakhdomeen,
      sessions: widget.sessions,
      from: widget.from,
      asOf: widget.asOf,
    );

    final atRiskList = AttendanceAnalyticsService.getAtRiskStudents(
      makhdomeen: widget.myMakhdomeen,
      sessions: widget.sessions,
      from: widget.from,
      asOf: widget.asOf,
    );

    List<MakhdomModel> segmentedList;
    if (_behaviorFilter == 'consistent') {
      segmentedList = segmentation.consistent;
    } else if (_behaviorFilter == 'irregular') {
      segmentedList = segmentation.irregular;
    } else if (_behaviorFilter == 'atRisk') {
      segmentedList = segmentation.atRisk;
    } else if (_behaviorFilter == 'insufficient') {
      segmentedList = segmentation.insufficient;
    } else {
      segmentedList = widget.myMakhdomeen;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsetsDirectional.fromSTEB(16.w, 12.h, 16.w, 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.from != null)
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Text(
                context.tr.analyticsDateBounds(
                  formatters.formatDate(widget.from!),
                  formatters.formatDate(widget.asOf ?? DateTime.now()),
                ),
                style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted),
              ),
            ),
          // 1. كروت المؤشرات السريعة لمجموعتي
          GridView.count(
            crossAxisCount: context.isDesktopScreen ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10.h,
            crossAxisSpacing: 10.w,
            childAspectRatio: context.isDesktopScreen ? 2.2 : 1.35,
            children: [
              AnalyticsStatCard(
                title: context.tr.servantGroupAttendanceRate,
                value: attendanceRate == null
                    ? context.tr.insufficientAttendanceData
                    : '${formatters.formatNumber(attendanceRate, decimalDigits: 0)}%',
                subtitle: context.tr.messageAllSessions,
                icon: Icons.how_to_reg_rounded,
                color: Colors.teal,
                isDark: isDark,
              ),
              AnalyticsStatCard(
                title: context.tr.servantGroupVisitationProgress,
                value: '${formatters.formatNumber(visitRate, decimalDigits: 0)}%',
                subtitle: context.tr.messageOfStudents(
                  formatters.formatNumber(visitedCount),
                  formatters.formatNumber(totalCount),
                ),
                icon: Icons.volunteer_activism_rounded,
                color: AppColors.primaryLight,
                isDark: isDark,
              ),
              AnalyticsStatCard(
                title: context.tr.urgentVisitationNeeded,
                value: '${atRiskList.length}',
                subtitle: attendanceRate == null
                    ? context.tr.insufficientAttendanceData
                    : atRiskList.isEmpty
                        ? (context.tr.messageAllConsistent)
                        : (context.tr.messageAbsenceAlert649),
                icon: Icons.warning_amber_rounded,
                color: atRiskList.isEmpty
                    ? AppColors.successColor
                    : AppColors.errorColor,
                isDark: isDark,
              ),
              AnalyticsStatCard(
                title: context.tr.segmentConsistent,
                value: formatters.formatNumber(segmentation.consistent.length),
                subtitle: context.tr.messageAttendance75,
                icon: Icons.star_rounded,
                color: AppColors.accentGold,
                isDark: isDark,
              ),
            ],
          ),
          SizedBox(height: 18.h),

          // 2. كارت أثر الافتقاد على الحضور لمجموعتك
          VisitationImpactCard(impact: impact, isDark: isDark),
          SizedBox(height: 18.h),

          // 3. إنذارات الغياب المتكرر لأولادي
          AbsenceAlertsSection(
            atRiskList: atRiskList,
            hasAttendanceData: attendanceRate != null,
            isDark: isDark,
            onVisitRecorded: widget.onVisitRecorded,
          ),
          SizedBox(height: 22.h),

          // 4. التصنيف السلوكي للأولاد وقائمتهم
          BehavioralSegmentationSection(
            segmentation: segmentation,
            segmentedList: segmentedList,
            totalCount: totalCount,
            activeFilter: _behaviorFilter,
            onFilterChanged: (filter) => setState(() => _behaviorFilter = filter),
            isDark: isDark,
            onVisitRecorded: widget.onVisitRecorded,
          ),
        ],
      ),
    );
  }
}
