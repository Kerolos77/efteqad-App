import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/domain_labels.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/services/attendance_analytics_service.dart';
import '../../../../core/utils/color_generator.dart';
import '../../../../core/widgets/web/web_widgets.dart';
import '../../../common/widgets/record_visit_sheet.dart';
import '../web/my_analytics_web_screen.dart' show AnalyticsListViewMode;

class WebAnalyticsRosterSection extends StatelessWidget {
  final List<MakhdomModel> filteredList;
  final BehavioralSegmentation segmentation;
  final Map<String, AtRiskStudentInfo> atRiskMap;
  final Map<String, double?> individualRates;
  final AppFormatters formatters;
  final bool isDark;
  final bool isDesktop;
  final AnalyticsListViewMode viewMode;
  final ValueChanged<AnalyticsListViewMode> onViewModeChanged;
  final String behaviorFilter;
  final ValueChanged<String> onFilterChanged;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final void Function(String phone) onMakeCall;
  final void Function(String phone) onOpenWhatsApp;
  final VoidCallback onVisitRecorded;

  const WebAnalyticsRosterSection({
    super.key,
    required this.filteredList,
    required this.segmentation,
    required this.atRiskMap,
    required this.individualRates,
    required this.formatters,
    required this.isDark,
    required this.isDesktop,
    required this.viewMode,
    required this.onViewModeChanged,
    required this.behaviorFilter,
    required this.onFilterChanged,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onMakeCall,
    required this.onOpenWhatsApp,
    required this.onVisitRecorded,
  });

