import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/constants.dart';

class AppVersionInfo {
  final String latestVersion;
  final String minRequiredVersion;
  final bool forceUpdate;
  final String downloadUrl;
  final String? releaseNotes;
  final DateTime? updatedAt;

  const AppVersionInfo({
    required this.latestVersion,
    required this.minRequiredVersion,
    this.forceUpdate = false,
    this.downloadUrl = AppConstants.appDownloadPageUrl,
    this.releaseNotes,
    this.updatedAt,
  });

  factory AppVersionInfo.fallback() {
    return const AppVersionInfo(
      latestVersion: AppConstants.appVersion,
      minRequiredVersion: AppConstants.appVersion,
      forceUpdate: false,
      downloadUrl: AppConstants.appDownloadPageUrl,
    );
  }

  factory AppVersionInfo.fromMap(Map<String, dynamic>? data) {
    if (data == null) return AppVersionInfo.fallback();

    final rawLatest = (data['latestVersion'] ?? data['version'] ?? '')
        .toString()
        .trim();
    final latestVersion =
        rawLatest.isNotEmpty ? rawLatest : AppConstants.appVersion;

    final rawMin = (data['minRequiredVersion'] ?? '').toString().trim();
    final minRequiredVersion = rawMin.isNotEmpty ? rawMin : latestVersion;

    final rawUrl = (data['downloadUrl'] ?? data['url'] ?? '').toString().trim();
    final downloadUrl =
        rawUrl.isNotEmpty ? rawUrl : AppConstants.appDownloadPageUrl;

    final rawNotes = (data['releaseNotes'] ?? data['notes'] ?? '')
        .toString()
        .trim();

    DateTime? updatedAt;
    final rawUpdatedAt = data['updatedAt'];
    if (rawUpdatedAt is Timestamp) {
      updatedAt = rawUpdatedAt.toDate();
    } else if (rawUpdatedAt is String) {
      updatedAt = DateTime.tryParse(rawUpdatedAt);
    }

    return AppVersionInfo(
      latestVersion: latestVersion,
      minRequiredVersion: minRequiredVersion,
      forceUpdate: data['forceUpdate'] == true,
      downloadUrl: downloadUrl,
      releaseNotes: rawNotes.isNotEmpty ? rawNotes : null,
      updatedAt: updatedAt,
    );
  }

  bool isUpdateAvailable({String currentVersion = AppConstants.appVersion}) {
    return AppVersionService.compareVersions(latestVersion, currentVersion) > 0;
  }

  bool isForceUpdateRequired({
    String currentVersion = AppConstants.appVersion,
  }) {
    if (!isUpdateAvailable(currentVersion: currentVersion)) return false;
    if (forceUpdate) return true;
    return AppVersionService.compareVersions(
          minRequiredVersion,
          currentVersion,
        ) >
        0;
  }
}

class AppVersionService {
  static final AppVersionService shared = AppVersionService();

  final FirebaseFirestore? _providedFirestore;

  AppVersionService({FirebaseFirestore? firestore})
    : _providedFirestore = firestore;

  bool get _isFirebaseReady =>
      _providedFirestore != null || Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db =>
      _providedFirestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _versionDocRef => _db
      .collection(AppConstants.colSettings)
      .doc(AppConstants.docAppVersion);

  /// Compares two semantic version strings (e.g. "1.0.1" vs "1.0.0" or "v1.2.0+3").
  /// Returns:
  ///  - `1` if [v1] > [v2]
  ///  - `-1` if [v1] < [v2]
  ///  - `0` if [v1] == [v2]
  static int compareVersions(String v1, String v2) {
    String normalize(String v) {
      var clean = v.trim();
      if (clean.startsWith('v') || clean.startsWith('V')) {
        clean = clean.substring(1).trim();
      }
      return clean;
    }

    final n1 = normalize(v1);
    final n2 = normalize(v2);
    if (n1 == n2) return 0;

    final parts1AndBuild = n1.split('+');
    final parts2AndBuild = n2.split('+');

    final core1 = parts1AndBuild.first
        .split('.')
        .map((e) => int.tryParse(e.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
    final core2 = parts2AndBuild.first
        .split('.')
        .map((e) => int.tryParse(e.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();

    final maxLength = core1.length > core2.length ? core1.length : core2.length;
    for (var i = 0; i < maxLength; i++) {
      final num1 = i < core1.length ? core1[i] : 0;
      final num2 = i < core2.length ? core2[i] : 0;
      if (num1 > num2) return 1;
      if (num1 < num2) return -1;
    }

    if (parts1AndBuild.length > 1 && parts2AndBuild.length > 1) {
      final b1 = int.tryParse(parts1AndBuild[1]) ?? 0;
      final b2 = int.tryParse(parts2AndBuild[1]) ?? 0;
      if (b1 > b2) return 1;
      if (b1 < b2) return -1;
    }

    return 0;
  }

  /// دالة تُستدعى مرة واحدة فقط من `main.dart` لإنشاء مستند `settings/app_version`
  /// في Firestore بالحقول الافتراضية، وبعدها يتم التعديل يدوياً من لوحة تحكم Firestore فقط.
  Future<void> seedAppVersionToFirestoreOnce() async {
    if (!_isFirebaseReady) return;
    try {
      final snapshot = await _versionDocRef.get();
      if (!snapshot.exists) {
        await _versionDocRef.set({
          'version': AppConstants.appVersion,
          'latestVersion': AppConstants.appVersion,
          'minRequiredVersion': AppConstants.appVersion,
          'forceUpdate': false,
          'downloadUrl': AppConstants.appDownloadPageUrl,
          'releaseNotes': 'الإصدار الأول من تطبيق الراعي',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('settings/app_version initialized in Firestore.');
      }
    } catch (e) {
      debugPrint('Could not initialize settings/app_version: $e');
    }
  }

  /// قراءة فقط (Read-Only): يفحص الإصدار الحالي من Firestore (`settings/app_version`).
  Future<AppVersionInfo> checkVersion() async {
    if (!_isFirebaseReady) {
      return AppVersionInfo.fallback();
    }
    try {
      final doc = await _versionDocRef.get();
      if (!doc.exists || doc.data() == null) {
        return AppVersionInfo.fallback();
      }
      return AppVersionInfo.fromMap(doc.data());
    } catch (e) {
      debugPrint('Error checking app version from Firestore: $e');
      return AppVersionInfo.fallback();
    }
  }

  /// قراءة فقط (Read-Only): يراقب مستند `settings/app_version` في Firestore.
  Stream<AppVersionInfo> watchVersion() {
    if (!_isFirebaseReady) {
      return Stream<AppVersionInfo>.value(
        AppVersionInfo.fallback(),
      ).asBroadcastStream();
    }
    return _versionDocRef
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) {
            return AppVersionInfo.fallback();
          }
          return AppVersionInfo.fromMap(snapshot.data());
        })
        .handleError((Object error) {
          debugPrint('Error watching app version stream: $error');
        })
        .asBroadcastStream();
  }

  /// يفتح صفحة التحميل الرسمية في المتصفح الخارجي لتنزيل الإصدار الجديد.
  Future<bool> openDownloadPage([String? customUrl]) async {
    final target = (customUrl != null && customUrl.trim().isNotEmpty)
        ? customUrl.trim()
        : AppConstants.appDownloadPageUrl;
    final uri = Uri.tryParse(target);
    if (uri == null) return false;
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return true;
      return await launchUrl(uri);
    } catch (e) {
      debugPrint('Failed to launch download URL ($target): $e');
      return false;
    }
  }
}
