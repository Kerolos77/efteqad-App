import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:efteqad/core/localization/app_formatters.dart';
import 'package:efteqad/core/localization/domain_labels.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';

class MakhdomAgeSelector extends StatelessWidget {
  final DateTime? birthDate;
  final int currentEffectiveAge;
  final bool isDark;
  final bool isEditing;
  final String defaultGrade;
  final bool disabled;
  final ValueChanged<DateTime?> onBirthDateChanged;

  const MakhdomAgeSelector({
    super.key,
    required this.birthDate,
    required this.currentEffectiveAge,
    required this.isDark,
    required this.isEditing,
    required this.defaultGrade,
    required this.disabled,
    required this.onBirthDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9))
            .withValues(alpha: 0.7),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(7.r),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.cake_outlined,
                  size: 20.sp,
                  color: AppColors.primaryLight,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            context.tr.messageAgeYears(
                              AppFormatters(
                                Localizations.localeOf(context),
                              ).formatNumber(currentEffectiveAge),
                            ),
                            style: TextStyle(
                              fontSize: 14.5.sp,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 7.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: (birthDate != null
                                    ? AppColors.successColor
                                    : AppColors.accentBlue)
                                .withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            birthDate != null
                                ? context.tr.messageCalculatedPrecisely
                                : context.tr.messageAutomatic,
                            style: TextStyle(
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w700,
                              color: birthDate != null
                                  ? AppColors.successColor
                                  : AppColors.accentBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      birthDate != null
                          ? context.tr.birthDateCaption(
                              AppFormatters(
                                Localizations.localeOf(context),
                              ).formatDate(birthDate!),
                            )
                          : context.tr.messageAgeEstimatedFromSecondaryGrade(
                              DomainLabels(
                                Localizations.localeOf(context),
                              ).gradeName(defaultGrade).toString(),
                            ),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (birthDate != null)
                IconButton(
                  icon: Icon(Icons.close, size: 18.sp),
                  splashRadius: 16.r,
                  tooltip: context.tr.messageResetToAutomaticCalculation,
                  color: AppColors.textMuted,
                  onPressed: disabled ? null : () => onBirthDateChanged(null),
                ),
            ],
          ),
          SizedBox(height: 10.h),
          // شريط سريع لاختيار السن بنقرة واحدة أو تحديد تاريخ دقيق
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                ...[14, 15, 16, 17, 18].map((ageVal) {
                  final isSelected = currentEffectiveAge == ageVal;
                  return Padding(
                    padding: EdgeInsetsDirectional.only(start: 6.w),
                    child: InkWell(
                      onTap: () {
                        if (disabled) return;
                        final targetYear = DateTime.now().year - ageVal;
                        onBirthDateChanged(DateTime(targetYear, 1, 1));
                      },
                      borderRadius: BorderRadius.circular(10.r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 5.h,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryLight
                              : (isDark
                                    ? Colors.white10
                                    : Colors.white),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryLight
                                : (isDark
                                      ? Colors.white12
                                      : AppColors.borderLight),
                          ),
                        ),
                        child: Text(
                          context.tr.messageYears721(
                            AppFormatters(
                              Localizations.localeOf(context),
                            ).formatNumber(ageVal),
                          ),
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                      ? Colors.white70
                                      : AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                SizedBox(width: 4.w),
                InkWell(
                  onTap: () async {
                    if (disabled) return;
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: birthDate ??
                          DateTime(DateTime.now().year - currentEffectiveAge, 1, 1),
                      firstDate: DateTime(1990),
                      lastDate: DateTime.now(),
                      initialDatePickerMode: DatePickerMode.year,
                      helpText: context.tr.messageChooseExactBirthDate,
                      confirmText: context.tr.confirm,
                      cancelText: context.tr.cancel,
                    );
                    if (picked != null) {
                      onBirthDateChanged(picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.white,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: isDark ? Colors.white12 : AppColors.borderLight,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          size: 14.sp,
                          color: AppColors.accentBlue,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          context.tr.messageExactDate,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white70
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
