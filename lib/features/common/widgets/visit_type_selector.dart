import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';

class VisitTypeSelector extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String>? onTypeSelected;
  final bool isEnabled;

  const VisitTypeSelector({
    super.key,
    required this.selectedType,
    this.onTypeSelected,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final types = [
      (key: 'home', label: context.tr.visitHome),
      (key: 'phone', label: context.tr.visitPhone),
      (key: 'church', label: context.tr.visitChurch),
      (key: 'other', label: context.tr.visitOther),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr.visitTypeLabel,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.sp,
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: types.map((item) {
            final isSelected = selectedType == item.key;
            return InkWell(
              onTap: isEnabled ? () => onTypeSelected?.call(item.key) : null,
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryLight.withValues(alpha: isDark ? 0.3 : 0.15)
                      : (isDark ? const Color(0xFF131D31) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryLight : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? AppColors.primaryLight
                        : (isDark ? Colors.white70 : AppColors.textDark),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
