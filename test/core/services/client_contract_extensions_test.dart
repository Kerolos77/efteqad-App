import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/services/trusted_mutations.dart';
import 'package:efteqad/core/services/firestore_service.dart';
import 'package:efteqad/core/services/notification_service.dart';
import 'package:efteqad/core/services/excel_service.dart';
import 'package:efteqad/core/localization/excel_column_labels.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:efteqad/core/constants/constants.dart';
import 'package:efteqad/core/models/makhdom_model.dart';

void main() {
  test(
    'task deletion callable keeps its stable operation across failure and retry',
    () async {
      final sent = <Map<String, dynamic>>[];
      var fail = true;
      final service = FirestoreService(
        mutations: TrustedMutations(
          transport: (n, p) async {
            expect(n, 'deleteTask');
            sent.add(p);
            if (fail) throw StateError('offline');
            return {'success': true, 'status': 'cancelled'};
          },
        ),
      );
      await expectLater(service.deleteTask('task'), throwsA(anything));
      fail = false;
      await service.deleteTask('task');
      expect(sent.last, sent.first);
      expect(sent.first['taskId'], 'task');
      expect(sent.first['operationId'], isNotEmpty);
    },
  );
  test(
    'legacy notify caller emits only child identity, trusted kind and retained intent',
    () async {
      final sent = <Map<String, dynamic>>[];
      var fail = true;
      final service = NotificationService(
        mutations: TrustedMutations(
          transport: (n, p) async {
            expect(n, 'sendChildAlert');
            sent.add(p);
            if (fail) throw StateError('offline');
            return {'success': true, 'recipientId': 'new', 'outboxId': 'o'};
          },
        ),
      );
      Future<void> send() => service.notifyKhadem(
        recipientId: 'spoof',
        recipientName: 'Spoof',
        title: 'Private title',
        body: 'Private body',
        type: 'absence_alert',
        data: {'makhdomId': 'm', 'grade': 'spoof', 'consecutiveAbsences': 99},
      );
      await expectLater(send(), throwsA(anything));
      fail = false;
      await send();
      expect(sent.last, sent.first);
      expect(sent.first.keys.toSet(), {'makhdomId', 'kind', 'operationId'});
      expect(sent.first['makhdomId'], 'm');
      expect(sent.first['kind'], 'absence');
    },
  );
  test(
    'AR/EN Excel profile roundtrip preserves tracking date and text phones without importing derived state',
    () {
      final child = MakhdomModel(
        id: 'm',
        fullName: 'Name',
        phone: '01000000000',
        grade: '3rd',
        trackingStartDate: DateTime(2026, 9, 25),
        assignedKhademId: 's',
        visitCount: 99,
        createdAt: DateTime.now(),
      );
      for (final locale in [const Locale('ar'), const Locale('en')]) {
        final bytes = ExcelService.exportMakhdomeenBytes([
          child,
        ], labels: ExcelColumnLabels(locale));
        final parsed = ExcelService.parseMakhdomeen(
          bytes,
          grade: '3rd',
        ).rows.single;
        expect(parsed.trackingStartDate, DateTime(2026, 9, 25));
        expect(parsed.phone, '01000000000');
        expect(parsed.visitCount, 0);
        expect(parsed.assignedKhademId, isNull);
      }
      expect(
        TrustedMutations.profileFields(child)['trackingStartDate'],
        '2026-09-25T00:00:00.000',
      );
    },
  );

  test(
    'updateKhademProfile uses set with merge: true and saves all pending and service fields',
    () async {
      final docRef = _MockDocRef();
      final colRef = _MockColRef(docRef);
      final firestore = _MockFirestore(colRef);
      final service = FirestoreService(firestore: firestore);

      await service.updateKhademProfile(
        id: 'khadem-123',
        name: 'مينا مجدي',
        phone: '01234567890',
        serviceId: 'service_thanawy',
        resubmitPending: true,
      );

      expect(firestore.requestedCollection, AppConstants.colKhodam);
      expect(colRef.requestedDocId, 'khadem-123');
      expect(docRef.savedOptions?.merge, isTrue);
      expect(docRef.savedData?['name'], 'مينا مجدي');
      expect(docRef.savedData?['phone'], '01234567890');
      expect(docRef.savedData?['serviceId'], 'service_thanawy');
      expect(docRef.savedData?['serviceIds'], ['service_thanawy']);
      expect(docRef.savedData?['status'], 'pending');
      expect(docRef.savedData?['role'], 'pending');
      expect(docRef.savedData?['rejectionReason'], FieldValue.delete());
      expect(docRef.savedData?['updatedAt'], isNotNull);
    },
  );
}

// ignore: subtype_of_sealed_class, must_be_immutable
class _MockDocRef implements DocumentReference<Map<String, dynamic>> {
  Map<String, dynamic>? savedData;
  SetOptions? savedOptions;

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    savedData = data;
    savedOptions = options;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class, must_be_immutable
class _MockColRef implements CollectionReference<Map<String, dynamic>> {
  final _MockDocRef docRef;
  String? requestedDocId;
  _MockColRef(this.docRef);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    requestedDocId = path;
    return docRef;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _MockFirestore implements FirebaseFirestore {
  final _MockColRef colRef;
  String? requestedCollection;
  _MockFirestore(this.colRef);

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    requestedCollection = collectionPath;
    return colRef;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

