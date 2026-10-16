import 'package:efteqad/core/localization/app_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../models/history_analysis.dart';

class HistoryKpis extends StatelessWidget {
  final HistoryAnalysis analysis;
  final bool isDark;

  const HistoryKpis({super.key, required this.analysis, required this.isDark});

  Widget _buildKpiCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDark
              ? AppColors.cardBorderDark
              : AppColors.cardBorderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(7.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, size: 16.sp, color: color),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasData = analysis.hasSufficientData;
    String rate(double? value) => value == null
        ? context.tr.insufficientDataShort
        : '${AppFormatters(Localizations.localeOf(context)).formatNumber(value, decimalDigits: 0)}%';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Column(
        children: [
          // شبكة الـ KPIs الرئيسية
          GridView(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.textScalerOf(context).scale(1) > 1.3
                  ? 1
                  : 2,
              mainAxisSpacing: 10.h,
              crossAxisSpacing: 10.w,
              mainAxisExtent: MediaQuery.textScalerOf(context).scale(200),
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // 1. نسبة الحضور الإجمالية
              _buildKpiCard(
                context: context,
                title: context.tr.overallAttendanceTitle,
                value: rate(analysis.overallAttendanceRate),
                subtitle: context.tr.attendanceRatio(
                  analysis.totalAttendedSessions,
                  analysis.totalEligibleSessions,
                ),
                icon: Icons.percent_rounded,
                color:
                    analysis.overallAttendanceRate != null &&
                        analysis.overallAttendanceRate! >= 75
                    ? AppColors.successColor
                    : (analysis.overallAttendanceRate != null &&
                              analysis.overallAttendanceRate! >= 40
                          ? AppColors.accentGold
                          : AppColors.errorColor),
              ),

              // 2. إجمالي الافتقادات
              _buildKpiCard(
                context: context,
                title: context.tr.totalVisitsTitle,
                value: '${analysis.totalVisitsCount}',
                subtitle: analysis.daysSinceLastVisit != null
                    ? context.tr.daysSinceLastVisit(
                        analysis.daysSinceLastVisit!,
                      )
                    : context.tr.noVisitsYet,
                icon: Icons.volunteer_activism_rounded,
                color: AppColors.sacredGold,
              ),

              // 3. الغياب المتتالي
              _buildKpiCard(
                context: context,
                title: context.tr.consecutiveAbsenceTitle,
                value: hasData
                    ? '${analysis.consecutiveAbsences}'
                    : context.tr.insufficientDataShort,
                subtitle: !hasData
                    ? context.tr.insufficientAttendanceData
                    : analysis.consecutiveAbsences == 0
                    ? context.tr.noConsecutiveAbsences
                    : (analysis.isCriticalRisk
                          ? context.tr.criticalAbsenceAlert
                          : context.tr.warningAbsenceAlert),
                icon: Icons.event_busy_rounded,
                color: analysis.consecutiveAbsences >= 2
                    ? AppColors.errorColor
                    : AppColors.successColor,
              ),

              // 4. حضور القداس مقابل الخدمة
              _buildKpiCard(
                context: context,
                title: context.tr.massAndServiceRatesTitle,
                value: rate(analysis.serviceAttendanceRate),
                subtitle: analysis.massAttendanceRate == null
                    ? context.tr.insufficientAttendanceData
                    : context.tr.massRateSubtitle(
                        AppFormatters(
                          Localizations.localeOf(context),
                        ).formatNumber(
                          analysis.massAttendanceRate!,
                          decimalDigits: 0,
                        ),
                      ),
                icon: Icons.church_rounded,
                color: AppColors.primaryLight,
              ),
            ],
          ),

          // 5. بطاقة الارتباط الإحصائي للزيارة (دون ادعاء سببية)
          if (analysis.correlationDifference != null) ...[
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isDark
                      ? AppColors.cardBorderDark
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: AppColors.sacredGold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.analytics_outlined,
                      size: 18.sp,
                      color: AppColors.sacredGold,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr.visitationCorrelationTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.sp,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          context.tr.visitationCorrelationBody(
                            analysis.correlationDifference! >= 0
                                ? '+${AppFormatters(Localizations.localeOf(context)).formatNumber(analysis.correlationDifference!, decimalDigits: 0)}'
                                : AppFormatters(
                                    Localizations.localeOf(context),
                                  ).formatNumber(
                                    analysis.correlationDifference!,
                                    decimalDigits: 0,
                                  ),
                          ),
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: isDark
                                ? Colors.white70
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (!hasData) ...[
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16.sp, color: Colors.blue),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      context.tr.insufficientHistoryDataHint,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
