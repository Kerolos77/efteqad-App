import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/web/web_widgets.dart';

class WebTasksControlsBar extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final String typeFilter;
  final String statusFilter;
  final int totalCount;
  final int pendingCount;
  final int completedCount;
  final int overdueCount;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onTypeFilterChanged;
  final ValueChanged<String> onStatusFilterChanged;
  final bool isDark;

  const WebTasksControlsBar({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.typeFilter,
    required this.statusFilter,
    required this.totalCount,
    required this.pendingCount,
    required this.completedCount,
    required this.overdueCount,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onTypeFilterChanged,
    required this.onStatusFilterChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return WebCard(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
                    hintText: 'ابحث في العنوان، الوصف، أو اسم المشرف...',
                    prefixIcon: Icon(Icons.search_rounded, size: 20.sp),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 18.sp),
                            onPressed: onClearSearch,
                          )
                        : null,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 12.h,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              DropdownButtonHideUnderline(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: DropdownButton<String>(
                    value: typeFilter,
                    icon: Icon(Icons.filter_list_rounded, size: 18.sp),
                    isDense: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('جميع الأنواع'),
                      ),
                      DropdownMenuItem(
                        value: 'attendance',
                        child: Text('حضور وغياب'),
                      ),
                      DropdownMenuItem(
                        value: 'visitation',
                        child: Text('افتقاد وزيارة'),
                      ),
                      DropdownMenuItem(
                        value: 'general',
                        child: Text('عام'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) onTypeFilterChanged(val);
                    },
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'الكل ($totalCount)'),
                SizedBox(width: 8.w),
                _buildFilterChip('pending', 'قيد التنفيذ ($pendingCount)'),
                SizedBox(width: 8.w),
                _buildFilterChip('completed', 'مكتملة ($completedCount)'),
                SizedBox(width: 8.w),
                _buildFilterChip(
                  'overdue',
                  'متأخرة ($overdueCount)',
                  isAlert: overdueCount > 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, {bool isAlert = false}) {
    final isSelected = statusFilter == key;
    Color activeColor = AppColors.primaryLight;
    if (isAlert) activeColor = AppColors.errorColor;

    return InkWell(
      onTap: () => onStatusFilterChanged(key),
      borderRadius: BorderRadius.circular(20.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20.r),
          border: isAlert && !isSelected
              ? Border.all(
                  color: AppColors.errorColor.withValues(alpha: 0.5),
                )
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isAlert
                    ? AppColors.errorColor
                    : (isDark ? Colors.white70 : AppColors.textDark)),
          ),
        ),
      ),
    );
  }
}
