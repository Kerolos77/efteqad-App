import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';

class ServiceGradeInputRow extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final bool isSaving;
  final bool isDark;
  final bool canDelete;
  final VoidCallback onDelete;

  const ServiceGradeInputRow({
    super.key,
    required this.index,
    required this.controller,
    required this.isSaving,
    required this.isDark,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black12,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14.r,
              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.15),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isSaving,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'اسم الصف (مثال: الصف الأول الابتدائي)',
                  hintStyle: TextStyle(
                    fontSize: 13.sp,
                    color: isDark ? Colors.white38 : AppColors.textMuted,
                  ),
                ),
                style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w600),
              ),
            ),
            if (canDelete)
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, size: 18.sp),
                color: AppColors.errorColor.withValues(alpha: 0.7),
                tooltip: 'حذف هذا الصف',
                onPressed: isSaving ? null : onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
