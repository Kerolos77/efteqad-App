import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import 'splash_progress_indicator.dart';
import 'splash_title.dart';
import 'splash_verse_pill.dart';

class MobileSplashContent extends StatelessWidget {
  final AnimationController controller;
  final Animation<double> fadeAnimation;
  final Animation<double> scaleAnimation;

  const MobileSplashContent({
    super.key,
    required this.controller,
    required this.fadeAnimation,
    required this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Mobile Good Shepherd Image
        AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return Opacity(
              opacity: fadeAnimation.value,
              child: Transform.scale(
                scale: scaleAnimation.value,
                child: Image.asset(
                  AppConstants.splashScreenBgPath,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  width: double.infinity,
                  height: double.infinity,
                  filterQuality: FilterQuality.high,
                ),
              ),
            );
          },
        ),

        // 2. Bottom Gradient Protection
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 220.h,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppColors.splashBgColor.withValues(alpha: 0.95),
                  AppColors.splashBgColor.withValues(alpha: 0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // 3. Typography & Sacred Verse
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                bottom: 28.h,
                start: 24.w,
                end: 24.w,
              ),
              child: FadeTransition(
                opacity: fadeAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SplashTitle(isWeb: false),
                    SizedBox(height: 6.h),
                    const SplashVersePill(isWeb: false),
                    SizedBox(height: 18.h),
                    const SplashProgressIndicator(isWeb: false),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
