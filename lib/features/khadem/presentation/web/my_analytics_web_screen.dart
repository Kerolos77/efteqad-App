import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/attendance_session_model.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/models/visit_model.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/services/attendance_analytics_service.dart';
import '../../../../core/utils/color_generator.dart';
import '../../../../core/widgets/web/web_widgets.dart';
import '../../../common/widgets/record_visit_sheet.dart';

enum AnalyticsListViewMode { table, grid }

class MyAnalyticsWebScreen extends StatefulWidget {
  final List<MakhdomModel> myMakhdomeen;
  final List<AttendanceSessionModel> sessions;
  final List<VisitModel> visits;
  final DateTime? from, asOf;
  final VoidCallback? onVisitRecorded;

  const MyAnalyticsWebScreen({
    super.key,
    required this.myMakhdomeen,
    required this.sessions,
    this.visits = const [],
    this.from,
    this.asOf,
    this.onVisitRecorded,
  });

  @override
  State<MyAnalyticsWebScreen> createState() => _MyAnalyticsWebScreenState();
}

class _MyAnalyticsWebScreenState extends State<MyAnalyticsWebScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _behaviorFilter = 'all'; // all, consistent, irregular, atRisk, insufficient
  AnalyticsListViewMode _viewMode = AnalyticsListViewMode.table;
  int? _touchedPieIndex;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) return;
    final url = Uri.parse('tel:$clean');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    var clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.startsWith('0')) clean = '2$clean';
    if (!clean.startsWith('20') && clean.length == 11) clean = '2$clean';
    if (clean.isEmpty) return;
    final url = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 1000;
    final formatters = AppFormatters(Localizations.localeOf(context));

    // 1. If no makhdomeen assigned
    if (widget.myMakhdomeen.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: WebCard(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.query_stats_rounded,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    context.tr.noMakhdomeenAssignedTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr.noMakhdomeenAssignedSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppConstants.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 2. Metrics & Analytics Calculations
    final attendanceRate =
        AttendanceAnalyticsService.calculateOverallAttendanceRate(
          makhdomeen: widget.myMakhdomeen,
          sessions: widget.sessions,
          from: widget.from,
          asOf: widget.asOf,
        );

    final visitedIds = widget.visits.map((v) => v.makhdomId).toSet();
    final visitedCount = widget.myMakhdomeen
        .where((m) => visitedIds.contains(m.id))
        .length;
    final totalCount = widget.myMakhdomeen.length;
    final visitRate = totalCount > 0 ? (visitedCount / totalCount * 100) : 0.0;

    final impact = AttendanceAnalyticsService.calculateVisitationImpact(
      makhdomeen: widget.myMakhdomeen,
      sessions: widget.sessions,
      visits: widget.visits,
      from: widget.from,
      asOf: widget.asOf,
    );

    final segmentation = AttendanceAnalyticsService.segmentStudents(
      makhdomeen: widget.myMakhdomeen,
      sessions: widget.sessions,
      from: widget.from,
      asOf: widget.asOf,
    );

    final atRiskList = AttendanceAnalyticsService.getAtRiskStudents(
      makhdomeen: widget.myMakhdomeen,
      sessions: widget.sessions,
      from: widget.from,
      asOf: widget.asOf,
    );

    final atRiskMap = {
      for (final item in atRiskList) item.makhdom.id: item,
    };

    // Calculate individual student rates map for fast lookup
    final individualRates = <String, double?>{
      for (final m in widget.myMakhdomeen)
        m.id: AttendanceAnalyticsService.calculateOverallAttendanceRate(
          makhdomeen: [m],
          sessions: widget.sessions,
          from: widget.from,
          asOf: widget.asOf,
        ),
    };

    // Segmented and Filtered list
    List<MakhdomModel> baseList;
    switch (_behaviorFilter) {
      case 'consistent':
        baseList = segmentation.consistent;
        break;
      case 'irregular':
        baseList = segmentation.irregular;
        break;
      case 'atRisk':
        baseList = segmentation.atRisk;
        break;
      case 'insufficient':
        baseList = segmentation.insufficient;
        break;
      default:
        baseList = widget.myMakhdomeen;
    }

    final filteredList = baseList.where((m) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matches = m.fullName.toLowerCase().contains(q) ||
            m.area.toLowerCase().contains(q) ||
            m.phone.contains(q) ||
            m.address.toLowerCase().contains(q);
        if (!matches) return false;
      }
      return true;
    }).toList();

    final dateDescription = widget.from != null
        ? 'تحليل الفترة من ${formatters.formatDate(widget.from!)} إلى ${formatters.formatDate(widget.asOf ?? DateTime.now())}'
        : 'تحليلات تفاعلية شاملة لمتابعة الحضور والافتقاد لمخدوميك';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 32 : 16,
          vertical: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Page Header
            WebPageHeader(
              title: 'تحليلات الافتقاد والحضور',
              description: dateDescription,
              actions: [
                OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.myMakhdomeenPath),
                  icon: const Icon(Icons.people_alt_outlined, size: 18),
                  label: const Text('قائمة مخدوميني'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: context.tr.retryAction,
                  onPressed: () => widget.onVisitRecorded?.call(),
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Top 4 Executive KPI Metrics
            _buildExecutiveKpiBar(
              context,
              attendanceRate: attendanceRate,
              visitRate: visitRate,
              visitedCount: visitedCount,
              totalCount: totalCount,
              atRiskCount: atRiskList.length,
              consistentCount: segmentation.consistent.length,
              formatters: formatters,
              isDark: isDark,
              isDesktop: isDesktop,
            ),
            const SizedBox(height: 24),

            // Visual Analytics: Impact & Behavioral Charts
            _buildVisualChartsSection(
              context,
              impact: impact,
              segmentation: segmentation,
              totalCount: totalCount,
              formatters: formatters,
              isDark: isDark,
              isDesktop: isDesktop,
            ),
            const SizedBox(height: 24),

            // Absence Alerts & At-Risk Action Center
            _buildAbsenceAlertsSection(
              context,
              atRiskList: atRiskList,
              formatters: formatters,
              isDark: isDark,
              isDesktop: isDesktop,
            ),
            const SizedBox(height: 24),

            // Behavioral Roster Explorer (Search, Filters, Data Table & Grid)
            _buildRosterSection(
              context,
              filteredList: filteredList,
              segmentation: segmentation,
              atRiskMap: atRiskMap,
              individualRates: individualRates,
              formatters: formatters,
              isDark: isDark,
              isDesktop: isDesktop,
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TOP KPI METRICS BAR
  // -------------------------------------------------------------
  Widget _buildExecutiveKpiBar(
    BuildContext context, {
    required double? attendanceRate,
    required double visitRate,
    required int visitedCount,
    required int totalCount,
    required int atRiskCount,
    required int consistentCount,
    required AppFormatters formatters,
    required bool isDark,
    required bool isDesktop,
  }) {
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
                : '${formatters.formatNumber(attendanceRate, decimalDigits: 0)}%',
            subtitle: context.tr.messageAllSessions,
            icon: Icons.how_to_reg_rounded,
            color: Colors.teal,
            progress: attendanceRate != null ? (attendanceRate / 100).clamp(0.0, 1.0) : null,
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
            color: AppConstants.primaryLight,
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
                ? AppConstants.successColor
                : AppConstants.errorColor,
            badge: atRiskCount > 0 ? 'تنبيه' : null,
            isDark: isDark,
          ),
          _buildKpiCard(
            context,
            title: context.tr.segmentConsistent,
            value: formatters.formatNumber(consistentCount),
            subtitle: context.tr.messageAttendance75,
            icon: Icons.star_rounded,
            color: AppConstants.accentGold,
            progress: totalCount > 0 ? (consistentCount / totalCount).clamp(0.0, 1.0) : null,
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
              color: isDark ? Colors.white : AppConstants.textDark,
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
              color: AppConstants.textMuted,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // VISUAL ANALYTICS: IMPACT & PIE CHARTS
  // -------------------------------------------------------------
  Widget _buildVisualChartsSection(
    BuildContext context, {
    required VisitationImpactInfo impact,
    required BehavioralSegmentation segmentation,
    required int totalCount,
    required AppFormatters formatters,
    required bool isDark,
    required bool isDesktop,
  }) {
    final impactCard = _buildVisitationImpactCard(
      context,
      impact: impact,
      formatters: formatters,
      isDark: isDark,
    );

    final pieCard = _buildBehavioralPieChartCard(
      context,
      segmentation: segmentation,
      totalCount: totalCount,
      formatters: formatters,
      isDark: isDark,
    );

    if (isDesktop) {
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
                        color: AppConstants.textMuted,
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
                color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.blueGrey, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr.insufficientAttendanceData,
                      style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Visited Students Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppConstants.successColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      context.tr.messageVisited,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${formatters.formatNumber(impact.visitedStudentsCount)} مخدوم)',
                      style: const TextStyle(fontSize: 11, color: AppConstants.textMuted),
                    ),
                  ],
                ),
                Text(
                  '${formatters.formatNumber(impact.visitedAttendanceRate!, decimalDigits: 0)}%',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppConstants.successColor,
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
                backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.successColor),
              ),
            ),
            const SizedBox(height: 18),

            // Unvisited Students Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cancel_outlined, color: AppConstants.errorColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      context.tr.messageUnvisited,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${formatters.formatNumber(impact.unvisitedStudentsCount)} مخدوم)',
                      style: const TextStyle(fontSize: 11, color: AppConstants.textMuted),
                    ),
                  ],
                ),
                Text(
                  '${formatters.formatNumber(impact.unvisitedAttendanceRate!, decimalDigits: 0)}%',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppConstants.errorColor,
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
                backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.errorColor),
              ),
            ),
            const SizedBox(height: 20),

            // Impact Insight Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: (impact.impactPercentage! > 0
                        ? AppConstants.successColor
                        : Colors.blueGrey)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (impact.impactPercentage! > 0
                          ? AppConstants.successColor
                          : Colors.blueGrey)
                      .withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    impact.impactPercentage! > 0
                        ? Icons.trending_up_rounded
                        : Icons.info_outline,
                    color: impact.impactPercentage! > 0
                        ? AppConstants.successColor
                        : Colors.blueGrey,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr.visitationImpactValue(impact.impactPercentage!),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: impact.impactPercentage! > 0
                            ? AppConstants.successColor
                            : (isDark ? Colors.white70 : AppConstants.textDark),
                      ),
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

    final hasData = (consistent + irregular + atRisk + insufficient) > 0;

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
                  color: AppConstants.accentGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: AppConstants.accentGold,
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
                      'توزيع المخدومين حسب أنماط التفاعل والانتظام',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppConstants.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (!hasData)
            const SizedBox(
              height: 160,
              child: Center(
                child: Text('لا توجد بيانات كافية للرسم البياني'),
              ),
            )
          else ...[
            SizedBox(
              height: 160,
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
                        centerSpaceRadius: 36,
                        sections: [
                          if (consistent > 0)
                            PieChartSectionData(
                              color: AppConstants.successColor,
                              value: consistent.toDouble(),
                              title: '${((consistent / totalCount) * 100).round()}%',
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
                              title: '${((irregular / totalCount) * 100).round()}%',
                              radius: _touchedPieIndex == 1 ? 38 : 32,
                              titleStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          if (atRisk > 0)
                            PieChartSectionData(
                              color: AppConstants.errorColor,
                              value: atRisk.toDouble(),
                              title: '${((atRisk / totalCount) * 100).round()}%',
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
                              title: '${((insufficient / totalCount) * 100).round()}%',
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
                        _buildChartLegendRow(
                          color: AppConstants.successColor,
                          label: context.tr.segmentConsistent,
                          count: consistent,
                          formatters: formatters,
                        ),
                        const SizedBox(height: 8),
                        _buildChartLegendRow(
                          color: Colors.orange,
                          label: context.tr.segmentIrregular,
                          count: irregular,
                          formatters: formatters,
                        ),
                        const SizedBox(height: 8),
                        _buildChartLegendRow(
                          color: AppConstants.errorColor,
                          label: context.tr.segmentAtRisk,
                          count: atRisk,
                          formatters: formatters,
                        ),
                        if (insufficient > 0) ...[
                          const SizedBox(height: 8),
                          _buildChartLegendRow(
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

  Widget _buildChartLegendRow({
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

  // -------------------------------------------------------------
  // ABSENCE ALERTS & AT-RISK CENTER
  // -------------------------------------------------------------
  Widget _buildAbsenceAlertsSection(
    BuildContext context, {
    required List<AtRiskStudentInfo> atRiskList,
    required AppFormatters formatters,
    required bool isDark,
    required bool isDesktop,
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
                  color: (atRiskList.isEmpty
                          ? AppConstants.successColor
                          : AppConstants.errorColor)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  atRiskList.isEmpty
                      ? Icons.verified_user_rounded
                      : Icons.notifications_active_rounded,
                  color: atRiskList.isEmpty
                      ? AppConstants.successColor
                      : AppConstants.errorColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          context.tr.absenceAlertsHeader,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (atRiskList.isEmpty
                                    ? AppConstants.successColor
                                    : AppConstants.errorColor)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            formatters.formatNumber(atRiskList.length),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: atRiskList.isEmpty
                                  ? AppConstants.successColor
                                  : AppConstants.errorColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr.absenceAlertsSubtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppConstants.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (atRiskList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.successColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppConstants.successColor.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppConstants.successColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr.noAbsenceAlerts,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppConstants.successColor,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final int columns = width >= 1000 ? 3 : (width >= 600 ? 2 : 1);

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    mainAxisExtent: 140,
                  ),
                  itemCount: atRiskList.length,
                  itemBuilder: (context, index) {
                    final info = atRiskList[index];
                    return _buildAtRiskStudentCard(
                      context,
                      info: info,
                      formatters: formatters,
                      isDark: isDark,
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAtRiskStudentCard(
    BuildContext context, {
    required AtRiskStudentInfo info,
    required AppFormatters formatters,
    required bool isDark,
  }) {
    final m = info.makhdom;
    final color = info.isCritical ? AppConstants.errorColor : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.6 : 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Text(
                  m.fullName.isNotEmpty ? m.fullName[0] : context.tr.messageM,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: color,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    if (m.area.isNotEmpty)
                      Text(
                        m.area,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppConstants.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  context.tr.missedFridaysCount(info.consecutiveAbsences),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (m.phone.isNotEmpty) ...[
                IconButton.outlined(
                  tooltip: 'اتصال هاتفياً',
                  onPressed: () => _makeCall(m.phone),
                  icon: const Icon(Icons.phone_rounded, size: 14, color: AppConstants.successColor),
                  style: IconButton.styleFrom(
                    side: const BorderSide(color: AppConstants.successColor),
                    padding: const EdgeInsets.all(6),
                    minimumSize: const Size(28, 28),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.outlined(
                  tooltip: 'مراسلة عبر واتساب',
                  onPressed: () => _openWhatsApp(m.phone),
                  icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 14, color: Colors.teal),
                  style: IconButton.styleFrom(
                    side: const BorderSide(color: Colors.teal),
                    padding: const EdgeInsets.all(6),
                    minimumSize: const Size(28, 28),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              ElevatedButton.icon(
                onPressed: () async {
                  await RecordVisitSheet.show(context, makhdom: m);
                  if (mounted) widget.onVisitRecorded?.call();
                },
                icon: const Icon(Icons.edit_calendar_rounded, size: 13, color: Colors.white),
                label: const Text('تسجيل افتقاد', style: TextStyle(fontSize: 11, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryLight,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(0, 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // BEHAVIORAL ROSTER SECTION (TABLE & GRID)
  // -------------------------------------------------------------
  Widget _buildRosterSection(
    BuildContext context, {
    required List<MakhdomModel> filteredList,
    required BehavioralSegmentation segmentation,
    required Map<String, AtRiskStudentInfo> atRiskMap,
    required Map<String, double?> individualRates,
    required AppFormatters formatters,
    required bool isDark,
    required bool isDesktop,
  }) {
    return WebCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Title & View Mode Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سجل متابعة المخدومين والانتظام',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'استعراض تفاصيل الحضور والتواصل المباشر مع كل مخدوم',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppConstants.textMuted,
                    ),
                  ),
                ],
              ),
              if (isDesktop)
                SegmentedButton<AnalyticsListViewMode>(
                  segments: const [
                    ButtonSegment(
                      value: AnalyticsListViewMode.table,
                      icon: Icon(Icons.table_chart_outlined, size: 16),
                      label: Text('جدول'),
                    ),
                    ButtonSegment(
                      value: AnalyticsListViewMode.grid,
                      icon: Icon(Icons.grid_view_rounded, size: 16),
                      label: Text('بطاقات'),
                    ),
                  ],
                  selected: {_viewMode},
                  onSelectionChanged: (set) {
                    setState(() => _viewMode = set.first);
                  },
                ),
            ],
          ),
          const SizedBox(height: 18),

          // Search & Filter Controls
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              // Search input
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'بحث بالاسم، المنطقة أو الهاتف...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? AppConstants.surfaceDark : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark ? AppConstants.cardBorderDark : AppConstants.cardBorderLight,
                      ),
                    ),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                ),
              ),

              // Filter Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSegmentFilterChip(
                    context,
                    label: context.tr.all,
                    count: widget.myMakhdomeen.length,
                    key: 'all',
                    color: AppConstants.primaryLight,
                    isDark: isDark,
                  ),
                  _buildSegmentFilterChip(
                    context,
                    label: context.tr.segmentConsistent,
                    count: segmentation.consistent.length,
                    key: 'consistent',
                    color: AppConstants.successColor,
                    isDark: isDark,
                  ),
                  _buildSegmentFilterChip(
                    context,
                    label: context.tr.segmentIrregular,
                    count: segmentation.irregular.length,
                    key: 'irregular',
                    color: Colors.orange,
                    isDark: isDark,
                  ),
                  _buildSegmentFilterChip(
                    context,
                    label: context.tr.segmentAtRisk,
                    count: segmentation.atRisk.length,
                    key: 'atRisk',
                    color: AppConstants.errorColor,
                    isDark: isDark,
                  ),
                  if (segmentation.insufficient.isNotEmpty)
                    _buildSegmentFilterChip(
                      context,
                      label: 'غير كافٍ',
                      count: segmentation.insufficient.length,
                      key: 'insufficient',
                      color: Colors.blueGrey,
                      isDark: isDark,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // List / Table Content
          if (filteredList.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 40,
                    color: isDark ? Colors.white30 : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr.noSearchResults,
                    style: const TextStyle(fontSize: 14, color: AppConstants.textMuted),
                  ),
                ],
              ),
            )
          else if (isDesktop && _viewMode == AnalyticsListViewMode.table)
            _buildDataTable(
              context,
              filteredList: filteredList,
              atRiskMap: atRiskMap,
              individualRates: individualRates,
              formatters: formatters,
              isDark: isDark,
            )
          else
            _buildGridCards(
              context,
              filteredList: filteredList,
              atRiskMap: atRiskMap,
              individualRates: individualRates,
              formatters: formatters,
              isDark: isDark,
              isDesktop: isDesktop,
            ),
        ],
      ),
    );
  }

  Widget _buildSegmentFilterChip(
    BuildContext context, {
    required String label,
    required int count,
    required String key,
    required Color color,
    required bool isDark,
  }) {
    final isSelected = _behaviorFilter == key;
    return ChoiceChip(
      selected: isSelected,
      selectedColor: color.withValues(alpha: 0.18),
      backgroundColor: isDark ? AppConstants.surfaceDark : Colors.white,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? color : (isDark ? Colors.white70 : AppConstants.textDark),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: isSelected ? color : color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ),
        ],
      ),
      side: BorderSide(
        color: isSelected
            ? color
            : (isDark ? AppConstants.cardBorderDark : AppConstants.cardBorderLight),
      ),
      onSelected: (_) => setState(() => _behaviorFilter = key),
    );
  }

  // -------------------------------------------------------------
  // DATA TABLE VIEW
  // -------------------------------------------------------------
  Widget _buildDataTable(
    BuildContext context, {
    required List<MakhdomModel> filteredList,
    required Map<String, AtRiskStudentInfo> atRiskMap,
    required Map<String, double?> individualRates,
    required AppFormatters formatters,
    required bool isDark,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? AppConstants.cardBorderDark : AppConstants.cardBorderLight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 850),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
              ),
              dataRowMinHeight: 56,
              dataRowMaxHeight: 64,
              horizontalMargin: 16,
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('المخدوم', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('المنطقة', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('رقم الهاتف', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('نسبة الحضور', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('حالة التفاعل', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('إجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: filteredList.map((m) {
                final rate = individualRates[m.id];
                final atRiskInfo = atRiskMap[m.id];
                final isAtRisk = atRiskInfo != null;
                final isConsistent = rate != null && rate >= 75;
                final isIrregular = rate != null && rate < 75 && rate >= 40 && !isAtRisk;

                Color badgeColor;
                String badgeText;
                if (isAtRisk) {
                  badgeColor = atRiskInfo.isCritical ? AppConstants.errorColor : Colors.orange;
                  badgeText = context.tr.missedFridaysCount(atRiskInfo.consecutiveAbsences);
                } else if (isConsistent) {
                  badgeColor = AppConstants.successColor;
                  badgeText = context.tr.segmentConsistent;
                } else if (isIrregular) {
                  badgeColor = Colors.orange;
                  badgeText = context.tr.segmentIrregular;
                } else {
                  badgeColor = Colors.blueGrey;
                  badgeText = 'غير كافٍ';
                }

                return DataRow(
                  cells: [
                    // Name & Avatar
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: ColorGenerator.getColorForId(m.fullName).withValues(alpha: 0.2),
                            child: Text(
                              m.fullName.isNotEmpty ? m.fullName[0] : 'م',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: ColorGenerator.getColorForId(m.fullName),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            m.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    // Area
                    DataCell(
                      Text(
                        m.area.isNotEmpty ? m.area : '—',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                    // Phone & Quick Contact
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            m.phone.isNotEmpty ? m.phone : '—',
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (m.phone.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const Icon(Icons.phone_rounded, size: 16, color: AppConstants.successColor),
                              tooltip: 'اتصال',
                              onPressed: () => _makeCall(m.phone),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16, color: Colors.teal),
                              tooltip: 'واتساب',
                              onPressed: () => _openWhatsApp(m.phone),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Rate
                    DataCell(
                      rate == null
                          ? const Text('—', style: TextStyle(color: AppConstants.textMuted))
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 48,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: (rate / 100).clamp(0.0, 1.0),
                                      minHeight: 6,
                                      backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        rate >= 75
                                            ? AppConstants.successColor
                                            : (rate >= 40 ? Colors.orange : AppConstants.errorColor),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${formatters.formatNumber(rate, decimalDigits: 0)}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    // Status Badge
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ),
                    // Actions
                    DataCell(
                      ElevatedButton.icon(
                        onPressed: () async {
                          await RecordVisitSheet.show(context, makhdom: m);
                          if (mounted) widget.onVisitRecorded?.call();
                        },
                        icon: const Icon(Icons.edit_calendar_rounded, size: 14, color: Colors.white),
                        label: const Text('افتقاد', style: TextStyle(fontSize: 12, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryLight,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // GRID CARDS VIEW
  // -------------------------------------------------------------
  Widget _buildGridCards(
    BuildContext context, {
    required List<MakhdomModel> filteredList,
    required Map<String, AtRiskStudentInfo> atRiskMap,
    required Map<String, double?> individualRates,
    required AppFormatters formatters,
    required bool isDark,
    required bool isDesktop,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int columns = width >= 900 ? 3 : (width >= 550 ? 2 : 1);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 160,
          ),
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final m = filteredList[index];
            final rate = individualRates[m.id];
            final atRiskInfo = atRiskMap[m.id];
            final isAtRisk = atRiskInfo != null;
            final isConsistent = rate != null && rate >= 75;
            final isIrregular = rate != null && rate < 75 && rate >= 40 && !isAtRisk;

            Color statusColor;
            String statusText;
            if (isAtRisk) {
              statusColor = atRiskInfo.isCritical ? AppConstants.errorColor : Colors.orange;
              statusText = context.tr.missedFridaysCount(atRiskInfo.consecutiveAbsences);
            } else if (isConsistent) {
              statusColor = AppConstants.successColor;
              statusText = context.tr.segmentConsistent;
            } else if (isIrregular) {
              statusColor = Colors.orange;
              statusText = context.tr.segmentIrregular;
            } else {
              statusColor = Colors.blueGrey;
              statusText = 'غير كافٍ';
            }

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppConstants.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppConstants.cardBorderDark : AppConstants.cardBorderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: ColorGenerator.getColorForId(m.fullName).withValues(alpha: 0.2),
                        child: Text(
                          m.fullName.isNotEmpty ? m.fullName[0] : 'م',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: ColorGenerator.getColorForId(m.fullName),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            if (m.area.isNotEmpty)
                              Text(
                                m.area,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppConstants.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 10.5,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (rate != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'نسبة الحضور',
                          style: TextStyle(fontSize: 11, color: AppConstants.textMuted),
                        ),
                        Text(
                          '${formatters.formatNumber(rate, decimalDigits: 0)}%',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: rate >= 75
                                ? AppConstants.successColor
                                : (rate >= 40 ? Colors.orange : AppConstants.errorColor),
                          ),
                        ),
                      ],
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (rate / 100).clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          rate >= 75
                              ? AppConstants.successColor
                              : (rate >= 40 ? Colors.orange : AppConstants.errorColor),
                        ),
                      ),
                    ),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (m.phone.isNotEmpty) ...[
                        IconButton.outlined(
                          tooltip: 'اتصال هاتفياً',
                          onPressed: () => _makeCall(m.phone),
                          icon: const Icon(Icons.phone_rounded, size: 14, color: AppConstants.successColor),
                          style: IconButton.styleFrom(
                            side: const BorderSide(color: AppConstants.successColor),
                            padding: const EdgeInsets.all(6),
                            minimumSize: const Size(28, 28),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton.outlined(
                          tooltip: 'مراسلة عبر واتساب',
                          onPressed: () => _openWhatsApp(m.phone),
                          icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 14, color: Colors.teal),
                          style: IconButton.styleFrom(
                            side: const BorderSide(color: Colors.teal),
                            padding: const EdgeInsets.all(6),
                            minimumSize: const Size(28, 28),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      ElevatedButton.icon(
                        onPressed: () async {
                          await RecordVisitSheet.show(context, makhdom: m);
                          if (mounted) widget.onVisitRecorded?.call();
                        },
                        icon: const Icon(Icons.edit_calendar_rounded, size: 13, color: Colors.white),
                        label: const Text('افتقاد', style: TextStyle(fontSize: 11, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryLight,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: const Size(0, 30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
