import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/widgets/web/web_widgets.dart';

class WebTasksKpiBar extends StatelessWidget {
  final int totalCount;
  final int completedCount;
  final int pendingCount;
  final int overdueCount;
  final double completionRate;
  final ValueChanged<String> onStatusFilterSelected;
  final bool isDark;

  const WebTasksKpiBar({
    super.key,
    required this.totalCount,
    required this.completedCount,
    required this.pendingCount,
    required this.overdueCount,
    required this.completionRate,
    required this.onStatusFilterSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final formatters = AppFormatters(Localizations.localeOf(context));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final kpiCards = [
          _buildStatCard(
            title: 'إجمالي المهام',
            value: formatters.formatNumber(totalCount),
            subtitle: 'نسبة الإنجاز ${(completionRate * 100).toInt()}%',
            icon: Icons.assignment_outlined,
            color: AppColors.primaryLight,
            isDark: isDark,
          ),
          _buildStatCard(
            title: 'قيد التنفيذ',
            value: formatters.formatNumber(pendingCount),
            subtitle: 'مهام مطلوب إنجازها',
            icon: Icons.hourglass_top_rounded,
            color: AppColors.warningColor,
            isDark: isDark,
            onTap: () => onStatusFilterSelected('pending'),
          ),
          _buildStatCard(
            title: 'مكتملة',
            value: formatters.formatNumber(completedCount),
            subtitle: 'تمت بنجاح',
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.successColor,
            isDark: isDark,
            onTap: () => onStatusFilterSelected('completed'),
          ),
          _buildStatCard(
            title: 'متأخرة',
            value: formatters.formatNumber(overdueCount),
            subtitle: overdueCount > 0
                ? 'تجاوزت موعد الاستحقاق'
                : 'لا توجد مهام متأخرة',
            icon: Icons.warning_amber_rounded,
            color: overdueCount > 0 ? AppColors.errorColor : Colors.grey,
            isDark: isDark,
            isCritical: overdueCount > 0,
            onTap: overdueCount > 0
                ? () => onStatusFilterSelected('overdue')
                : null,
          ),
        ];

        if (isWide) {
          return Row(
            children: kpiCards
                .map(
                  (c) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      child: c,
                    ),
                  ),
                )
                .toList(),
          );
        }

        return Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          children: kpiCards
              .map(
                (c) => SizedBox(
                  width: (constraints.maxWidth - 12.w) / 2,
                  child: c,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    VoidCallback? onTap,
    bool isCritical = false,
  }) {
    return WebCard(
      onTap: onTap,
      padding: EdgeInsets.all(18.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: color, size: 22.sp),
              ),
              const Spacer(),
              if (isCritical)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 3.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'عاجل',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2.h),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
