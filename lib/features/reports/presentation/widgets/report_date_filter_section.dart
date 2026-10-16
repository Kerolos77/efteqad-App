import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../models/report_filter_data.dart';

class ReportDateFilterSection extends StatelessWidget {
  final ReportFilterData filters;
  final bool isDark;
  final Color primaryColor;
  final ValueChanged<ReportFilterData> onFiltersChanged;

  const ReportDateFilterSection({
    super.key,
    required this.filters,
    required this.isDark,
    required this.primaryColor,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الفترة الزمنية:',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: QuickDateFilter.values.map((q) {
            final isSelected = filters.quickDateFilter == q;
            return ChoiceChip(
              label: Text(q.label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  if (q == QuickDateFilter.custom) {
                    _pickCustomRange(context);
                  } else {
                    onFiltersChanged(
                      filters.copyWith(
                        quickDateFilter: q,
                        dateRange: q.toRange(),
                      ),
                    );
                  }
                }
              },
              labelStyle: TextStyle(
                fontSize: 11.5.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? (isDark ? Colors.black87 : Colors.white)
                    : (isDark ? Colors.white70 : Colors.grey.shade800),
              ),
              selectedColor: primaryColor,
              backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14.sp,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
              SizedBox(width: 6.w),
              Text(
                'من ${dateFormat.format(filters.dateRange.start)} إلى ${dateFormat.format(filters.dateRange.end)}',
                style: TextStyle(
                  fontSize: 11.5.sp,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: filters.dateRange,
    );
    if (picked != null) {
      onFiltersChanged(
        filters.copyWith(
          quickDateFilter: QuickDateFilter.custom,
          dateRange: picked,
        ),
      );
    }
  }
}
