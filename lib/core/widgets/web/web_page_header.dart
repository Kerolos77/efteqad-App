import 'package:flutter/material.dart';
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
      padding: const EdgeInsets.symmetric(vertical: 16.0),
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
                        const SizedBox(height: 4),
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
                  const SizedBox(width: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
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
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(
                description!,
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: actions!,
              ),
            ],
          ],

          // Bottom Area: Search Bar
          if (searchBar != null) ...[
            const SizedBox(height: 16),
            searchBar!,
          ],
        ],
      ),
    );
  }
}
