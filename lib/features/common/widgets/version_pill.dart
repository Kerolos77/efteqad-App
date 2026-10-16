import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';

/// Pill badge widget for displaying version numbers in update dialogs.
class VersionPill extends StatelessWidget {
  final String label;
  final String version;
  final Color color;

  const VersionPill({
    super.key,
    required this.label,
    required this.version,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 3.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            version,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13.sp,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
