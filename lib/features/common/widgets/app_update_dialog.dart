import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/constants.dart';
import '../../../core/services/app_version_service.dart';
import '../../../core/services/shorebird_updater_service.dart';
import 'version_pill.dart';

class AppUpdateDialog extends StatelessWidget {
  final AppVersionInfo versionInfo;
  final String currentVersion;

  const AppUpdateDialog({
    super.key,
    required this.versionInfo,
    this.currentVersion = AppConstants.appVersion,
  });

  static Future<void> show(
    BuildContext context, {
    required AppVersionInfo versionInfo,
    String currentVersion = AppConstants.appVersion,
  }) {
    if (kIsWeb) return Future.value();
    final isMandatory = versionInfo.isForceUpdateRequired(
      currentVersion: currentVersion,
    );
    return showDialog<void>(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (_) => AppUpdateDialog(
        versionInfo: versionInfo,
        currentVersion: currentVersion,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMandatory = versionInfo.isForceUpdateRequired(
      currentVersion: currentVersion,
    );

    return PopScope(
      canPop: !isMandatory,
      child: AlertDialog(
        backgroundColor: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22.r),
          side: BorderSide(
            color: AppColors.sacredGold.withValues(alpha: 0.45),
            width: 1.4,
          ),
        ),
        titlePadding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 8.h),
        contentPadding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
        actionsPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        title: Column(
          children: [
            Container(
              width: 60.r,
              height: 60.r,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryNavy, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: AppColors.sacredGold.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.sacredGold.withValues(alpha: 0.2),
                    blurRadius: 12.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: Icon(
                Icons.system_update_rounded,
                color: AppColors.sacredGold,
                size: 32.r,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              isMandatory
                  ? 'تحديث هام ومطلوب للتطبيق'
                  : 'يتوفر إصدار جديد من تطبيق الراعي',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 17.sp,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 10.h,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    VersionPill(
                      label: 'إصدارك الحالي',
                      version: 'v$currentVersion',
                      color: AppColors.textMuted,
                    ),
                    Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.sacredGold,
                      size: 20.r,
                    ),
                    VersionPill(
                      label: 'الإصدار الجديد',
                      version: 'v${versionInfo.latestVersion}',
                      color: AppColors.successColor,
                    ),
                  ],
                ),
              ),
              if (versionInfo.releaseNotes != null &&
                  versionInfo.releaseNotes!.isNotEmpty) ...[
                SizedBox(height: 14.h),
                Text(
                  'ما الجديد في هذا الإصدار:',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.sp,
                    color: AppColors.sacredGold,
                  ),
                ),
                SizedBox(height: 6.h),
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: AppColors.sacredGold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.sacredGold.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    versionInfo.releaseNotes!,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              SizedBox(height: 12.h),
              Text(
                isMandatory
                    ? 'يرجى تحميل أحدث إصدار من الصفحة الرسمية للتطبيق للمتابعة.'
                    : 'يمكنك الآن تحميل النسخة الجديدة مباشرة من صفحة التحميل الرسمية للتطبيق.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await AppVersionService.shared.openDownloadPage(
                    versionInfo.downloadUrl,
                  );
                },
                icon: Icon(Icons.download_rounded, size: 20.r),
                label: Text(
                  'فتح صفحة التحميل وتنزيل التحديث',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5.sp,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sacredGold,
                  foregroundColor: AppColors.primaryNavy,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              if (!isMandatory) ...[
                SizedBox(height: 6.h),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'تذكيري لاحقاً',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class AppVersionUpdateGuard extends StatefulWidget {
  final Widget child;

  const AppVersionUpdateGuard({super.key, required this.child});

  @override
  State<AppVersionUpdateGuard> createState() => _AppVersionUpdateGuardState();
}

class _AppVersionUpdateGuardState extends State<AppVersionUpdateGuard> {
  StreamSubscription<AppVersionInfo>? _subscription;
  AppVersionInfo _versionInfo = AppVersionInfo.fallback();
  String? _lastPromptedVersion;
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) return;
    _subscription = AppVersionService.shared.watchVersion().listen((info) {
      if (!mounted) return;
      setState(() => _versionInfo = info);
      if (info.isUpdateAvailable() &&
          _lastPromptedVersion != info.latestVersion &&
          !_isDialogShowing) {
        _lastPromptedVersion = info.latestVersion;
        _isDialogShowing = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) {
            _isDialogShowing = false;
            return;
          }
          await AppUpdateDialog.show(context, versionInfo: info);
          _isDialogShowing = false;
        });
      }
    });
    // فحص وتنزيل أي تحديث لحظي من Shorebird في الخلفية
    Future.microtask(() async {
      final shorebirdService = ShorebirdUpdaterService();
      if (shorebirdService.isAvailable) {
        final downloaded = await shorebirdService.checkAndDownloadPatch();
        if (downloaded && mounted) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            const SnackBar(
              content: Text(
                'تم تنزيل تحديث لحظي جديد بنجاح! سيتم تطبيقه عند إعادة فتح التطبيق.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              backgroundColor: AppColors.primaryNavy,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return widget.child;
    final hasUpdate = _versionInfo.isUpdateAvailable();
    if (!hasUpdate) return widget.child;

    return Column(
      children: [
        Material(
          color: AppColors.primaryNavy,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.sacredGold.withValues(alpha: 0.45),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.system_update_rounded,
                  color: AppColors.sacredGold,
                  size: 18.r,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'يتوفر إصدار جديد من التطبيق (v${_versionInfo.latestVersion})',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => AppVersionService.shared.openDownloadPage(
                    _versionInfo.downloadUrl,
                  ),
                  icon: Icon(
                    Icons.download_rounded,
                    size: 15.r,
                    color: AppColors.sacredGold,
                  ),
                  label: Text(
                    'تنزيل التحديث',
                    style: TextStyle(
                      color: AppColors.sacredGold,
                      fontWeight: FontWeight.w900,
                      fontSize: 12.sp,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
