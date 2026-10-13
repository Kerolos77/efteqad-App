import 'package:flutter/material.dart';

/// Standard responsive breakpoints for Web & Cross-platform layouts.
class ResponsiveBreakpoints {
  const ResponsiveBreakpoints._();

  static const double mobileMax = 600.0;
  static const double tabletMax = 1024.0;
  static const double desktopMax = 1440.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileMax;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileMax && width < tabletMax;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletMax;

  /// Whether current layout should render in compact mode (phones or narrow browser windows)
  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < tabletMax;

  /// Provides responsive value depending on current screen width
  static T value<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mobileMax) return mobile;
    if (width < tabletMax) return tablet ?? mobile;
    return desktop;
  }
}

/// Extension on [BuildContext] for ergonomic responsive checks.
extension ResponsiveContextX on BuildContext {
  bool get isMobileScreen => ResponsiveBreakpoints.isMobile(this);
  bool get isTabletScreen => ResponsiveBreakpoints.isTablet(this);
  bool get isDesktopScreen => ResponsiveBreakpoints.isDesktop(this);
  bool get isCompactScreen => ResponsiveBreakpoints.isCompact(this);

  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
}
