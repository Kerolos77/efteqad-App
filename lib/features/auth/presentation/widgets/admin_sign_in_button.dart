import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';

/// Reusable Admin Sign-In trigger button.
class AdminSignInButton extends StatelessWidget {
  final VoidCallback? onTap;

  const AdminSignInButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: 14.h,
          horizontal: 16.w,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.primaryNavy.withValues(alpha: 0.4)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.key_outlined,
              size: 18.r,
              color: AppColors.accentGold,
            ),
            SizedBox(width: 10.w),
            Flexible(
              child: Text(
                context.tr.adminSignInButton,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentGold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
