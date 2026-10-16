import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/utils/color_generator.dart';
import '../../../khadem/presentation/widgets/analytics_stat_card.dart';

class AnalyticsVisitsSection extends StatelessWidget {
  final List<MakhdomModel> makhdomeen;
  final List<KhademModel> khodam;
  final Set<String> visitedIds;
  final bool isDark;
  final Future<void> Function(String phone) onMakeCall;

  const AnalyticsVisitsSection({
    super.key,
    required this.makhdomeen,
    required this.khodam,
    required this.visitedIds,
    required this.isDark,
    required this.onMakeCall,
  });

  @override
  Widget build(BuildContext context) {
    final totalMakhdomeen = makhdomeen.length;
    final assignedMakhdomeen = makhdomeen.where((m) => m.isAssigned).length;
    final unassignedMakhdomeen = totalMakhdomeen - assignedMakhdomeen;
    final visitedAtLeastOnce =
        makhdomeen.where((m) => visitedIds.contains(m.id)).length;
    final neverVisited = totalMakhdomeen - visitedAtLeastOnce;
    final brethrenCount =
        makhdomeen.where((m) => m.isBrethrenOfLord).length;
    final visitPercentage = totalMakhdomeen > 0
        ? (visitedAtLeastOnce / totalMakhdomeen) * 100
        : 0.0;

    final List<Map<String, dynamic>> khademStats = [];
    for (var k in khodam) {
      final myMakhdomeen =
          makhdomeen.where((m) => m.assignedKhademId == k.id).toList();
      final total = myMakhdomeen.length;
      final visited =
          myMakhdomeen.where((m) => visitedIds.contains(m.id)).length;
      final percentage = total > 0 ? (visited / total) * 100 : 0.0;

      khademStats.add({
        'khadem': k,
        'total': total,
        'visited': visited,
        'percentage': percentage,
      });
    }
    khademStats.sort(
      (a, b) =>
          (b['percentage'] as double).compareTo(a['percentage'] as double),
    );

    final unvisitedList =
        makhdomeen.where((m) => !visitedIds.contains(m.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // كروت الإحصائيات السريعة
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10.h,
          crossAxisSpacing: 10.w,
          childAspectRatio: 1.35,
          children: [
            AnalyticsStatCard(
              title: context.tr.totalMakhdomeenTitle,
              value: '$totalMakhdomeen',
              icon: Icons.groups_outlined,
              color: AppColors.primaryLight,
              subtitle: context.tr.totalBoysAssignedSubtitle(assignedMakhdomeen),
              isDark: isDark,
            ),
            AnalyticsStatCard(
              title: context.tr.visitationRateTitle,
              value:
                  '${AppFormatters(Localizations.localeOf(context)).formatNumber(visitPercentage, decimalDigits: 0)}%',
              icon: Icons.pie_chart_outline,
              color: AppColors.successColor,
              subtitle: context.tr.visitedBoysCountSubtitle(visitedAtLeastOnce),
              isDark: isDark,
            ),
            AnalyticsStatCard(
              title: context.tr.neverVisitedTitle,
              value: '$neverVisited',
              icon: Icons.person_off_outlined,
              color: AppColors.errorColor,
              subtitle: context.tr.needsUrgentVisitSubtitle,
              isDark: isDark,
            ),
            AnalyticsStatCard(
              title: context.tr.brethrenOfLordTitle,
              value: AppFormatters(
                Localizations.localeOf(context),
              ).formatNumber(brethrenCount),
              icon: Icons.favorite_border,
              color: AppColors.accentGold,
              subtitle: context.tr.specialFollowupSubtitle,
              isDark: isDark,
            ),
          ],
        ),
        SizedBox(height: 16.h),

        // الرسم البياني الدائري لحالة الافتقاد
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
              Text(
                context.tr.visitationDistributionTitle,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 18.h),
              SizedBox(
                height: 150.h,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 40.r,
                    sections: [
                      PieChartSectionData(
                        value: visitedAtLeastOnce.toDouble(),
                        title:
                            '${AppFormatters(Localizations.localeOf(context)).formatNumber(visitPercentage, decimalDigits: 0)}%',
                        color: AppColors.successColor,
                        radius: 38.r,
                        titleStyle: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontSize: 12.sp,
                        ),
                      ),
                      PieChartSectionData(
                        value: neverVisited.toDouble(),
                        title:
                            '${AppFormatters(Localizations.localeOf(context)).formatNumber(((neverVisited / totalMakhdomeen) * 100), decimalDigits: 0)}%',
                        color: AppColors.errorColor,
                        radius: 38.r,
                        titleStyle: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontSize: 12.sp,
                        ),
                      ),
                      if (unassignedMakhdomeen > 0)
                        PieChartSectionData(
                          value: unassignedMakhdomeen.toDouble(),
                          title: '',
                          color: isDark
                              ? Colors.white24
                              : const Color(0xFFCBD5E1),
                          radius: 32.r,
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 14.w,
                runSpacing: 8.h,
                children: [
                  _buildLegendItem(
                    AppColors.successColor,
                    '${context.tr.filterVisited} ($visitedAtLeastOnce)',
                  ),
                  _buildLegendItem(
                    AppColors.errorColor,
                    '${context.tr.filterUnvisited} ($neverVisited)',
                  ),
                  if (unassignedMakhdomeen > 0)
                    _buildLegendItem(
                      isDark ? Colors.white38 : Colors.grey.shade400,
                      '${context.tr.filterUnassigned} ($unassignedMakhdomeen)',
                    ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 18.h),

        // نسب إنجاز الخدام
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
                    Icons.leaderboard_outlined,
                    color: AppColors.primaryLight,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    context.tr.servantsAchievementRatesTitle,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              if (khademStats.isEmpty)
                Center(
                  child: Text(
                    context.tr.noKhodamYet,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textMuted,
                    ),
                  ),
                )
              else
                ...khademStats.map((stat) {
                  final k = stat['khadem'] as KhademModel;
                  final total = stat['total'] as int;
                  final visited = stat['visited'] as int;
                  final p = stat['percentage'] as double;
                  final color = ColorGenerator.getColorForId(k.id);

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
                                CircleAvatar(
                                  radius: 10.r,
                                  backgroundColor: color.withValues(alpha: 0.2),
                                  child: Text(
                                    k.name.isNotEmpty
                                        ? k.name[0]
                                        : context.tr.messageS,
                                    style: TextStyle(
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  k.name,
                                  style: TextStyle(
                                    fontSize: 12.5.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${AppFormatters(Localizations.localeOf(context)).formatNumber(visited)} / ${AppFormatters(Localizations.localeOf(context)).formatNumber(total)} (${AppFormatters(Localizations.localeOf(context)).formatNumber(p, decimalDigits: 0)}%)',
                              style: TextStyle(
                                fontSize: 11.5.sp,
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
                            value: total > 0 ? (visited / total) : 0.0,
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
        SizedBox(height: 18.h),

        // قائمة الأولاد الذين لم يُفتقدوا نهائياً
        if (unvisitedList.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                color: AppColors.errorColor.withValues(alpha: 0.25),
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
                          Icons.warning_amber_rounded,
                          color: AppColors.errorColor,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          context.tr.unvisitedChildrenHeader(
                            unvisitedList.length,
                          ),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.errorColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                ...unvisitedList.take(6).map((m) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 8.h),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF131D31)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isDark
                            ? AppColors.cardBorderDark
                            : AppColors.cardBorderLight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.fullName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.sp,
                                ),
                              ),
                              Text(
                                m.isAssigned
                                    ? context.tr.assignedToKhademLabel(
                                        m.assignedKhademName!,
                                      )
                                    : context.tr.unassignedBadge,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: m.isAssigned
                                      ? AppColors.textMuted
                                      : AppColors.errorColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (m.phone.isNotEmpty)
                          IconButton(
                            icon: Icon(
                              Icons.phone_outlined,
                              size: 18.sp,
                              color: AppColors.successColor,
                            ),
                            onPressed: () => onMakeCall(m.phone),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10.w,
          height: 10.h,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 11.sp,
            color: isDark ? Colors.white70 : AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
