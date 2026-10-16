import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:efteqad/core/localization/app_formatters.dart';
import 'package:efteqad/core/localization/domain_labels.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/makhdom_model.dart';

class MakhdomCardExpandedDetails extends StatelessWidget {
  final MakhdomModel makhdom;
  final bool isDark;
  final ValueChanged<String> onMakeCall;

  const MakhdomCardExpandedDetails({
    super.key,
    required this.makhdom,
    required this.isDark,
    required this.onMakeCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 12.h,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.black12 : const Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.cardBorderDark
                : AppColors.cardBorderLight,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (makhdom.address.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.home_outlined,
                  size: 15.sp,
                  color: AppColors.textMuted,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    makhdom.address,
                    style: TextStyle(
                      fontSize: 12.sp,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
          ],

          if (makhdom.school.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 15.sp,
                  color: AppColors.accentBlue,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    '${context.tr.schoolLabel} ${makhdom.school}${makhdom.secondaryType.isNotEmpty ? " (${makhdom.secondaryType})" : ""}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
          ],

          if (makhdom.age != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.cake_outlined,
                  size: 15.sp,
                  color: Colors.pinkAccent,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    makhdom.birthDate != null
                        ? '${context.tr.birthDateDetailLabel} ${AppFormatters(Localizations.localeOf(context)).formatDate(makhdom.birthDate)} (${context.tr.ageYearsOld(makhdom.age!)})'
                        : context.tr.messageAgeEstimatedFrom(
                            context.tr.ageYearsOld(makhdom.age!),
                            DomainLabels(
                              Localizations.localeOf(context),
                            ).gradeName(makhdom.grade),
                          ),
                    style: TextStyle(
                      fontSize: 12.sp,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
          ],

          // هواتف الوالدين
          Row(
            children: [
              if (makhdom.fatherPhone.isNotEmpty)
                Expanded(
                  child: InkWell(
                    onTap: () => onMakeCall(makhdom.fatherPhone),
                    borderRadius: BorderRadius.circular(10.r),
                    child: Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: isDark
                              ? AppColors.cardBorderDark
                              : AppColors.cardBorderLight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.phone_android,
                            size: 14.sp,
                            color: AppColors.primaryLight,
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              '${context.tr.fatherPhoneLabel} ${AppFormatters(Localizations.localeOf(context)).ltr(makhdom.fatherPhone)}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (makhdom.fatherPhone.isNotEmpty &&
                  makhdom.motherPhone.isNotEmpty)
                SizedBox(width: 8.w),
              if (makhdom.motherPhone.isNotEmpty)
                Expanded(
                  child: InkWell(
                    onTap: () => onMakeCall(makhdom.motherPhone),
                    borderRadius: BorderRadius.circular(10.r),
                    child: Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: isDark
                              ? AppColors.cardBorderDark
                              : AppColors.cardBorderLight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.phone_android,
                            size: 14.sp,
                            color: Colors.purple,
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              '${context.tr.motherPhoneLabel} ${AppFormatters(Localizations.localeOf(context)).ltr(makhdom.motherPhone)}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),

          if (makhdom.notes != null && makhdom.notes!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                '${context.tr.notesLabel} ${makhdom.notes!}',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
