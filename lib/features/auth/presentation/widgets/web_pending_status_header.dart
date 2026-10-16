import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/responsive/responsive_breakpoints.dart';

/// Status emblem and title header for Web Pending Assignment screen.
class WebPendingStatusHeader extends StatelessWidget {
  const WebPendingStatusHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = context.tr;
    final isDesktop = context.isDesktopScreen;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // App Emblem & Status Badge
        Center(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: isDesktop ? 84 : 84.r,
                height: isDesktop ? 84 : 84.r,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.primaryNavy,
                      AppColors.primaryLight,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryLight.withValues(alpha: 0.3),
                      blurRadius: isDesktop ? 16 : 16.r,
                      offset: Offset(0, isDesktop ? 6 : 6.h),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.hourglass_top_rounded,
                  color: AppColors.sacredGold,
                  size: isDesktop ? 40 : 40.r,
                ),
              ),
              Container(
                padding: EdgeInsets.all(isDesktop ? 6 : 6.r),
                decoration: const BoxDecoration(
                  color: AppColors.sacredGold,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: AppColors.primaryNavy,
                  size: isDesktop ? 16 : 16.r,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isDesktop ? 24 : 20.h),

        // Title & Description
        Text(
          tr.pendingStatusTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            fontSize: isDesktop ? null : 20.sp,
          ),
        ),
        SizedBox(height: isDesktop ? 10 : 8.h),
        Text(
          tr.pendingStatusDesc,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isDesktop ? 14 : 13.sp,
            height: 1.6,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
