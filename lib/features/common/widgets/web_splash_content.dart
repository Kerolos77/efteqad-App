import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import 'splash_progress_indicator.dart';
import 'splash_title.dart';
import 'splash_verse_pill.dart';

class WebSplashContent extends StatelessWidget {
  final Animation<double> fadeAnimation;
  final Animation<double> scaleAnimation;

  const WebSplashContent({
    super.key,
    required this.fadeAnimation,
    required this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.25,
          colors: [
            Color(0xFF132338),
            AppColors.splashBgColor,
            Color(0xFF060B12),
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Framed Good Shepherd Sacred Image
                  Container(
                    width: 220,
                    height: 290,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.sacredGold.withValues(alpha: 0.55),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.sacredGold.withValues(alpha: 0.2),
                          blurRadius: 36,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      AppConstants.splashScreenBgPath,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. App Name
                  const SplashTitle(isWeb: true),
                  const SizedBox(height: 10),

                  // 3. Sacred Verse Pill
                  const SplashVersePill(isWeb: true),
                  const SizedBox(height: 24),

                  // 4. Subtle Gold Indicator
                  const SplashProgressIndicator(isWeb: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
