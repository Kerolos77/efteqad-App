import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';

class AttendanceHubHeader extends StatelessWidget {
  final String gradeLabel;
  final bool isStageAdmin;
  final List<String> grades;
  final String selectedGrade;
  final String Function(String) getGradeLabel;
  final ValueChanged<String> onGradeSelected;
  final bool isDark;

  const AttendanceHubHeader({
    super.key,
    required this.gradeLabel,
    required this.isStageAdmin,
    required this.grades,
    required this.selectedGrade,
    required this.getGradeLabel,
    required this.onGradeSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(
                Icons.how_to_reg_rounded,
                color: AppColors.primaryLight,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الحضور والغياب ($gradeLabel)',
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'رصد مباشر لخدام الفرقة مع قفل تلقائي لمنع التضارب ودمج ذكي للأوفلاين',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (isStageAdmin) ...[
          SizedBox(height: 14.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final g in grades)
                  Padding(
                    padding: EdgeInsetsDirectional.only(end: 8.w),
                    child: ChoiceChip(
                      label: Text(
                        getGradeLabel(g),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: selectedGrade == g
                              ? Colors.white
                              : (isDark ? Colors.white70 : AppColors.textDark),
                        ),
                      ),
                      selected: selectedGrade == g,
                      selectedColor: AppColors.primaryLight,
                      onSelected: (_) => onGradeSelected(g),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
