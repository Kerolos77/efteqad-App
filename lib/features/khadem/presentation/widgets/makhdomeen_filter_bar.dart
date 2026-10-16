import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/localization/app_localizations.dart';

class MakhdomeenFilterBar extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String activeFilter; // 'all', 'unvisited', 'visited', 'brethren'
  final ValueChanged<String> onFilterChanged;
  final int totalCount;
  final int unvisitedCount;
  final int visitedCount;
  final int brethrenCount;
  final bool isDark;

  const MakhdomeenFilterBar({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.totalCount,
    required this.unvisitedCount,
    required this.visitedCount,
    required this.brethrenCount,
    required this.isDark,
  });

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    String key,
  ) {
    final isSelected = activeFilter == key;

    return Padding(
      padding: EdgeInsetsDirectional.only(end: 8.w),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected
              ? Colors.white
              : (isDark ? Colors.white70 : AppColors.textDark),
        ),
        backgroundColor: isDark ? const Color(0xFF131D31) : const Color(0xFFF1F5F9),
        selectedColor: AppColors.primaryLight,
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: isSelected
              ? AppColors.primaryLight
              : (isDark ? Colors.white12 : Colors.black12),
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        onSelected: (_) => onFilterChanged(key),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatters = AppFormatters(Localizations.localeOf(context));

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: TextField(
            onChanged: onSearchChanged,
            style: TextStyle(fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: context.tr.searchMyMakhdomeen,
              hintStyle: TextStyle(fontSize: 13.sp),
              prefixIcon: Icon(Icons.search, size: 20.sp),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
            ),
          ),
        ),
        SizedBox(height: 10.h),
        SizedBox(
          height: 40.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            children: [
              _buildFilterChip(
                context,
                '${context.tr.all} (${formatters.formatNumber(totalCount)})',
                'all',
              ),
              _buildFilterChip(
                context,
                '${context.tr.filterUnvisited} (${formatters.formatNumber(unvisitedCount)})',
                'unvisited',
              ),
              _buildFilterChip(
                context,
                '${context.tr.filterVisited} (${formatters.formatNumber(visitedCount)})',
                'visited',
              ),
              _buildFilterChip(
                context,
                '${context.tr.filterBrethren} (${formatters.formatNumber(brethrenCount)})',
                'brethren',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
