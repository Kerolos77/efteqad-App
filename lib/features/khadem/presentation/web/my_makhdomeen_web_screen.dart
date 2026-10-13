import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/localization/domain_labels.dart';
import '../../../../core/models/attendance_session_model.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/services/attendance_analytics_service.dart';
import '../../../../core/utils/color_generator.dart';
import '../../../../core/widgets/web/web_widgets.dart';
import '../../../common/widgets/record_visit_sheet.dart';

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
    final visitedCount = widget.myMakhdomeen.where((m) => m.visitCount > 0).length;
    final unvisitedCount = totalCount - visitedCount;
    final brethrenCount = widget.myMakhdomeen.where((m) => m.isBrethrenOfLord).length;
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
              description: 'إدارة ومتابعة أحوال المخدومين وتسجيل الافتقاد بدقة وسهولة',
              actions: [
                if (widget.onSwitchToAnalytics != null)
                  OutlinedButton.icon(
                    onPressed: widget.onSwitchToAnalytics,
                    icon: const Icon(Icons.analytics_outlined, size: 18),
                    label: const Text('تقرير الافتقاد والتحليلات'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Top Metrics Bar (4 Responsive Cards)
            _buildMetricsBar(
              context,
              totalCount: totalCount,
              visitedCount: visitedCount,
              unvisitedCount: unvisitedCount,
              atRiskCount: atRiskList.length,
              brethrenCount: brethrenCount,
              percentage: percentage,
              formatters: formatters,
              isDesktop: isDesktop,
            ),
            const SizedBox(height: 24),

            // Search, Filter & View Controls
            _buildControlsBar(
              context,
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
              _buildDataTable(context, filteredList, atRiskMap, formatters)
            else
              _buildGridCards(context, filteredList, atRiskMap, formatters, isDesktop),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TOP METRIC CARDS
  // ==========================================
  Widget _buildMetricsBar(
    BuildContext context, {
    required int totalCount,
    required int visitedCount,
    required int unvisitedCount,
    required int atRiskCount,
    required int brethrenCount,
    required double percentage,
    required AppFormatters formatters,
    required bool isDesktop,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cards = [
      _buildStatCard(
        title: 'إجمالي المخدومين',
        value: formatters.formatNumber(totalCount),
        subtitle: 'المسندين إليك بالخدمة',
        icon: Icons.people_alt_rounded,
        color: AppConstants.primaryLight,
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
        onTap: () => setState(() => _activeFilter = 'unvisited'),
      ),
      _buildStatCard(
        title: 'غياب متكرر (تنبيه)',
        value: formatters.formatNumber(atRiskCount),
        subtitle: atRiskCount > 0 ? 'غائب 3 مرات متتالية فأكثر' : 'لا توجد حالات غياب حرجة',
        icon: Icons.warning_amber_rounded,
        color: atRiskCount > 0 ? const Color(0xFFEF4444) : Colors.grey,
        isDark: isDark,
        isCritical: atRiskCount > 0,
        onTap: atRiskCount > 0 ? () => setState(() => _activeFilter = 'at_risk') : null,
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
              width: isTablet ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth,
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
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
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : AppConstants.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppConstants.textMuted),
          ),
          if (progress != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // CONTROLS & FILTER BAR
  // ==========================================
  Widget _buildControlsBar(
    BuildContext context, {
    required int totalCount,
    required int visitedCount,
    required int unvisitedCount,
    required int brethrenCount,
    required int atRiskCount,
    required AppFormatters formatters,
    required bool isDesktop,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return WebCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Search Input Field
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'ابحث بالاسم، المنطقة، العنوان، أو رقم الهاتف...',
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
                    fillColor: isDark ? const Color(0xFF131D31) : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? AppConstants.cardBorderDark : AppConstants.cardBorderLight,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? AppConstants.cardBorderDark : AppConstants.cardBorderLight,
                      ),
                    ),
                  ),
                ),
              ),

              if (isDesktop) ...[
                const SizedBox(width: 16),
                // View Mode Switcher
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF131D31) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildViewModeButton(
                        icon: Icons.table_rows_rounded,
                        label: 'جدول',
                        mode: MakhdomeenViewMode.table,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 4),
                      _buildViewModeButton(
                        icon: Icons.grid_view_rounded,
                        label: 'بطاقات',
                        mode: MakhdomeenViewMode.grid,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Filters Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'الكل (${formatters.formatNumber(totalCount)})',
                  key: 'all',
                  isDark: isDark,
                ),
                _buildFilterChip(
                  label: 'في انتظار الافتقاد (${formatters.formatNumber(unvisitedCount)})',
                  key: 'unvisited',
                  isDark: isDark,
                  badgeColor: const Color(0xFFF59E0B),
                ),
                _buildFilterChip(
                  label: 'تم افتقادهم (${formatters.formatNumber(visitedCount)})',
                  key: 'visited',
                  isDark: isDark,
                  badgeColor: const Color(0xFF10B981),
                ),
                if (brethrenCount > 0)
                  _buildFilterChip(
                    label: 'إخوة الرب (${formatters.formatNumber(brethrenCount)})',
                    key: 'brethren',
                    isDark: isDark,
                    badgeColor: AppConstants.royalGold,
                  ),
                if (atRiskCount > 0)
                  _buildFilterChip(
                    label: 'غياب متكرر (${formatters.formatNumber(atRiskCount)})',
                    key: 'at_risk',
                    isDark: isDark,
                    badgeColor: Colors.redAccent,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeButton({
    required IconData icon,
    required String label,
    required MakhdomeenViewMode mode,
    required bool isDark,
  }) {
    final isSelected = _viewMode == mode;
    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppConstants.primaryLight : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? (isDark ? Colors.white : AppConstants.primaryLight)
                  : AppConstants.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : AppConstants.primaryLight)
                    : AppConstants.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String key,
    required bool isDark,
    Color? badgeColor,
  }) {
    final isSelected = _activeFilter == key;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: InkWell(
        onTap: () => setState(() => _activeFilter = key),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? (badgeColor ?? AppConstants.primaryNavy)
                : (isDark ? const Color(0xFF131D31) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? (badgeColor ?? AppConstants.primaryNavy)
                  : (isDark ? AppConstants.cardBorderDark : AppConstants.cardBorderLight),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : AppConstants.textDark),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // DESKTOP DATA TABLE
  // ==========================================
  Widget _buildDataTable(
    BuildContext context,
    List<MakhdomModel> list,
    Map<String, AtRiskStudentInfo> atRiskMap,
    AppFormatters formatters,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return WebCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2.6), // Name & photo
            1: FlexColumnWidth(1.6), // Grade & Area
            2: FlexColumnWidth(2.2), // Phone & WhatsApp
            3: FlexColumnWidth(1.4), // Visit Status
            4: FlexColumnWidth(1.8), // Last Visit
            5: FlexColumnWidth(2.4), // Actions
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            // Table Header
            TableRow(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131D31) : const Color(0xFFF8FAFC),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppConstants.cardBorderDark : AppConstants.cardBorderLight,
                  ),
                ),
              ),
              children: [
                _buildTableHeaderCell('المخدوم'),
                _buildTableHeaderCell('السنة والمنطقة'),
                _buildTableHeaderCell('التواصل'),
                _buildTableHeaderCell('حالة الافتقاد'),
                _buildTableHeaderCell('آخر افتقاد'),
                _buildTableHeaderCell('الإجراءات'),
              ],
            ),

            // Table Rows
            ...list.asMap().entries.map((entry) {
              final index = entry.key;
              final m = entry.value;
              final atRisk = atRiskMap[m.id];
              final isEven = index % 2 == 0;

              return TableRow(
                decoration: BoxDecoration(
                  color: isEven
                      ? Colors.transparent
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.02)
                          : const Color(0xFFFBFDFF)),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? AppConstants.cardBorderDark.withValues(alpha: 0.5)
                          : AppConstants.cardBorderLight.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                children: [
                  // 1. Makhdom Identity & Avatar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        _buildAvatar(m),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      m.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (m.isBrethrenOfLord) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppConstants.royalGold.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'إخوة رب',
                                        style: TextStyle(
                                          color: AppConstants.royalGold,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (atRisk != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, size: 13, color: Colors.redAccent),
                                    const SizedBox(width: 4),
                                    Text(
                                      'غائب ${formatters.formatNumber(atRisk.consecutiveAbsences)} مرات متتالية',
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Grade & Area
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DomainLabels(Localizations.localeOf(context)).gradeName(m.grade),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        if (m.area.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            m.area,
                            style: const TextStyle(fontSize: 11, color: AppConstants.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 3. Contact & Phone
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: SelectableText(
                            m.phone,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          tooltip: 'نسخ الرقم',
                          onPressed: () => _copyToClipboard(context, m.phone, 'رقم الهاتف'),
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: const Icon(Icons.call_rounded, size: 18, color: Colors.blueAccent),
                          tooltip: 'اتصال',
                          onPressed: () => _makeCall(m.phone),
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF25D366)),
                          tooltip: 'واتساب',
                          onPressed: () => _openWhatsApp(m.phone),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),

                  // 4. Visit Status Badge
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: m.visitCount > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                                const SizedBox(width: 6),
                                Text(
                                  'تم الافتقاد (${formatters.formatNumber(m.visitCount)})',
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.access_time_rounded, size: 14, color: Color(0xFFF59E0B)),
                                SizedBox(width: 6),
                                Text(
                                  'لم يُفتقد بعد',
                                  style: TextStyle(
                                    color: Color(0xFFF59E0B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),

                  // 5. Last Visit Date
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: m.lastVisitDate != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formatters.formatDate(m.lastVisitDate!),
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                              if (m.lastVisitNotes != null && m.lastVisitNotes!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  m.lastVisitNotes!,
                                  style: const TextStyle(fontSize: 11, color: AppConstants.textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          )
                        : const Text(
                            '—',
                            style: TextStyle(color: AppConstants.textMuted),
                          ),
                  ),

                  // 6. Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: () => RecordVisitSheet.show(context, makhdom: m),
                          icon: const Icon(Icons.add_task_rounded, size: 15),
                          label: const Text('سجل افتقاد'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppConstants.royalGold,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.person_outline_rounded, size: 17),
                          tooltip: 'سجل وتفاصيل المخدوم',
                          onPressed: () => context.push(AppRoutes.makhdomHistory(m.id)),
                          visualDensity: VisualDensity.compact,
                        ),
                        if (m.homeLocationUrl != null && m.homeLocationUrl!.isNotEmpty)
                          IconButton.filledTonal(
                            icon: const Icon(Icons.location_on_outlined, size: 17, color: Colors.redAccent),
                            tooltip: 'موقع المنزل',
                            onPressed: () => _openLocation(m.homeLocationUrl),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          color: AppConstants.textMuted,
        ),
      ),
    );
  }

  // ==========================================
  // RESPONSIVE GRID CARDS (MOBILE WEB / TABLET)
  // ==========================================
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
              child: _buildMakhdomCardItem(context, m, atRisk, formatters),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMakhdomCardItem(
    BuildContext context,
    MakhdomModel m,
    AtRiskStudentInfo? atRisk,
    AppFormatters formatters,
  ) {
    return WebCard(
      padding: const EdgeInsets.all(18),
      onTap: () => context.push(AppRoutes.makhdomHistory(m.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Avatar + Full Name + Badges
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(m, radius: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            m.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (m.isBrethrenOfLord) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppConstants.royalGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'إخوة رب',
                              style: TextStyle(
                                color: AppConstants.royalGold,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DomainLabels(Localizations.localeOf(context)).gradeName(m.grade)}${m.area.isNotEmpty ? ' • ${m.area}' : ''}',
                      style: const TextStyle(fontSize: 12, color: AppConstants.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Repeated absence alert if any
          if (atRisk != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.redAccent),
                  const SizedBox(width: 6),
                  Text(
                    'غائب ${formatters.formatNumber(atRisk.consecutiveAbsences)} مرات متتالية (افتقاد عاجل)',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Visit Status & Last visit
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('حالة الافتقاد', style: TextStyle(fontSize: 11, color: AppConstants.textMuted)),
                    const SizedBox(height: 3),
                    Text(
                      m.visitCount > 0
                          ? 'تم (${formatters.formatNumber(m.visitCount)} زيارات)'
                          : 'في الانتظار',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: m.visitCount > 0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('آخر افتقاد', style: TextStyle(fontSize: 11, color: AppConstants.textMuted)),
                    const SizedBox(height: 3),
                    Text(
                      m.lastVisitDate != null ? formatters.formatDate(m.lastVisitDate!) : 'لم يُسجل',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Quick Action Buttons
          Row(
            children: [
              // Contact buttons
              IconButton.filledTonal(
                icon: const Icon(Icons.call_rounded, size: 18, color: Colors.blueAccent),
                tooltip: 'اتصال',
                onPressed: () => _makeCall(m.phone),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF25D366)),
                tooltip: 'واتساب',
                onPressed: () => _openWhatsApp(m.phone),
                visualDensity: VisualDensity.compact,
              ),
              if (m.homeLocationUrl != null && m.homeLocationUrl!.isNotEmpty) ...[
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  icon: const Icon(Icons.location_on_outlined, size: 18, color: Colors.redAccent),
                  tooltip: 'موقع المنزل',
                  onPressed: () => _openLocation(m.homeLocationUrl),
                  visualDensity: VisualDensity.compact,
                ),
              ],
              const Spacer(),
              // Log Visit Button
              FilledButton.icon(
                onPressed: () => RecordVisitSheet.show(context, makhdom: m),
                icon: const Icon(Icons.add_task_rounded, size: 16),
                label: const Text('سجل افتقاد'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppConstants.royalGold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HELPERS & EMPTY STATES
  // ==========================================
  Widget _buildAvatar(MakhdomModel m, {double radius = 20}) {
    final hasPhoto = m.photoUrl != null && m.photoUrl!.isNotEmpty;
    final initials = m.fullName.trim().isNotEmpty
        ? m.fullName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : '?';

    if (hasPhoto) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: CachedNetworkImageProvider(m.photoUrl!),
      );
    }

    final avatarColor = ColorGenerator.getColorForId(m.fullName);
    return CircleAvatar(
      radius: radius,
      backgroundColor: avatarColor.withValues(alpha: 0.15),
      child: Text(
        initials,
        style: TextStyle(
          color: avatarColor,
          fontWeight: FontWeight.w900,
          fontSize: radius * 0.7,
        ),
      ),
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
                isSearch ? Icons.search_off_rounded : Icons.people_outline_rounded,
                size: 48,
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isSearch ? 'لا توجد نتائج مطابقة لبحثك' : 'لا يوجد مخدومين مسندين إليك حالياً',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(height: 6),
            Text(
              isSearch
                  ? 'جرب البحث باسم آخر أو تغيير الفلتر المحدد'
                  : 'سيقوم أمين الخدمة أو المشرف بإسناد مخدومين لمتابعتهم قريباً',
              style: const TextStyle(fontSize: 13, color: AppConstants.textMuted),
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
