import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';

/// Reusable tile component for AppDrawer navigation items.
class AppDrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDark;
  final Color? color;

  const AppDrawerTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.isDark,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? (isDark ? Colors.white : AppColors.textDark);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        leading: Icon(
          icon,
          color: color ?? (isDark ? Colors.white70 : AppColors.primaryNavy),
          size: 22.r,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w600,
            color: itemColor,
          ),
        ),
        onTap: onTap,
        dense: true,
      ),
    );
  }
}
