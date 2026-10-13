import 'package:flutter_test/flutter_test.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:efteqad/core/services/shorebird_updater_service.dart';

class FakeShorebirdUpdater implements ShorebirdUpdater {
  final bool available;
  final Patch? currentPatch;
  UpdateStatus status;
  bool updateCalled = false;

  FakeShorebirdUpdater({
    this.available = true,
    this.currentPatch,
    this.status = UpdateStatus.upToDate,
  });

  @override
  bool get isAvailable => available;

  @override
  Future<Patch?> readCurrentPatch() async => currentPatch;

  @override
  Future<Patch?> readNextPatch() async => currentPatch;

  @override
  Future<UpdateStatus> checkForUpdate({UpdateTrack? track}) async => status;

  @override
  Future<void> update({UpdateTrack? track}) async {
    updateCalled = true;
    status = UpdateStatus.restartRequired;
  }
}

void main() {
  group('ShorebirdUpdaterService Tests', () {
    test('returns false when Shorebird is unavailable', () async {
      final fake = FakeShorebirdUpdater(available: false);
      final service = ShorebirdUpdaterService(updater: fake);

      expect(service.isAvailable, isFalse);
      final result = await service.checkAndDownloadPatch();
      expect(result, isFalse);
    });

    test('reads current patch number correctly', () async {
      final fake = FakeShorebirdUpdater(
        available: true,
        currentPatch: const Patch(number: 3),
      );
      final service = ShorebirdUpdaterService(updater: fake);

      expect(service.isAvailable, isTrue);
      final patchNum = await service.getCurrentPatchNumber();
      expect(patchNum, equals(3));
    });

    test('downloads update when outdated and returns true', () async {
      final fake = FakeShorebirdUpdater(
        available: true,
        status: UpdateStatus.outdated,
      );
      final service = ShorebirdUpdaterService(updater: fake);

      final result = await service.checkAndDownloadPatch();
      expect(result, isTrue);
      expect(fake.updateCalled, isTrue);
    });
  });
}
