import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../main.dart';
import 'settings_card.dart';
import 'settings_section_title.dart';

class SettingsLanguageSection extends StatelessWidget {
  final bool isDark;
  final Future<void> Function(Locale locale) onSelectLocale;

  const SettingsLanguageSection({
    super.key,
    required this.isDark,
    required this.onSelectLocale,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionTitle(
          title: context.tr.languageSection,
          icon: Icons.translate_outlined,
        ),
        SettingsCard(
          isDark: isDark,
          child: ValueListenableBuilder<Locale>(
            valueListenable: localeNotifier,
            builder: (context, currentLocale, _) {
              final isArabic = currentLocale.languageCode == 'ar';
              return Column(
                children: [
                  InkWell(
                    onTap: () => onSelectLocale(const Locale('ar', 'EG')),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16.r),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: isArabic
                                  ? AppColors.primaryLight.withValues(alpha: 0.15)
                                  : (isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.04)),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              '🇪🇬',
                              style: TextStyle(fontSize: 18.sp),
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr.arabicLang,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5.sp,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  context.tr.arabicLangDesc,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isArabic)
                            Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primaryLight,
                              size: 22.sp,
                            )
                          else
                            Icon(
                              Icons.radio_button_unchecked,
                              color: isDark ? Colors.white24 : Colors.black26,
                              size: 22.sp,
                            ),
                        ],
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: isDark
                        ? AppColors.cardBorderDark
                        : AppColors.cardBorderLight,
                  ),
                  InkWell(
                    onTap: () => onSelectLocale(const Locale('en', 'US')),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(16.r),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: !isArabic
                                  ? AppColors.primaryLight.withValues(alpha: 0.15)
                                  : (isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.04)),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              '🇺🇸',
                              style: TextStyle(fontSize: 18.sp),
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr.englishLang,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5.sp,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  context.tr.englishLangDesc,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isArabic)
                            Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primaryLight,
                              size: 22.sp,
                            )
                          else
                            Icon(
                              Icons.radio_button_unchecked,
                              color: isDark ? Colors.white24 : Colors.black26,
                              size: 22.sp,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
