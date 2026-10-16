import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';

/// Branding header for Auth screens (App logo, title, spiritual verse, and tagline).
class AuthBrandingHeader extends StatelessWidget {
  final double? logoSize;
  final bool showVerse;

  const AuthBrandingHeader({
    super.key,
    this.logoSize,
    this.showVerse = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveLogoSize = logoSize ?? 108.r;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // App Logo inside a royal capsule with sacred gold glow
        Container(
          width: effectiveLogoSize,
          height: effectiveLogoSize,
          decoration: BoxDecoration(
            color: AppColors.primaryNavy,
            borderRadius: BorderRadius.circular(effectiveLogoSize * 0.26),
            border: Border.all(
              color: AppColors.sacredGold.withValues(alpha: 0.7),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.sacredGold.withValues(
                  alpha: isDark ? 0.35 : 0.2,
                ),
                blurRadius: 30.r,
                spreadRadius: 2.r,
                offset: Offset(0, 6.h),
              ),
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isDark ? 0.5 : 0.12,
                ),
                blurRadius: 22.r,
                offset: Offset(0, 10.h),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(effectiveLogoSize * 0.24),
            child: Image.asset(
              AppConstants.appLogoPath,
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(height: 22.h),

        // App Title
        Text(
          context.tr.appName,
          style: TextStyle(
            fontSize: 32.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
        SizedBox(height: 8.h),

        // Spiritual Verse Capsule
        if (showVerse) ...[
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 6.h,
            ),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withValues(
                alpha: isDark ? 0.15 : 0.1,
              ),
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(
                color: AppColors.accentGold.withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            child: Text(
              context.tr.shepherdVerse,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.accentGold,
              ),
            ),
          ),
          SizedBox(height: 6.h),
        ],

        // Subtitle / Tagline
        Text(
          context.tr.appTagline,
          style: TextStyle(
            fontSize: 13.sp,
            color: AppColors.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
