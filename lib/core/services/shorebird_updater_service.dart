import 'dart:developer' as developer;
import 'package:shorebird_code_push/shorebird_code_push.dart';

class ShorebirdUpdaterService {
  final ShorebirdUpdater _updater;

  ShorebirdUpdaterService({ShorebirdUpdater? updater})
      : _updater = updater ?? ShorebirdUpdater();

  /// هل التطبيق يعمل بنسخة تدعم Shorebird (Release build with Shorebird Engine)؟
  bool get isAvailable {
    try {
      return _updater.isAvailable;
    } catch (_) {
      return false;
    }
  }

  /// رقم الباتش اللحظي الحالي المطبق على الجهاز
  Future<int?> getCurrentPatchNumber() async {
    if (!isAvailable) return null;
    try {
      final patch = await _updater.readCurrentPatch();
      return patch?.number;
    } catch (e) {
      developer.log('Error reading current Shorebird patch: $e',
          name: 'ShorebirdUpdaterService');
      return null;
    }
  }

  /// فحص حالة التحديث وتنزيله تلقائياً في الخلفية
  /// يُرجع `true` إذا تم تنزيل باتش جديد وبانتظار إعادة تشغيل التطبيق لتطبيقه
  Future<bool> checkAndDownloadPatch({
    void Function(UpdateStatus status)? onStatusChanged,
  }) async {
    if (!isAvailable) {
      onStatusChanged?.call(UpdateStatus.unavailable);
      return false;
    }

    try {
      final status = await _updater.checkForUpdate();
      onStatusChanged?.call(status);

      if (status == UpdateStatus.outdated) {
        developer.log('New Shorebird patch found. Downloading in background...',
            name: 'ShorebirdUpdaterService');
        await _updater.update();
        onStatusChanged?.call(UpdateStatus.restartRequired);
        return true;
      } else if (status == UpdateStatus.restartRequired) {
        return true;
      }

      return false;
    } catch (e, st) {
      developer.log('Error updating Shorebird patch: $e',
          name: 'ShorebirdUpdaterService', error: e, stackTrace: st);
      return false;
    }
  }
}
