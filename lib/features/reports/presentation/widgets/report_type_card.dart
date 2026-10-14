import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../models/report_type.dart';

class ReportTypeCard extends StatelessWidget {
  final ReportType type;
  final bool isSelected;
  final VoidCallback onTap;

  const ReportTypeCard({
    super.key,
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = isDark ? AppConstants.sacredGold : AppConstants.primaryLight;
    final borderColor = isSelected
        ? primaryColor
        : (isDark ? Colors.white12 : Colors.grey.shade300);

    final bgColor = isSelected
        ? (isDark
            ? AppConstants.sacredGold.withValues(alpha: 0.12)
            : AppConstants.primaryLight.withValues(alpha: 0.08))
        : (isDark ? const Color(0xFF1E293B) : Colors.white);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor
                    : (isDark ? Colors.white10 : Colors.grey.shade100),
                shape: BoxShape.circle,
              ),
              child: Icon(
                type.icon,
                size: 22,
                color: isSelected
                    ? (isDark ? Colors.black87 : Colors.white)
                    : (isDark ? Colors.white70 : Colors.grey.shade700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          type.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (type == ReportType.brethrenOfLord ||
                          type == ReportType.servantPerformanceCard)
                        Container(
                          margin: const EdgeInsetsDirectional.only(start: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: type == ReportType.brethrenOfLord
                                ? Colors.red.withValues(alpha: 0.15)
                                : Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            type == ReportType.brethrenOfLord ? 'سري' : 'للأمناء',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: type == ReportType.brethrenOfLord
                                  ? Colors.red
                                  : Colors.amber.shade800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    type.description,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsetsDirectional.only(start: 8),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: primaryColor,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
