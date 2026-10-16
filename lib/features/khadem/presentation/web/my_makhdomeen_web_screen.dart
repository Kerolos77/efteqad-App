import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/models/attendance_session_model.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/services/attendance_analytics_service.dart';
import '../../../../core/widgets/web/web_widgets.dart';
import '../widgets/web_makhdom_card.dart';
import '../widgets/web_makhdomeen_controls_bar.dart';
import '../widgets/web_makhdomeen_data_table.dart';
import '../widgets/web_makhdomeen_metrics_bar.dart';

enum MakhdomeenViewMode { table, grid }

class MyMakhdomeenWebScreen extends StatefulWidget {
  final List<MakhdomModel> myMakhdomeen;
  final List<AttendanceSessionModel> sessions;
  final VoidCallback? onSwitchToAnalytics;

  const MyMakhdomeenWebScreen({
    super.key,
    required this.myMakhdomeen,
    this.sessions = const [],
    this.onSwitchToAnalytics,
  });

  @override
  State<MyMakhdomeenWebScreen> createState() => _MyMakhdomeenWebScreenState();
}

class _MyMakhdomeenWebScreenState extends State<MyMakhdomeenWebScreen> {
  String _searchQuery = '';
  String _activeFilter = 'all'; // all, unvisited, visited, brethren, at_risk
  MakhdomeenViewMode _viewMode = MakhdomeenViewMode.table;
  final TextEditingController _searchController = TextEditingController();

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
    final url = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openLocation(String? urlString) async {
    if (urlString == null || urlString.trim().isEmpty) return;
    final url = Uri.parse(urlString.trim());
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ $label: $text'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        width: 320,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 1000;
    final formatters = AppFormatters(Localizations.localeOf(context));

    // 1. Calculate Analytics & At-Risk mapping
    final totalCount = widget.myMakhdomeen.length;
    final visitedCount =
        widget.myMakhdomeen.where((m) => m.visitCount > 0).length;
    final unvisitedCount = totalCount - visitedCount;
    final brethrenCount =
        widget.myMakhdomeen.where((m) => m.isBrethrenOfLord).length;
    final percentage = totalCount > 0 ? (visitedCount / totalCount) : 0.0;

    final atRiskList = widget.sessions.isNotEmpty
        ? AttendanceAnalyticsService.getAtRiskStudents(
            makhdomeen: widget.myMakhdomeen,
            sessions: widget.sessions,
          )
        : <AtRiskStudentInfo>[];

    final atRiskMap = {
      for (final item in atRiskList) item.makhdom.id: item,
    };

    // 2. Filter & Search Makhdomeen
    final filteredList = widget.myMakhdomeen.where((m) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matches = m.fullName.toLowerCase().contains(q) ||
            m.area.toLowerCase().contains(q) ||
            m.phone.contains(q) ||
            m.address.toLowerCase().contains(q);
        if (!matches) return false;
      }

      switch (_activeFilter) {
        case 'unvisited':
          return m.visitCount == 0;
        case 'visited':
          return m.visitCount > 0;
        case 'brethren':
          return m.isBrethrenOfLord;
        case 'at_risk':
          return atRiskMap.containsKey(m.id);
        default:
          return true;
      }
    }).toList();

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
            // Header
            WebPageHeader(
              title: 'مخدوميني',
              description:
                  'إدارة ومتابعة أحوال المخدومين وتسجيل الافتقاد بدقة وسهولة',
              actions: [
                if (widget.onSwitchToAnalytics != null)
                  OutlinedButton.icon(
                    onPressed: widget.onSwitchToAnalytics,
                    icon: const Icon(Icons.analytics_outlined, size: 18),
                    label: const Text('تقرير الافتقاد والتحليلات'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Top Metrics Bar
            WebMakhdomeenMetricsBar(
              totalCount: totalCount,
              visitedCount: visitedCount,
              unvisitedCount: unvisitedCount,
              atRiskCount: atRiskList.length,
              percentage: percentage,
              formatters: formatters,
              isDesktop: isDesktop,
              onSelectUnvisited: () =>
                  setState(() => _activeFilter = 'unvisited'),
              onSelectAtRisk: () => setState(() => _activeFilter = 'at_risk'),
            ),
            const SizedBox(height: 24),

            // Search, Filter & View Controls
            WebMakhdomeenControlsBar(
              searchController: _searchController,
              searchQuery: _searchQuery,
              onSearchChanged: (val) =>
                  setState(() => _searchQuery = val.trim()),
              onClearSearch: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              activeFilter: _activeFilter,
              onFilterChanged: (key) => setState(() => _activeFilter = key),
              viewMode: _viewMode,
              onViewModeChanged: (mode) => setState(() => _viewMode = mode),
              totalCount: totalCount,
              visitedCount: visitedCount,
              unvisitedCount: unvisitedCount,
              brethrenCount: brethrenCount,
              atRiskCount: atRiskList.length,
              formatters: formatters,
              isDesktop: isDesktop,
            ),
            const SizedBox(height: 20),

            // Makhdomeen Content (Table or Grid)
            if (widget.myMakhdomeen.isEmpty)
              _buildEmptyState(context, isSearch: false)
            else if (filteredList.isEmpty)
              _buildEmptyState(context, isSearch: true)
            else if (isDesktop && _viewMode == MakhdomeenViewMode.table)
              WebMakhdomeenDataTable(
                list: filteredList,
                atRiskMap: atRiskMap,
                formatters: formatters,
                onMakeCall: _makeCall,
                onOpenWhatsApp: _openWhatsApp,
                onOpenLocation: _openLocation,
                onCopy: (text, label) =>
                    _copyToClipboard(context, text, label),
              )
            else
              _buildGridCards(
                context,
                filteredList,
                atRiskMap,
                formatters,
                isDesktop,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCards(
    BuildContext context,
    List<MakhdomModel> list,
    Map<String, AtRiskStudentInfo> atRiskMap,
    AppFormatters formatters,
    bool isDesktop,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = isDesktop
            ? (constraints.maxWidth - 32) / 3
            : constraints.maxWidth >= 640
                ? (constraints.maxWidth - 16) / 2
                : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: list.map((m) {
            final atRisk = atRiskMap[m.id];
            return SizedBox(
              width: cardWidth,
              child: WebMakhdomCard(
                makhdom: m,
                atRisk: atRisk,
                formatters: formatters,
                onCall: () => _makeCall(m.phone),
                onWhatsApp: () => _openWhatsApp(m.phone),
                onOpenLocation: m.homeLocationUrl != null &&
                        m.homeLocationUrl!.isNotEmpty
                    ? () => _openLocation(m.homeLocationUrl)
                    : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool isSearch}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearch
                    ? Icons.search_off_rounded
                    : Icons.people_outline_rounded,
                size: 48,
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isSearch
                  ? 'لا توجد نتائج مطابقة لبحثك'
                  : 'لا يوجد مخدومين مسندين إليك حالياً',
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(height: 6),
            Text(
              isSearch
                  ? 'جرب البحث باسم آخر أو تغيير الفلتر المحدد'
                  : 'سيقوم أمين الخدمة أو المشرف بإسناد مخدومين لمتابعتهم قريباً',
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            if (isSearch) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _activeFilter = 'all';
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('إعادة ضبط البحث'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
