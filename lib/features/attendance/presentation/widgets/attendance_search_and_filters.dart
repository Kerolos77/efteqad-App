import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';

class AttendanceSearchAndFilters extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final Map<String, String> availableClasses;
  final Map<String, int> classCounts;
  final String? selectedClassFilter;
  final ValueChanged<String?> onClassFilterSelected;
  final String statusFilter;
  final ValueChanged<String> onStatusFilterSelected;
  final int totalCount;
  final int absentCount;
  final int attendedCount;
  final int excusedCount;
  final bool isDark;

  const AttendanceSearchAndFilters({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.availableClasses,
    required this.classCounts,
    required this.selectedClassFilter,
    required this.onClassFilterSelected,
    required this.statusFilter,
    required this.onStatusFilterSelected,
    required this.totalCount,
    required this.absentCount,
    required this.attendedCount,
    required this.excusedCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // حقل البحث
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(16.w, 8.h, 16.w, 4.h),
          child: TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: context.tr.messageSearchByName,
              prefixIcon: Icon(Icons.search_rounded, size: 20.sp),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: 18.sp),
                      onPressed: onClearSearch,
                    )
                  : null,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 10.h,
              ),
            ),
          ),
        ),

        // شرائح فلترة الفصول (إن وُجدت)
        if (availableClasses.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsetsDirectional.fromSTEB(16.w, 0, 16.w, 6.h),
            child: Row(
              children: [
                _buildClassFilterChip(
                  key: null,
                  label: 'كل الفصول',
                ),
                ...availableClasses.entries.map((entry) {
                  final count = classCounts[entry.key] ?? 0;
                  return Padding(
                    padding: EdgeInsetsDirectional.only(start: 6.w),
                    child: _buildClassFilterChip(
                      key: entry.key,
                      label: '${entry.value} ($count)',
                    ),
                  );
                }),
              ],
            ),
          ),

        // شرائح فلترة الحالات
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsetsDirectional.fromSTEB(16.w, 2.h, 16.w, 6.h),
          child: Row(
            children: [
              _buildFilterChip(
                key: 'all',
                label: 'الكل ($totalCount)',
              ),
              SizedBox(width: 6.w),
              _buildFilterChip(
                key: 'absent',
                label: 'غائب ($absentCount)',
              ),
              SizedBox(width: 6.w),
              _buildFilterChip(
                key: 'present',
                label: 'حاضر ($attendedCount)',
              ),
              SizedBox(width: 6.w),
              _buildFilterChip(
                key: 'excused',
                label: 'بعذر ($excusedCount)',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClassFilterChip({
    required String? key,
    required String label,
  }) {
    final selected = selectedClassFilter == key;
    return InkWell(
      onTap: () => onClassFilterSelected(key),
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.sacredGold
              : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10.r),
          border: selected
              ? null
              : Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.diversity_3_rounded,
              size: 13.sp,
              color: selected
                  ? Colors.black87
                  : (isDark ? Colors.white60 : AppColors.textMuted),
            ),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5.sp,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected
                    ? Colors.black87
                    : (isDark ? Colors.white70 : AppColors.textDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String key,
    required String label,
  }) {
    final selected = statusFilter == key;
    return InkWell(
      onTap: () => onStatusFilterSelected(key),
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryLight
              : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5.sp,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected
                ? Colors.white
                : (isDark ? Colors.white70 : AppColors.textDark),
          ),
        ),
      ),
    );
  }
}
