import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/web/web_widgets.dart';

class WebAnalyticsKpiBar extends StatelessWidget {
  final double? attendanceRate;
  final double visitRate;
  final int visitedCount;
  final int totalCount;
  final int atRiskCount;
  final int consistentCount;
  final AppFormatters formatters;
  final bool isDark;

  const WebAnalyticsKpiBar({
    super.key,
    required this.attendanceRate,
    required this.visitRate,
    required this.visitedCount,
    required this.totalCount,
    required this.atRiskCount,
    required this.consistentCount,
    required this.formatters,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int columns = width >= 1100 ? 4 : (width >= 650 ? 2 : 1);

        final cards = [
          _buildKpiCard(
            context,
            title: context.tr.servantGroupAttendanceRate,
            value: attendanceRate == null
                ? context.tr.insufficientAttendanceData
                : '${formatters.formatNumber(attendanceRate!, decimalDigits: 0)}%',
            subtitle: context.tr.messageAllSessions,
            icon: Icons.how_to_reg_rounded,
            color: Colors.teal,
            progress: attendanceRate != null
                ? (attendanceRate! / 100).clamp(0.0, 1.0)
                : null,
            isDark: isDark,
          ),
          _buildKpiCard(
            context,
            title: context.tr.servantGroupVisitationProgress,
            value: '${formatters.formatNumber(visitRate, decimalDigits: 0)}%',
            subtitle: context.tr.messageOfStudents(
              formatters.formatNumber(visitedCount),
              formatters.formatNumber(totalCount),
            ),
            icon: Icons.volunteer_activism_rounded,
            color: AppColors.primaryLight,
            progress: (visitRate / 100).clamp(0.0, 1.0),
            isDark: isDark,
          ),
          _buildKpiCard(
            context,
            title: context.tr.urgentVisitationNeeded,
            value: formatters.formatNumber(atRiskCount),
            subtitle: atRiskCount == 0
                ? context.tr.messageAllConsistent
                : context.tr.messageAbsenceAlert649,
            icon: Icons.warning_amber_rounded,
            color: atRiskCount == 0
                ? AppColors.successColor
                : AppColors.errorColor,
            badge: atRiskCount > 0 ? 'تنبيه' : null,
            isDark: isDark,
          ),
          _buildKpiCard(
            context,
            title: context.tr.segmentConsistent,
            value: formatters.formatNumber(consistentCount),
            subtitle: context.tr.messageAttendance75,
            icon: Icons.star_rounded,
            color: AppColors.accentGold,
            progress: totalCount > 0
                ? (consistentCount / totalCount).clamp(0.0, 1.0)
                : null,
            isDark: isDark,
          ),
        ];

        if (columns == 4) {
          return Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                Expanded(child: cards[i]),
              ],
            ],
          );
        }

        if (columns == 2) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 16),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: 16),
                  Expanded(child: cards[3]),
                ],
              ),
            ],
          );
        }

        return Column(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              cards[i],
            ],
          ],
        );
      },
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    double? progress,
    String? badge,
    required bool isDark,
  }) {
    return WebCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: value.length > 8 ? 20 : 26,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.textDark,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
                value: progress,
                minHeight: 6,
                backgroundColor:
                    isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
