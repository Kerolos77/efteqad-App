import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/localization/app_localizations.dart';

class TasksFilterBar extends StatelessWidget {
  final String currentFilter;
  final int totalCount;
  final int pendingCount;
  final int completedCount;
  final bool canCreateTasks;
  final bool hasKhodam;
  final ValueChanged<String> onFilterSelected;
  final VoidCallback onAddTask;
  final bool isDark;

  const TasksFilterBar({
    super.key,
    required this.currentFilter,
    required this.totalCount,
    required this.pendingCount,
    required this.completedCount,
    required this.canCreateTasks,
    required this.hasKhodam,
    required this.onFilterSelected,
    required this.onAddTask,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final formatters = AppFormatters(Localizations.localeOf(context));

    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(16.w, 12.h, 16.w, 12.h),
      color: isDark ? AppColors.surfaceDark : Colors.white,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterChip(
                    filterKey: 'all',
                    label:
                        '${context.tr.all} (${formatters.formatNumber(totalCount)})',
                  ),
                  SizedBox(width: 8.w),
                  _buildFilterChip(
                    filterKey: 'pending',
                    label:
                        '${context.tr.pendingTasksSection} (${formatters.formatNumber(pendingCount)})',
                  ),
                  SizedBox(width: 8.w),
                  _buildFilterChip(
                    filterKey: 'completed',
                    label:
                        '${context.tr.completedTasksSection} (${formatters.formatNumber(completedCount)})',
                  ),
                ],
              ),
            ),
          ),
          if (canCreateTasks && hasKhodam) ...[
            SizedBox(width: 8.w),
            ElevatedButton.icon(
              onPressed: onAddTask,
              icon: Icon(Icons.add, size: 16.sp),
              label: Text(
                context.tr.addTaskTitle,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 8.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String filterKey,
    required String label,
  }) {
    final isSelected = currentFilter == filterKey;
    return InkWell(
      onTap: () => onFilterSelected(filterKey),
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryLight
              : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : AppColors.textDark),
          ),
        ),
      ),
    );
  }
}
