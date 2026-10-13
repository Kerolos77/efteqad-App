import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../../../core/services/app_version_service.dart';
import '../../../core/services/shorebird_updater_service.dart';

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
            ? AppConstants.surfaceDark
            : AppConstants.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: AppConstants.sacredGold.withValues(alpha: 0.45),
            width: 1.4,
          ),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppConstants.primaryNavy, AppConstants.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppConstants.sacredGold.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.sacredGold.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.system_update_rounded,
                color: AppConstants.sacredGold,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isMandatory
                  ? 'تحديث هام ومطلوب للتطبيق'
                  : 'يتوفر إصدار جديد من تطبيق الراعي',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 17,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildVersionPill(
                      label: 'إصدارك الحالي',
                      version: 'v$currentVersion',
                      color: AppConstants.textMuted,
                    ),
                    const Icon(
                      Icons.arrow_back_rounded,
                      color: AppConstants.sacredGold,
                      size: 20,
                    ),
                    _buildVersionPill(
                      label: 'الإصدار الجديد',
                      version: 'v${versionInfo.latestVersion}',
                      color: AppConstants.successColor,
                    ),
                  ],
                ),
              ),
              if (versionInfo.releaseNotes != null &&
                  versionInfo.releaseNotes!.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'ما الجديد في هذا الإصدار:',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppConstants.sacredGold,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppConstants.sacredGold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppConstants.sacredGold.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    versionInfo.releaseNotes!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                isMandatory
                    ? 'يرجى تحميل أحدث إصدار من الصفحة الرسمية للتطبيق للمتابعة.'
                    : 'يمكنك الآن تحميل النسخة الجديدة مباشرة من صفحة التحميل الرسمية للتطبيق.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppConstants.textMutedDark
                      : AppConstants.textMuted,
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
                icon: const Icon(Icons.download_rounded, size: 20),
                label: const Text(
                  'فتح صفحة التحميل وتنزيل التحديث',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.sacredGold,
                  foregroundColor: AppConstants.primaryNavy,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (!isMandatory) ...[
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'تذكيري لاحقاً',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVersionPill({
    required String label,
    required String version,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppConstants.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            version,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: color,
            ),
          ),
        ),
      ],
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
              backgroundColor: AppConstants.primaryNavy,
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
    final hasUpdate = _versionInfo.isUpdateAvailable();
    if (!hasUpdate) return widget.child;

    return Column(
      children: [
        Material(
          color: AppConstants.primaryNavy,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppConstants.sacredGold.withValues(alpha: 0.45),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.system_update_rounded,
                  color: AppConstants.sacredGold,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'يتوفر إصدار جديد من التطبيق (v${_versionInfo.latestVersion})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => AppVersionService.shared.openDownloadPage(
                    _versionInfo.downloadUrl,
                  ),
                  icon: const Icon(
                    Icons.download_rounded,
                    size: 15,
                    color: AppConstants.sacredGold,
                  ),
                  label: const Text(
                    'تنزيل التحديث',
                    style: TextStyle(
                      color: AppConstants.sacredGold,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
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

