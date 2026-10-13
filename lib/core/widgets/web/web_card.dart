import 'package:flutter/material.dart';

/// A web-optimized card with clean borders, elevation, and optional hover effect.
class WebCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final Widget? header;
  final bool enableHover;

  const WebCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.backgroundColor,
    this.onTap,
    this.header,
    this.enableHover = true,
  });

  @override
  State<WebCard> createState() => _WebCardState();
}

class _WebCardState extends State<WebCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseBorderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);

    final hoveredBorderColor = theme.colorScheme.primary.withOpacity(0.35);

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) {
        if (widget.enableHover) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (widget.enableHover) setState(() => _isHovered = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered ? hoveredBorderColor : baseBorderColor,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(_isHovered ? 0.35 : 0.15)
                  : Colors.black.withOpacity(_isHovered ? 0.08 : 0.02),
              blurRadius: _isHovered ? 16 : 8,
              offset: Offset(0, _isHovered ? 6 : 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: widget.padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.header != null) ...[
                  widget.header!,
                  const SizedBox(height: 16),
                ],
                widget.child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
