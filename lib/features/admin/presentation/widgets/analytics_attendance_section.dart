import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/attendance_session_model.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/services/attendance_analytics_service.dart';
import '../../../khadem/presentation/widgets/analytics_stat_card.dart';

class AnalyticsAttendanceSection extends StatelessWidget {
  final List<MakhdomModel> makhdomeen;
  final List<AttendanceSessionModel> sessions;
  final bool isDark;
  final DateTime asOf;
  final DateTime? from;

  const AnalyticsAttendanceSection({
    super.key,
    required this.makhdomeen,
    required this.sessions,
    required this.isDark,
    required this.asOf,
    required this.from,
  });

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_busy_outlined,
                size: 48.sp,
                color: isDark ? Colors.white30 : Colors.grey.shade400,
              ),
              SizedBox(height: 12.h),
              Text(
                context.tr.messageNoAttendanceSessionsRecordedYet,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
              ),
              SizedBox(height: 4.h),
              Text(
                context.tr.messageWeeklyStatisticsAppearHereAfterRecordingAttendance,
                style: TextStyle(fontSize: 11.5.sp, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    final overallRate =
        AttendanceAnalyticsService.calculateOverallAttendanceRate(
          makhdomeen: makhdomeen,
          sessions: sessions,
          asOf: asOf,
          from: from,
        );

    final serviceSessions = sessions.where((s) => s.type == 'khedma').toList();
    final massSessions = sessions.where((s) => s.type == 'qoddas').toList();

    final serviceRate =
        AttendanceAnalyticsService.calculateOverallAttendanceRate(
          makhdomeen: makhdomeen,
          sessions: serviceSessions,
          asOf: asOf,
          from: from,
        );
    final massRate = AttendanceAnalyticsService.calculateOverallAttendanceRate(
      makhdomeen: makhdomeen,
      sessions: massSessions,
      type: 'qoddas',
      asOf: asOf,
      from: from,
    );

    final weeklyTrend = AttendanceAnalyticsService.getWeeklyTrend(
      makhdomeen: makhdomeen,
      sessions: sessions,
      asOf: asOf,
      from: from,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // كروت نسب الحضور الرئيسية
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10.h,
          crossAxisSpacing: 10.w,
          childAspectRatio: 1.35,
          children: [
            AnalyticsStatCard(
              title: context.tr.messageOverallAttendanceRate,
              value: overallRate == null
                  ? context.tr.insufficientAttendanceData
                  : '${AppFormatters(Localizations.localeOf(context)).formatNumber(overallRate, decimalDigits: 1)}%',
              icon: Icons.how_to_reg_rounded,
              color: const Color(0xFF8B5CF6),
              subtitle: context.tr.messageAverageOfRecordedSessions,
              isDark: isDark,
            ),
            AnalyticsStatCard(
              title: context.tr.messageAttendanceFridays,
              value: '${sessions.length}',
              icon: Icons.calendar_today_rounded,
              color: AppColors.primaryLight,
              subtitle: context.tr.messageServiceMass(
                (serviceSessions.length).toString(),
                (massSessions.length).toString(),
              ),
              isDark: isDark,
            ),
            AnalyticsStatCard(
              title: context.tr.messageServiceAttendance,
              value: serviceRate == null
                  ? context.tr.insufficientAttendanceData
                  : '${AppFormatters(Localizations.localeOf(context)).formatNumber(serviceRate, decimalDigits: 1)}%',
              icon: Icons.fact_check_outlined,
              color: AppColors.successColor,
              subtitle: context.tr.messageAverageSundaySchoolAttendance,
              isDark: isDark,
            ),
            AnalyticsStatCard(
              title: context.tr.messageMassAttendance,
              value: massRate == null
                  ? context.tr.insufficientAttendanceData
                  : '${AppFormatters(Localizations.localeOf(context)).formatNumber(massRate, decimalDigits: 1)}%',
              icon: Icons.church_rounded,
              color: AppColors.accentGold,
              subtitle: context.tr.messageAverageMassAttendance,
              isDark: isDark,
            ),
          ],
        ),
        SizedBox(height: 18.h),

        // منحنى وجدول الجلسات الأسبوعية
        Container(
          padding: EdgeInsets.all(18.r),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(
              color: isDark
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
                    Icons.timeline_rounded,
                    color: AppColors.primaryLight,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    context.tr.messageWeeklyAttendanceRecentFridays,
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              ...weeklyTrend.map((point) {
                final isMass = point.type == 'qoddas';
                final color = isMass
                    ? AppColors.accentGold
                    : const Color(0xFF8B5CF6);

                return Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  isMass
                                      ? context.tr.messageMass
                                      : context.tr.messageService,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Builder(
                                builder: (context) {
                                  final dt = DateTime.tryParse(point.date);
                                  final dayLabel = dt != null
                                      ? AppFormatters(
                                          Localizations.localeOf(context),
                                        ).formatDate(dt, format: 'EEEE')
                                      : (context.tr.messageSession);
                                  return Text(
                                    '$dayLabel ${point.date}',
                                    style: TextStyle(
                                      fontSize: 12.5.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          Text(
                            '${point.attendedCount} / ${point.totalEligible} (${AppFormatters(Localizations.localeOf(context)).formatNumber(point.percentage, decimalDigits: 0)}%)',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6.r),
                        child: LinearProgressIndicator(
                          value: point.totalEligible > 0
                              ? (point.attendedCount / point.totalEligible)
                              : 0.0,
                          backgroundColor: isDark
                              ? Colors.white10
                              : Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 6.h,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
