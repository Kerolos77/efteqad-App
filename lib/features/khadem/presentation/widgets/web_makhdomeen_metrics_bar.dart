import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/widgets/web/web_widgets.dart';

class WebMakhdomeenMetricsBar extends StatelessWidget {
  final int totalCount;
  final int visitedCount;
  final int unvisitedCount;
  final int atRiskCount;
  final double percentage;
  final AppFormatters formatters;
  final bool isDesktop;
  final VoidCallback onSelectUnvisited;
  final VoidCallback onSelectAtRisk;

  const WebMakhdomeenMetricsBar({
    super.key,
    required this.totalCount,
    required this.visitedCount,
    required this.unvisitedCount,
    required this.atRiskCount,
    required this.percentage,
    required this.formatters,
    required this.isDesktop,
    required this.onSelectUnvisited,
    required this.onSelectAtRisk,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cards = [
      _buildStatCard(
        title: 'إجمالي المخدومين',
        value: formatters.formatNumber(totalCount),
        subtitle: 'المسندين إليك بالخدمة',
        icon: Icons.people_alt_rounded,
        color: AppColors.primaryLight,
        isDark: isDark,
      ),
      _buildStatCard(
        title: 'تم افتقادهم',
        value: '${formatters.formatNumber(visitedCount)} (${(percentage * 100).toInt()}%)',
        subtitle: 'نسبة الإنجاز الإجمالية',
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF10B981),
        progress: percentage,
        isDark: isDark,
      ),
      _buildStatCard(
        title: 'في انتظار الافتقاد',
        value: formatters.formatNumber(unvisitedCount),
        subtitle: 'بحاجة إلى زيارة أو تواصل',
        icon: Icons.schedule_rounded,
        color: const Color(0xFFF59E0B),
        isDark: isDark,
        onTap: onSelectUnvisited,
      ),
      _buildStatCard(
        title: 'غياب متكرر (تنبيه)',
        value: formatters.formatNumber(atRiskCount),
        subtitle: atRiskCount > 0
            ? 'غائب 3 مرات متتالية فأكثر'
            : 'لا توجد حالات غياب حرجة',
        icon: Icons.warning_amber_rounded,
        color: atRiskCount > 0 ? const Color(0xFFEF4444) : Colors.grey,
        isDark: isDark,
        isCritical: atRiskCount > 0,
        onTap: atRiskCount > 0 ? onSelectAtRisk : null,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: c,
                  ),
                ))
            .toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards.map((c) {
            return SizedBox(
              width: isTablet
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth,
              child: c,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    double? progress,
    bool isCritical = false,
    VoidCallback? onTap,
  }) {
    return WebCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              if (isCritical)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text(
                    'عاجل',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textMuted,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                color: color,
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
