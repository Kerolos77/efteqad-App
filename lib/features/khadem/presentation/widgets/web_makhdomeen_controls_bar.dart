import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/widgets/web/web_widgets.dart';
import '../web/my_makhdomeen_web_screen.dart' show MakhdomeenViewMode;

class WebMakhdomeenControlsBar extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final String activeFilter;
  final ValueChanged<String> onFilterChanged;
  final MakhdomeenViewMode viewMode;
  final ValueChanged<MakhdomeenViewMode> onViewModeChanged;
  final int totalCount;
  final int visitedCount;
  final int unvisitedCount;
  final int brethrenCount;
  final int atRiskCount;
  final AppFormatters formatters;
  final bool isDesktop;

  const WebMakhdomeenControlsBar({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.viewMode,
    required this.onViewModeChanged,
    required this.totalCount,
    required this.visitedCount,
    required this.unvisitedCount,
    required this.brethrenCount,
    required this.atRiskCount,
    required this.formatters,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return WebCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'ابحث بالاسم، المنطقة، العنوان، أو رقم الهاتف...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: onClearSearch,
                          )
                        : null,
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF131D31)
                        : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.cardBorderDark
                            : AppColors.cardBorderLight,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.cardBorderDark
                            : AppColors.cardBorderLight,
                      ),
                    ),
                  ),
                ),
              ),
              if (isDesktop) ...[
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF131D31)
                        : const Color(0xFFF1F5F9),
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'الكل (${formatters.formatNumber(totalCount)})',
                  filterKey: 'all',
                  isDark: isDark,
                ),
                _buildFilterChip(
                  label:
                      'في انتظار الافتقاد (${formatters.formatNumber(unvisitedCount)})',
                  filterKey: 'unvisited',
                  isDark: isDark,
                  badgeColor: const Color(0xFFF59E0B),
                ),
                _buildFilterChip(
                  label:
                      'تم افتقادهم (${formatters.formatNumber(visitedCount)})',
                  filterKey: 'visited',
                  isDark: isDark,
                  badgeColor: const Color(0xFF10B981),
                ),
                if (brethrenCount > 0)
                  _buildFilterChip(
                    label:
                        'إخوة الرب (${formatters.formatNumber(brethrenCount)})',
                    filterKey: 'brethren',
                    isDark: isDark,
                    badgeColor: AppColors.royalGold,
                  ),
                if (atRiskCount > 0)
                  _buildFilterChip(
                    label:
                        'غياب متكرر (${formatters.formatNumber(atRiskCount)})',
                    filterKey: 'at_risk',
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
    final isSelected = viewMode == mode;
    return InkWell(
      onTap: () => onViewModeChanged(mode),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.surfaceDark : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? AppColors.primaryLight
                  : (isDark ? Colors.white60 : Colors.grey.shade600),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? (isDark ? Colors.white : AppColors.textDark)
                    : (isDark ? Colors.white60 : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String filterKey,
    required bool isDark,
    Color? badgeColor,
  }) {
    final isSelected = activeFilter == filterKey;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: InkWell(
        onTap: () => onFilterChanged(filterKey),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryLight.withValues(alpha: isDark ? 0.25 : 0.12)
                : (isDark ? const Color(0xFF131D31) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryLight.withValues(alpha: 0.6)
                  : (isDark
                      ? AppColors.cardBorderDark
                      : AppColors.cardBorderLight),
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badgeColor != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? (isDark ? Colors.white : AppColors.primaryLight)
                      : (isDark ? Colors.white70 : AppColors.textDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
