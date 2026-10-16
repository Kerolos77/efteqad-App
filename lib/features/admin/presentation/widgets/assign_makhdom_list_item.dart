import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/utils/color_generator.dart';

class AssignMakhdomListItem extends StatelessWidget {
  final MakhdomModel makhdom;
  final bool isSelected;
  final bool isDark;
  final Color targetColor;
  final String targetKhademId;
  final VoidCallback onTap;

  const AssignMakhdomListItem({
    super.key,
    required this.makhdom,
    required this.isSelected,
    required this.isDark,
    required this.targetColor,
    required this.targetKhademId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isWithOtherKhadem =
        makhdom.assignedKhademId != null &&
        makhdom.assignedKhademId!.isNotEmpty &&
        makhdom.assignedKhademId != targetKhademId;
    final otherKhademColor = ColorGenerator.getColorForId(
      makhdom.assignedKhademId,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.symmetric(vertical: 4.h),
        padding: EdgeInsets.symmetric(
          horizontal: 14.w,
          vertical: 12.h,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? targetColor.withValues(
                  alpha: isDark ? 0.12 : 0.06,
                )
              : (isDark
                    ? AppColors.surfaceDark
                    : Colors.white),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected
                ? targetColor.withValues(alpha: 0.5)
                : (isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight),
            width: isSelected ? 1.5.w : 1.w,
          ),
        ),
        child: Row(
          children: [
            // أيقونة الاختيار الحديثة (Circle check)
            Container(
              width: 24.w,
              height: 24.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? targetColor
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? targetColor
                      : (isDark
                            ? Colors.white30
                            : Colors.grey.shade400),
                  width: 2.w,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check_rounded,
                      size: 16.sp,
                      color: Colors.white,
                    )
                  : null,
            ),
            SizedBox(width: 14.w),

            // تفاصيل المخدوم
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          makhdom.fullName,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: 14.sp,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isWithOtherKhadem)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: otherKhademColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: otherKhademColor.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_pin_circle_rounded,
                                size: 12.sp,
                                color: otherKhademColor,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                makhdom.assignedKhademName ??
                                    context.tr.otherServant,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                  color: otherKhademColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8.w,
                    children: [
                      if (makhdom.area.isNotEmpty)
                        Text(
                          makhdom.area,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMuted,
                          ),
                        ),
                      if (makhdom.phone.isNotEmpty)
                        Text(
                          makhdom.phone,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMuted,
                          ),
                        ),
                      if (makhdom.isBrethrenOfLord)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 1.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentGold.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            context.tr.brethrenBadge,
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppColors.accentGold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
