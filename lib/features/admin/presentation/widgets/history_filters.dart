import 'package:efteqad/core/localization/app_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';

enum HistoryFilterType {
  all,
  visitsOnly,
  attendanceOnly,
  fruitfulOnly,
  absencesOnly,
}

enum HistoryDateRange { allTime, last30Days, last90Days, custom }

class HistoryFilters extends StatelessWidget {
  final HistoryFilterType selectedFilter;
  final ValueChanged<HistoryFilterType> onFilterChanged;
  final HistoryDateRange selectedDateRange;
  final ValueChanged<HistoryDateRange> onDateRangeChanged;
  final DateTimeRange? customDateRange;
  final VoidCallback onPickCustomDateRange;
  final Map<HistoryFilterType, int> counts;
  final bool isDark;

  const HistoryFilters({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.selectedDateRange,
    required this.onDateRangeChanged,
    this.customDateRange,
    required this.onPickCustomDateRange,
    required this.counts,
    required this.isDark,
  });

  String _getFilterLabel(BuildContext context, HistoryFilterType type) {
    switch (type) {
      case HistoryFilterType.all:
        return context.tr.filterAllEvents;
      case HistoryFilterType.visitsOnly:
        return context.tr.filterVisitsOnly;
      case HistoryFilterType.attendanceOnly:
        return context.tr.filterAttendanceOnly;
      case HistoryFilterType.fruitfulOnly:
        return context.tr.filterFruitfulOnly;
      case HistoryFilterType.absencesOnly:
        return context.tr.filterAbsencesOnly;
    }
  }

  String _getDateRangeLabel(BuildContext context, HistoryDateRange range) {
    switch (range) {
      case HistoryDateRange.allTime:
        return context.tr.rangeAllTime;
      case HistoryDateRange.last30Days:
        return context.tr.rangeLast30Days;
      case HistoryDateRange.last90Days:
        return context.tr.rangeLast90Days;
      case HistoryDateRange.custom:
        return context.tr.rangeCustom;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDark
              ? AppColors.cardBorderDark
              : AppColors.cardBorderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. فلاتر نوع الحدث (أزرار أفقية قابلة للتمرير)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: HistoryFilterType.values.map((type) {
                final isSelected = selectedFilter == type;
                final count = counts[type] ?? 0;
                final label = _getFilterLabel(context, type);

                return Padding(
                  padding: EdgeInsetsDirectional.only(start: 6.w),
                  child: FilterChip(
                    label: Text(
                      count > 0
                          ? '$label (${AppFormatters(Localizations.localeOf(context)).formatNumber(count)})'
                          : label,
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        fontWeight: isSelected
                            ? FontWeight.w900
                            : FontWeight.w700,
                        color: isSelected
                            ? Colors.black
                            : (isDark ? Colors.white70 : AppColors.textDark),
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) => onFilterChanged(type),
                    selectedColor: AppColors.sacredGold,
                    backgroundColor: isDark
                        ? Colors.white10
                        : const Color(0xFFF1F5F9),
                    checkmarkColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.sacredGold
                            : (isDark ? Colors.white12 : Colors.grey.shade300),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 8.h),

          // 2. فلاتر النطاق الزمني
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: HistoryDateRange.values.map((range) {
                final isSelected = selectedDateRange == range;
                final label = _getDateRangeLabel(context, range);

                return Padding(
                  padding: EdgeInsetsDirectional.only(start: 6.w),
                  child: ChoiceChip(
                    label: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                  ? Colors.white60
                                  : AppColors.textMuted),
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      if (range == HistoryDateRange.custom) {
                        onPickCustomDateRange();
                      } else {
                        onDateRangeChanged(range);
                      }
                    },
                    selectedColor: AppColors.primaryLight,
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primaryLight
                            : (isDark ? Colors.white12 : Colors.grey.shade300),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
