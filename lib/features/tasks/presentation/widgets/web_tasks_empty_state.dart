import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';

class WebTasksEmptyState extends StatelessWidget {
  final bool isDark;

  const WebTasksEmptyState({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(48.0.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.task_alt_rounded,
                size: 54.sp,
                color: AppColors.primaryLight,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'لا توجد مهام تطابق هذا الفلتر',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'أحسنت! جميع التكليفات إما منجزة أو لا توجد مهام حالية.',
              style: TextStyle(fontSize: 13.sp, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
