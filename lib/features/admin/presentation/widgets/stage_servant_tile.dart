import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/utils/color_generator.dart';

class StageServantTile extends StatelessWidget {
  final KhademModel khadem;
  final int assignedCount;
  final String gradeLabel;
  final bool isDark;
  final VoidCallback onMakeCall;
  final VoidCallback onChangeGrade;

  const StageServantTile({
    super.key,
    required this.khadem,
    required this.assignedCount,
    required this.gradeLabel,
    required this.isDark,
    required this.onMakeCall,
    required this.onChangeGrade,
  });

  @override
  Widget build(BuildContext context) {
    final color = ColorGenerator.getColorForId(khadem.id);

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? AppColors.cardBorderDark
              : AppColors.cardBorderLight,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Text(
              khadem.name.isNotEmpty ? khadem.name[0] : context.tr.messageS,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        khadem.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5.sp,
                        ),
                      ),
                    ),
                    if (khadem.isGradeAdmin) ...[
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.sacredGold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          context.tr.currentGradeAdmin,
                          style: TextStyle(
                            color: AppColors.sacredGold,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 3.h),
                Text(
                  context.tr.messageAssignedStudents730(
                    gradeLabel,
                    AppFormatters(
                      Localizations.localeOf(context),
                    ).formatNumber(assignedCount),
                  ),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.phone_outlined, size: 18.sp),
            color: AppColors.textMuted,
            onPressed: onMakeCall,
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 18.sp),
            color: AppColors.textMuted,
            tooltip: context.tr.messageChangeGrade732,
            onPressed: onChangeGrade,
          ),
        ],
      ),
    );
  }
}
