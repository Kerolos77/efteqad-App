import 'package:efteqad/core/constants/constants.dart';
import 'package:efteqad/core/services/app_version_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppVersionService & AppVersionInfo Tests', () {
    test('compareVersions compares semantic versions and build numbers accurately', () {
      expect(AppVersionService.compareVersions('1.0.0', '1.0.0'), 0);
      expect(AppVersionService.compareVersions('v1.0.0', '1.0.0'), 0);
      expect(AppVersionService.compareVersions('1.0.1', '1.0.0'), 1);
      expect(AppVersionService.compareVersions('1.1.0', '1.0.9'), 1);
      expect(AppVersionService.compareVersions('2.0.0', '1.9.9'), 1);
      expect(AppVersionService.compareVersions('1.0.0', '1.0.1'), -1);
      expect(AppVersionService.compareVersions('1.0.0+2', '1.0.0+1'), 1);
    });

    test('AppVersionInfo detects available and mandatory updates with fallback downloadUrl', () {
      final info = AppVersionInfo.fromMap({
        'version': '1.1.0',
        'minRequiredVersion': '1.0.5',
        'releaseNotes': 'إضافة نظام الحضور والغياب الجديد',
      });

      expect(info.latestVersion, '1.1.0');
      expect(info.downloadUrl, AppConstants.appDownloadPageUrl);
      expect(info.isUpdateAvailable(currentVersion: '1.0.0'), isTrue);
      expect(info.isForceUpdateRequired(currentVersion: '1.0.0'), isTrue);
      expect(info.isUpdateAvailable(currentVersion: '1.1.0'), isFalse);
      expect(info.isForceUpdateRequired(currentVersion: '1.1.0'), isFalse);
    });
  });
}