  @override
  Widget build(BuildContext context) {
    return WebCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                      color: AppColors.textMuted,
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
                  selected: {viewMode},
                  onSelectionChanged: (set) => onViewModeChanged(set.first),
                ),
            ],
          ),
          const SizedBox(height: 18),

          // Search Bar
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'ابحث عن مخدوم بالاسم، الهاتف، المنطقة...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: onClearSearch,
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark
                      ? AppColors.cardBorderDark
                      : AppColors.cardBorderLight,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Behavioral Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  key: 'all',
                  label:
                      'الكل (${formatters.formatNumber(segmentation.consistent.length + segmentation.irregular.length + segmentation.atRisk.length + segmentation.insufficient.length)})',
                  color: AppColors.primaryLight,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  key: 'consistent',
                  label:
                      'منتظم (${formatters.formatNumber(segmentation.consistent.length)})',
                  color: AppColors.successColor,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  key: 'irregular',
                  label:
                      'متذبذب (${formatters.formatNumber(segmentation.irregular.length)})',
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  key: 'atRisk',
                  label:
                      'معرض للانقطاع (${formatters.formatNumber(segmentation.atRisk.length)})',
                  color: AppColors.errorColor,
                ),
                if (segmentation.insufficient.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    key: 'insufficient',
                    label:
                        'غير مكتمل (${formatters.formatNumber(segmentation.insufficient.length)})',
                    color: Colors.blueGrey,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),

          if (filteredList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 40,
                    color: isDark ? Colors.white24 : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'لا يوجد مخدومين يطابقون شروط البحث أو الفلتر',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            )
          else if (isDesktop && viewMode == AnalyticsListViewMode.table)
            _buildDataTable(context)
          else
            _buildGridCards(context),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String key,
    required String label,
    required Color color,
  }) {
    final selected = behaviorFilter == key;
    return InkWell(
      onTap: () => onFilterChanged(key),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: isDark ? 0.25 : 0.12)
              : (isDark ? const Color(0xFF131D31) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.6)
                : (isDark
                    ? AppColors.cardBorderDark
                    : AppColors.cardBorderLight),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected
                ? (isDark ? Colors.white : color)
                : (isDark ? Colors.white70 : AppColors.textDark),
          ),
        ),
      ),
    );
  }

  Widget _buildDataTable(BuildContext context) {
    return Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      columnWidths: const {
        0: FixedColumnWidth(250),
        1: FixedColumnWidth(140),
        2: FixedColumnWidth(140),
        3: FixedColumnWidth(150),
        4: FixedColumnWidth(220),
      },
      border: TableBorder(
        horizontalInside: BorderSide(
          color: isDark
              ? AppColors.cardBorderDark.withValues(alpha: 0.5)
              : AppColors.cardBorderLight.withValues(alpha: 0.6),
        ),
      ),
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131D31) : const Color(0xFFF8FAFC),
          ),
          children: const [
            _TableHeaderCell('المخدوم'),
            _TableHeaderCell('الفرقة والمنطقة'),
            _TableHeaderCell('نسبة الحضور'),
            _TableHeaderCell('تصنيف السلوك'),
            _TableHeaderCell('الإجراءات'),
          ],
        ),
        ...filteredList.map((m) {
          final rate = individualRates[m.id];
          final atRisk = atRiskMap[m.id];
          return TableRow(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          ColorGenerator.getColorForId(m.fullName)
                              .withValues(alpha: 0.15),
                      child: Text(
                        m.fullName.isNotEmpty ? m.fullName[0] : '?',
                        style: TextStyle(
                          color: ColorGenerator.getColorForId(m.fullName),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        m.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DomainLabels(Localizations.localeOf(context))
                          .gradeName(m.grade),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (m.area.isNotEmpty)
                      Text(
                        m.area,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  rate == null
                      ? '—'
                      : '${formatters.formatNumber(rate, decimalDigits: 0)}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: rate == null
                        ? Colors.blueGrey
                        : (rate >= 75
                            ? AppColors.successColor
                            : (rate >= 40
                                ? Colors.orange
                                : AppColors.errorColor)),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _buildSegmentBadge(context, m, atRisk),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (m.phone.isNotEmpty) ...[
                      IconButton.outlined(
                        tooltip: 'اتصال',
                        onPressed: () => onMakeCall(m.phone),
                        icon: const Icon(
                          Icons.phone_rounded,
                          size: 15,
                          color: AppColors.successColor,
                        ),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(30, 30),
                          padding: const EdgeInsets.all(6),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton.outlined(
                        tooltip: 'واتساب',
                        onPressed: () => onOpenWhatsApp(m.phone),
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 15,
                          color: Color(0xFF25D366),
                        ),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(30, 30),
                          padding: const EdgeInsets.all(6),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    ElevatedButton(
                      onPressed: () async {
                        await RecordVisitSheet.show(context, makhdom: m);
                        onVisitRecorded();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: const Size(0, 30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'افتقاد',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildGridCards(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = isDesktop
            ? (constraints.maxWidth - 28) / 3
            : constraints.maxWidth >= 600
                ? (constraints.maxWidth - 14) / 2
                : constraints.maxWidth;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: filteredList.map((m) {
            final rate = individualRates[m.id];
            final atRisk = atRiskMap[m.id];
            return SizedBox(
              width: cardWidth,
              child: WebCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              ColorGenerator.getColorForId(m.fullName)
                                  .withValues(alpha: 0.15),
                          child: Text(
                            m.fullName.isNotEmpty ? m.fullName[0] : '?',
                            style: TextStyle(
                              color: ColorGenerator.getColorForId(m.fullName),
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
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
                              Text(
                                DomainLabels(Localizations.localeOf(context))
                                    .gradeName(m.grade),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (rate != null)
                          Text(
                            '${formatters.formatNumber(rate, decimalDigits: 0)}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: rate >= 75
                                  ? AppColors.successColor
                                  : (rate >= 40
                                      ? Colors.orange
                                      : AppColors.errorColor),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSegmentBadge(context, m, atRisk),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (m.phone.isNotEmpty) ...[
                          IconButton.outlined(
                            tooltip: 'اتصال',
                            onPressed: () => onMakeCall(m.phone),
                            icon: const Icon(
                              Icons.phone_rounded,
                              size: 15,
                              color: AppColors.successColor,
                            ),
                            style: IconButton.styleFrom(
                              minimumSize: const Size(28, 28),
                              padding: const EdgeInsets.all(5),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton.outlined(
                            tooltip: 'واتساب',
                            onPressed: () => onOpenWhatsApp(m.phone),
                            icon: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 15,
                              color: Color(0xFF25D366),
                            ),
                            style: IconButton.styleFrom(
                              minimumSize: const Size(28, 28),
                              padding: const EdgeInsets.all(5),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        ElevatedButton(
                          onPressed: () async {
                            await RecordVisitSheet.show(context, makhdom: m);
                            onVisitRecorded();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryLight,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            minimumSize: const Size(0, 28),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'افتقاد',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSegmentBadge(
    BuildContext context,
    MakhdomModel m,
    AtRiskStudentInfo? atRisk,
  ) {
    if (atRisk != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.errorColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'معرض للانقطاع (${atRisk.consecutiveAbsences})',
          style: const TextStyle(
            color: AppColors.errorColor,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    if (segmentation.consistent.any((s) => s.id == m.id)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.successColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          context.tr.segmentConsistent,
          style: const TextStyle(
            color: AppColors.successColor,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    if (segmentation.irregular.any((s) => s.id == m.id)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          context.tr.segmentIrregular,
          style: const TextStyle(
            color: Colors.orange,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'غير مكتمل',
        style: TextStyle(
          color: Colors.blueGrey,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String text;
  const _TableHeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
