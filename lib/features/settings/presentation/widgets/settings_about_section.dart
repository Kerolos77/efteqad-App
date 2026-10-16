import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/app_version_service.dart';
import 'settings_card.dart';
import 'settings_section_title.dart';

class SettingsAboutSection extends StatelessWidget {
  final bool isDark;
  final bool isCheckingVersion;
  final Stream<AppVersionInfo> versionStream;
  final VoidCallback onCheckForUpdates;

  const SettingsAboutSection({
    super.key,
    required this.isDark,
    required this.isCheckingVersion,
    required this.versionStream,
    required this.onCheckForUpdates,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionTitle(
          title: context.tr.aboutSection,
          icon: Icons.info_outline_rounded,
        ),
        SettingsCard(
          isDark: isDark,
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 46.w,
                    height: 46.h,
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: AppColors.sacredGold.withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: Image.asset(
                        AppConstants.appLogoPath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr.appName,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16.sp,
                          ),
                        ),
                        Text(
                          '«${context.tr.appTagline}»',
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            color: AppColors.accentGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white10
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        context.tr.version(AppConstants.appVersion),
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                context.tr.aboutServiceDesc,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 14.h),
              StreamBuilder<AppVersionInfo>(
                stream: versionStream,
                initialData: AppVersionInfo.fallback(),
                builder: (context, snapshot) {
                  final versionInfo = snapshot.data ?? AppVersionInfo.fallback();
                  final hasUpdate = versionInfo.isUpdateAvailable();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (hasUpdate) ...[
                        Container(
                          margin: EdgeInsets.only(bottom: 10.h),
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            color: AppColors.warningColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: AppColors.warningColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.new_releases_rounded,
                                color: AppColors.warningColor,
                                size: 20.sp,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  'يتوفر تحديث جديد (v${versionInfo.latestVersion})',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.sp,
                                    color: AppColors.warningColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: [
                          OutlinedButton.icon(
                            onPressed: isCheckingVersion ? null : onCheckForUpdates,
                            icon: isCheckingVersion
                                ? SizedBox(
                                    width: 14.w,
                                    height: 14.h,
                                    child: const CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Icon(Icons.system_update_alt_rounded, size: 16.sp),
                            label: Text(
                              'التحقق من التحديثات',
                              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => AppVersionService.shared.openDownloadPage(
                              versionInfo.downloadUrl,
                            ),
                            icon: Icon(Icons.open_in_new_rounded, size: 16.sp),
                            label: Text(
                              hasUpdate
                                  ? 'تحميل الإصدار الجديد (v${versionInfo.latestVersion})'
                                  : 'صفحة تحميل التطبيق',
                              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hasUpdate
                                  ? AppColors.sacredGold
                                  : AppColors.primaryNavy,
                              foregroundColor: hasUpdate
                                  ? AppColors.primaryNavy
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
