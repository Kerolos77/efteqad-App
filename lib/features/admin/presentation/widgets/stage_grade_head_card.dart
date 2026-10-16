import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/khadem_model.dart';

class StageGradeHeadCard extends StatelessWidget {
  final String gradeKey;
  final String gradeTitle;
  final KhademModel? headKhadem;
  final List<KhademModel> gradeKhodam;
  final Color color;
  final bool isDark;
  final VoidCallback onTapGrade;
  final VoidCallback onAppointHead;

  const StageGradeHeadCard({
    super.key,
    required this.gradeKey,
    required this.gradeTitle,
    required this.headKhadem,
    required this.gradeKhodam,
    required this.color,
    required this.isDark,
    required this.onTapGrade,
    required this.onAppointHead,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTapGrade,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.school, color: color, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          gradeTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5.sp,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Icon(
                          Icons.open_in_new_rounded,
                          size: 13.sp,
                          color: color.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      headKhadem != null
                          ? headKhadem!.name
                          : context.tr.noGradeHeadAssigned,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: headKhadem != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: headKhadem != null ? null : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: onAppointHead,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: color),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                ),
                child: Text(
                  headKhadem != null
                      ? context.tr.changeGradeHeadBtn
                      : context.tr.appointGradeHeadBtn,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
