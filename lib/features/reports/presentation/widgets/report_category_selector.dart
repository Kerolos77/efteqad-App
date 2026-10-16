import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../models/report_type.dart';

class ReportCategorySelector extends StatelessWidget {
  final ReportCategory? selectedCategory;
  final bool isDark;
  final ValueChanged<ReportCategory?> onCategorySelected;

  const ReportCategorySelector({
    super.key,
    required this.selectedCategory,
    required this.isDark,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('جميع الأقسام'),
            selected: selectedCategory == null,
            onSelected: (val) {
              if (val) onCategorySelected(null);
            },
            selectedColor: isDark ? AppColors.sacredGold : AppColors.primaryLight,
            labelStyle: TextStyle(
              fontSize: 12.sp,
              fontWeight:
                  selectedCategory == null ? FontWeight.bold : FontWeight.normal,
              color: selectedCategory == null
                  ? (isDark ? Colors.black87 : Colors.white)
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
          SizedBox(width: 6.w),
          ...ReportCategory.values.map((cat) {
            final isSelected = selectedCategory == cat;
            return Padding(
              padding: EdgeInsets.only(left: 6.w),
              child: ChoiceChip(
                avatar: Icon(cat.icon, size: 16.sp),
                label: Text(cat.title),
                selected: isSelected,
                onSelected: (val) {
                  onCategorySelected(val ? cat : null);
                },
                selectedColor:
                    isDark ? AppColors.sacredGold : AppColors.primaryLight,
                labelStyle: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? (isDark ? Colors.black87 : Colors.white)
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
