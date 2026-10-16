import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_formatters.dart';

class AttendanceDateSelectorBar extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onPickDate;
  final bool isDark;

  const AttendanceDateSelectorBar({
    super.key,
    required this.selectedDate,
    required this.onPickDate,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 14.w,
        vertical: 10.h,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? AppColors.cardBorderDark
              : AppColors.cardBorderLight,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_month_rounded,
            color: AppColors.primaryLight,
            size: 20.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تاريخ جلسة الرصد',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  AppFormatters(
                    Localizations.localeOf(context),
                  ).formatDayAndDate(selectedDate),
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: onPickDate,
            icon: Icon(Icons.edit_calendar_rounded, size: 16.sp),
            label: Text(
              'تغيير اليوم',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
