import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../responsive/responsive_breakpoints.dart';

/// A standard responsive header for Web pages featuring:
/// - Page title and description
/// - Search input
/// - Action buttons (e.g. Export, Add, Filter)
class WebPageHeader extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? searchBar;
  final List<Widget>? actions;

  const WebPageHeader({
    super.key,
    required this.title,
    this.description,
    this.searchBar,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = context.isDesktopScreen;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Title + Primary Actions
          if (isDesktop)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (description != null) ...[
                        SizedBox(height: 4.h),
                        Text(
                          description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (actions != null) ...[
                  SizedBox(width: 16.w),
                  Wrap(
                    spacing: 12.w,
                    runSpacing: 12.h,
                    children: actions!,
                  ),
                ],
              ],
            )
          else ...[
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 18.sp,
              ),
            ),
            if (description != null) ...[
              SizedBox(height: 4.h),
              Text(
                description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12.sp,
                ),
              ),
            ],
            if (actions != null && actions!.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: actions!,
              ),
            ],
          ],

          // Bottom Area: Search Bar
          if (searchBar != null) ...[
            SizedBox(height: 16.h),
            searchBar!,
          ],
        ],
      ),
    );
  }
}
