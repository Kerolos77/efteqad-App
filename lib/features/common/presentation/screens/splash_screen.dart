import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _scaleAnimation = Tween<double>(
      begin: 0.97,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppConstants.splashBgColor,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );
    }

    final isWideScreen = MediaQuery.sizeOf(context).width >= 600;

    return Scaffold(
      backgroundColor: AppConstants.splashBgColor,
      body: isWideScreen ? _buildWebSplash(context) : _buildMobileSplash(context),
    );
  }

  /// Web & Desktop Layout: Beautiful centered framed portrait and spiritual branding
  Widget _buildWebSplash(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.25,
          colors: [
            Color(0xFF132338),
            AppConstants.splashBgColor,
            Color(0xFF060B12),
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
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
                        color: AppConstants.sacredGold.withValues(alpha: 0.55),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.sacredGold.withValues(alpha: 0.2),
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
                  Text(
                    context.tr.appName,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: AppConstants.sacredGold,
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 3. Sacred Verse Pill
                  Container(
                    constraints: const BoxConstraints(maxWidth: 520),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppConstants.sacredGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: AppConstants.sacredGold.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      context.tr.shepherdVerseGoodShepherd,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.sacredGold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4. Subtle Gold Indicator
                  const SizedBox(
                    width: 48,
                    height: 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppConstants.sacredGold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Mobile Layout: Full bleed immersion with bottom gradient protection
  Widget _buildMobileSplash(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Mobile Good Shepherd Image
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
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
          height: 220,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppConstants.splashBgColor.withValues(alpha: 0.95),
                  AppConstants.splashBgColor.withValues(alpha: 0.6),
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
              padding: const EdgeInsetsDirectional.only(
                bottom: 28,
                start: 24,
                end: 24,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr.appName,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: AppConstants.sacredGold,
                            blurRadius: 18,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.sacredGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: AppConstants.sacredGold.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        context.tr.shepherdVerseGoodShepherd,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.sacredGold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const SizedBox(
                      width: 32,
                      height: 2.5,
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppConstants.sacredGold,
                          ),
                        ),
                      ),
                    ),
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
