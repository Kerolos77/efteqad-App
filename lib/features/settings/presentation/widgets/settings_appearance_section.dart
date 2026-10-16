import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/settings/settings_cubit.dart';
import 'settings_card.dart';
import 'settings_section_title.dart';

class SettingsAppearanceSection extends StatelessWidget {
  final bool isDark;

  const SettingsAppearanceSection({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionTitle(
          title: context.tr.appearanceSection,
          icon: Icons.palette_outlined,
        ),
        SettingsCard(
          isDark: isDark,
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.amber : AppColors.primaryLight)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: isDark ? Colors.amber : AppColors.primaryLight,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDark ? context.tr.darkMode : context.tr.lightMode,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                    Text(
                      isDark
                          ? context.tr.darkModeDesc
                          : context.tr.lightModeDesc,
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
              Switch(
                value: isDark,
                activeThumbColor: Colors.amber,
                onChanged: (val) async {
                  final newMode = val ? ThemeMode.dark : ThemeMode.light;
                  try {
                    await context.read<SettingsCubit>().setThemeMode(newMode);
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppFailure.fromException(error)
                                .localizedMessage(context.tr),
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
