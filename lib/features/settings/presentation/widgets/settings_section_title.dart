import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';

class SettingsSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const SettingsSectionTitle({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: 8.h, end: 4.w),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16.sp,
            color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
