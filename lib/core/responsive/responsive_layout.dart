import 'package:flutter/material.dart';
import 'responsive_breakpoints.dart';

/// Builder widget that renders different layouts according to screen size.
class ResponsiveLayout extends StatelessWidget {
  final Widget Function(BuildContext context) mobile;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context) desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveBreakpoints.tabletMax) {
          return desktop(context);
        } else if (constraints.maxWidth >= ResponsiveBreakpoints.mobileMax && tablet != null) {
          return tablet!(context);
        } else {
          return mobile(context);
        }
      },
    );
  }
}

/// Restricts the maximum width of content on large screens (e.g., desktops / 4K monitors)
/// and centers the content with appropriate padding.
class WebConstrainedBox extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const WebConstrainedBox({
    super.key,
    required this.child,
    this.maxWidth = 1280.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
