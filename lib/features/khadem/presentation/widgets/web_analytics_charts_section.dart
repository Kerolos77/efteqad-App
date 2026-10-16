import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/attendance_analytics_service.dart';
import '../../../../core/widgets/web/web_widgets.dart';

class WebAnalyticsChartsSection extends StatefulWidget {
  final VisitationImpactInfo impact;
  final BehavioralSegmentation segmentation;
  final int totalCount;
  final AppFormatters formatters;
  final bool isDark;
  final bool isDesktop;

  const WebAnalyticsChartsSection({
    super.key,
    required this.impact,
    required this.segmentation,
    required this.totalCount,
    required this.formatters,
    required this.isDark,
    required this.isDesktop,
  });

  @override
  State<WebAnalyticsChartsSection> createState() =>
      _WebAnalyticsChartsSectionState();
}

class _WebAnalyticsChartsSectionState extends State<WebAnalyticsChartsSection> {
  int? _touchedPieIndex;

  @override
  Widget build(BuildContext context) {
    final impactCard = _buildVisitationImpactCard(
      context,
      impact: widget.impact,
      formatters: widget.formatters,
      isDark: widget.isDark,
    );

    final pieCard = _buildBehavioralPieChartCard(
      context,
      segmentation: widget.segmentation,
      totalCount: widget.totalCount,
      formatters: widget.formatters,
      isDark: widget.isDark,
    );

    if (widget.isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: impactCard),
          const SizedBox(width: 20),
          Expanded(flex: 5, child: pieCard),
        ],
      );
    }

    return Column(
      children: [
        impactCard,
        const SizedBox(height: 16),
        pieCard,
      ],
    );
  }

  Widget _buildVisitationImpactCard(
    BuildContext context, {
    required VisitationImpactInfo impact,
    required AppFormatters formatters,
    required bool isDark,
  }) {
    return WebCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  color: Colors.amber,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr.visitationImpactHeader,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr.visitationImpactSubtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (!impact.hasSufficientData)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.blueGrey,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr.insufficientAttendanceData,
                      style:
                          const TextStyle(fontSize: 13, color: Colors.blueGrey),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: AppColors.successColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.tr.messageVisited,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${formatters.formatNumber(impact.visitedStudentsCount)} مخدوم)',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${formatters.formatNumber(impact.visitedAttendanceRate!, decimalDigits: 0)}%',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.successColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (impact.visitedAttendanceRate! / 100).clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor:
                    isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.successColor,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.cancel_outlined,
                      color: AppColors.errorColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.tr.messageUnvisited,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${formatters.formatNumber(impact.unvisitedStudentsCount)} مخدوم)',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${formatters.formatNumber(impact.unvisitedAttendanceRate!, decimalDigits: 0)}%',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.errorColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (impact.unvisitedAttendanceRate! / 100).clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor:
                    isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.errorColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBehavioralPieChartCard(
    BuildContext context, {
    required BehavioralSegmentation segmentation,
    required int totalCount,
    required AppFormatters formatters,
    required bool isDark,
  }) {
    final consistent = segmentation.consistent.length;
    final irregular = segmentation.irregular.length;
    final atRisk = segmentation.atRisk.length;
    final insufficient = segmentation.insufficient.length;

    return WebCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pie_chart_outline_rounded,
                  color: Colors.indigoAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr.messageBehavioralSegmentation651,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'توزيع المخدومين حسب نمط حضورهم للأنشطة',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (totalCount == 0)
            const SizedBox(
              height: 140,
              child: Center(
                child: Text('لا توجد بيانات كافية لعرض التوزيع'),
              ),
            )
          else ...[
            SizedBox(
              height: 140,
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                _touchedPieIndex = -1;
                                return;
                              }
                              _touchedPieIndex = pieTouchResponse
                                  .touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 3,
                        centerSpaceRadius: 28,
                        sections: [
                          if (consistent > 0)
                            PieChartSectionData(
                              color: AppColors.successColor,
                              value: consistent.toDouble(),
                              title:
                                  '${((consistent / totalCount) * 100).round()}%',
                              radius: _touchedPieIndex == 0 ? 38 : 32,
                              titleStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          if (irregular > 0)
                            PieChartSectionData(
                              color: Colors.orange,
                              value: irregular.toDouble(),
                              title:
                                  '${((irregular / totalCount) * 100).round()}%',
                              radius: _touchedPieIndex == 1 ? 38 : 32,
                              titleStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          if (atRisk > 0)
                            PieChartSectionData(
                              color: AppColors.errorColor,
                              value: atRisk.toDouble(),
                              title:
                                  '${((atRisk / totalCount) * 100).round()}%',
                              radius: _touchedPieIndex == 2 ? 38 : 32,
                              titleStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          if (insufficient > 0)
                            PieChartSectionData(
                              color: Colors.blueGrey,
                              value: insufficient.toDouble(),
                              title:
                                  '${((insufficient / totalCount) * 100).round()}%',
                              radius: _touchedPieIndex == 3 ? 38 : 32,
                              titleStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 6,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendRow(
                          color: AppColors.successColor,
                          label: context.tr.segmentConsistent,
                          count: consistent,
                          formatters: formatters,
                        ),
                        const SizedBox(height: 8),
                        _buildLegendRow(
                          color: Colors.orange,
                          label: context.tr.segmentIrregular,
                          count: irregular,
                          formatters: formatters,
                        ),
                        const SizedBox(height: 8),
                        _buildLegendRow(
                          color: AppColors.errorColor,
                          label: context.tr.segmentAtRisk,
                          count: atRisk,
                          formatters: formatters,
                        ),
                        if (insufficient > 0) ...[
                          const SizedBox(height: 8),
                          _buildLegendRow(
                            color: Colors.blueGrey,
                            label: 'غير مكتمل',
                            count: insufficient,
                            formatters: formatters,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendRow({
    required Color color,
    required String label,
    required int count,
    required AppFormatters formatters,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          formatters.formatNumber(count),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
