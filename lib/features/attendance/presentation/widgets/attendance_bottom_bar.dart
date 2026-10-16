import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';

class AttendanceBottomBar extends StatelessWidget {
  final int attendedCount;
  final int totalCount;
  final int absentCount;
  final int excusedCount;
  final bool canFinalize;
  final VoidCallback onFinalize;
  final bool isDark;

  const AttendanceBottomBar({
    super.key,
    required this.attendedCount,
    required this.totalCount,
    required this.absentCount,
    required this.excusedCount,
    required this.canFinalize,
    required this.onFinalize,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.cardBorderDark
                : AppColors.cardBorderLight,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'حاضر: $attendedCount',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryLight,
                        ),
                      ),
                      Text(
                        ' • غائب: $absentCount',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                        ),
                      ),
                      if (excusedCount > 0)
                        Text(
                          ' • بعذر: $excusedCount',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentGold,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'الإجمالي: $totalCount مخدوم',
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (canFinalize)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.successColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 8.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                onPressed: onFinalize,
                icon: Icon(Icons.task_alt_rounded, size: 18.sp),
                label: Text(
                  context.tr.messageFinalizeAttendance,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
