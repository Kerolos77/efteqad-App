import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/attendance_session_model.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/models/visit_model.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/services/attendance_analytics_service.dart';
import '../../../../core/widgets/web/web_widgets.dart';
import '../widgets/web_absence_alerts_section.dart';
import '../widgets/web_analytics_charts_section.dart';
import '../widgets/web_analytics_kpi_bar.dart';
import '../widgets/web_analytics_roster_section.dart';

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
                      color: AppColors.textMuted,
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

    final individualRates = <String, double?>{
      for (final m in widget.myMakhdomeen)
        m.id: AttendanceAnalyticsService.calculateOverallAttendanceRate(
          makhdomeen: [m],
          sessions: widget.sessions,
          from: widget.from,
          asOf: widget.asOf,
        ),
    };

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
            WebAnalyticsKpiBar(
              attendanceRate: attendanceRate,
              visitRate: visitRate,
              visitedCount: visitedCount,
              totalCount: totalCount,
              atRiskCount: atRiskList.length,
              consistentCount: segmentation.consistent.length,
              formatters: formatters,
              isDark: isDark,
            ),
            const SizedBox(height: 24),

            // Visual Analytics: Impact & Behavioral Charts
            WebAnalyticsChartsSection(
              impact: impact,
              segmentation: segmentation,
              totalCount: totalCount,
              formatters: formatters,
              isDark: isDark,
              isDesktop: isDesktop,
            ),
            const SizedBox(height: 24),

            // Absence Alerts & At-Risk Action Center
            WebAbsenceAlertsSection(
              atRiskList: atRiskList,
              formatters: formatters,
              isDark: isDark,
              onMakeCall: _makeCall,
              onOpenWhatsApp: _openWhatsApp,
              onVisitRecorded: () => widget.onVisitRecorded?.call(),
            ),
            const SizedBox(height: 24),

            // Behavioral Roster Explorer
            WebAnalyticsRosterSection(
              filteredList: filteredList,
              segmentation: segmentation,
              atRiskMap: atRiskMap,
              individualRates: individualRates,
              formatters: formatters,
              isDark: isDark,
              isDesktop: isDesktop,
              viewMode: _viewMode,
              onViewModeChanged: (mode) => setState(() => _viewMode = mode),
              behaviorFilter: _behaviorFilter,
              onFilterChanged: (filter) =>
                  setState(() => _behaviorFilter = filter),
              searchController: _searchController,
              searchQuery: _searchQuery,
              onSearchChanged: (val) =>
                  setState(() => _searchQuery = val.trim()),
              onClearSearch: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              onMakeCall: _makeCall,
              onOpenWhatsApp: _openWhatsApp,
              onVisitRecorded: () => widget.onVisitRecorded?.call(),
            ),
          ],
        ),
      ),
    );
  }
}
