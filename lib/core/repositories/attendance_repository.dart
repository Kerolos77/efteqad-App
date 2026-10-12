import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import '../constants/constants.dart';
import '../models/attendance_session_model.dart';
import '../models/snapshot_list.dart';
import '../errors/app_failure.dart';
import '../services/trusted_mutations.dart';

abstract class AttendanceRepository {
  Stream<AttendanceSessionModel?> watchGradeSession({
    required String sessionId,
    required String grade,
    String? taskId,
    String? expectedUid,
  });
  Stream<List<AttendanceSessionModel>> watchGradeAttendance({
    required String grade,
    DateTime? from,
    DateTime? to,
  });
  Future<void> setPresence({
    required String sessionId,
    required String grade,
    required String makhdomId,
    required bool isPresent,
    required String date,
    required String type,
    required String khademId,
    required String khademName,
    String? taskId,
    String? operationId,
    bool onlyOwnMark = false,
  });
  Future<void> setExcuse({
    required String sessionId,
    required String grade,
    required String makhdomId,
    required String? note,
    required String date,
    required String type,
    required String khademId,
    required String khademName,
    String? operationId,
  });
  Future<bool> acquireSessionLock({
    required String sessionId,
    required String grade,
    required String khademId,
    required String khademName,
    bool force = false,
  });
  Future<void> releaseSessionLock({
    required String sessionId,
    required String grade,
    required String khademId,
    bool force = false,
  });
  Future<void> finalizeAttendance({
    required String sessionId,
    required String grade,
    String? taskId,
  });
  Future<void> reopenAttendance({
    required String sessionId,
    required String grade,
    required String reason,
    required String operationId,
  });
}

typedef AttendancePartStream =
    Stream<AttendanceSessionModel?> Function(String sessionId, String grade);

class FirestoreAttendanceRepository implements AttendanceRepository {
  static const Duration lockLeaseDuration = Duration(seconds: 45);

  final FirebaseFirestore? _providedFirestore;
  FirebaseFirestore get _firestore =>
      _providedFirestore ?? FirebaseFirestore.instance;
  final TrustedMutations _mutations;
  final AttendancePartStream? _sessionStream;
  FirestoreAttendanceRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    TrustedMutations? mutations,
    AttendancePartStream? sessionStream,
  }) : _providedFirestore = firestore,
       _mutations = mutations ?? TrustedMutations(functions: functions),
       _sessionStream = sessionStream;
  Stream<AttendanceSessionModel?> _part(String sessionId, String grade) =>
      _sessionStream?.call(sessionId, grade) ??
      _firestore
          .collection(AppConstants.colAttendance)
          .doc(sessionId)
          .collection('grades')
          .doc(grade)
          .snapshots(includeMetadataChanges: true)
          .where(
            (snap) =>
                !snap.metadata.isFromCache && !snap.metadata.hasPendingWrites,
          )
          .map(
            (snap) => snap.exists
                ? AttendanceSessionModel.fromMap(snap.data()!, sessionId)
                : null,
          );
  @override
  Stream<AttendanceSessionModel?> watchGradeSession({
    required String sessionId,
    required String grade,
    String? taskId,
    String? expectedUid,
  }) {
    if (taskId != null) {
      return _initializedSession(sessionId, grade, taskId, expectedUid);
    }
    if (grade != 'all') return _part(sessionId, grade);
    late StreamController<AttendanceSessionModel?> controller;
    final latest = <String, AttendanceSessionModel?>{};
    final subscriptions = <StreamSubscription<AttendanceSessionModel?>>[];
    controller = StreamController<AttendanceSessionModel?>(
      onListen: () {
        for (final g in ['1st', '2nd', '3rd']) {
          subscriptions.add(
            _part(sessionId, g).listen((part) {
              latest[g] = part;
              if (latest.length != 3) return;
              final parts = latest.values
                  .whereType<AttendanceSessionModel>()
                  .toList();
              if (parts.isEmpty) {
                controller.add(null);
                return;
              }
              final first = parts.first;
              final mergedPresentBy = <String, Map<String, bool>>{};
              final mergedExcuses = <String, AttendanceExcuse>{};
              for (final p in parts) {
                p.presentBy.forEach((studentId, byServant) {
                  mergedPresentBy.putIfAbsent(studentId, () => {}).addAll(
                    byServant,
                  );
                });
                mergedExcuses.addAll(p.excuses);
              }
              controller.add(
                first.copyWith(
                  id: sessionId,
                  grade: 'all',
                  attendedMakhdomIds: parts
                      .expand((p) => p.attendedMakhdomIds)
                      .toSet()
                      .toList(),
                  presentBy: mergedPresentBy,
                  excuses: mergedExcuses,
                  status: parts.any((p) => p.isFinalized)
                      ? 'finalized'
                      : 'draft',
                ),
              );
            }, onError: controller.addError),
          );
        }
      },
      onCancel: () async {
        for (final sub in subscriptions) {
          await sub.cancel();
        }
      },
    );
    return controller.stream;
  }

  Stream<AttendanceSessionModel?> _initializedSession(
    String sessionId,
    String grade,
    String taskId,
    String? expectedUid,
  ) async* {
    await _mutations.call('initializeAttendance', {
      'sessionId': sessionId,
      'grade': grade,
      'taskId': taskId,
    }, expectedUid: expectedUid);
    yield* watchGradeSession(sessionId: sessionId, grade: grade);
  }

  @override
  Stream<List<AttendanceSessionModel>> watchGradeAttendance({
    required String grade,
    DateTime? from,
    DateTime? to,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collectionGroup('grades')
        .where('grade', isEqualTo: grade);
    if (from != null) {
      query = query.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(
          DateTime.utc(from.year, from.month, from.day),
        ),
      );
    }
    if (to != null) {
      query = query.where(
        'date',
        isLessThan: Timestamp.fromDate(
          DateTime.utc(to.year, to.month, to.day + 1),
        ),
      );
    }
    final primary = query
        .orderBy('date', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map<List<AttendanceSessionModel>>(
          (snap) => SnapshotList<AttendanceSessionModel>.fromSnapshot(
            snap,
            (doc) => AttendanceSessionModel.fromMap(
              doc.data(),
              doc.data()['sessionId'] as String? ??
                  doc.reference.parent.parent!.id,
            ),
          ),
        );
    return _withAttendanceFallback(
      primary,
      () => _fallbackGradeAttendanceStream(grade: grade, from: from, to: to),
    );
  }

  Stream<List<AttendanceSessionModel>> _fallbackGradeAttendanceStream({
    required String grade,
    DateTime? from,
    DateTime? to,
  }) {
    final fromDay = from != null
        ? DateTime.utc(from.year, from.month, from.day)
        : null;
    final toDayExclusive = to != null
        ? DateTime.utc(to.year, to.month, to.day + 1)
        : null;
    return _firestore
        .collection(AppConstants.colAttendance)
        .snapshots(includeMetadataChanges: true)
        .map<List<AttendanceSessionModel>>((snap) {
          final items = snap.docs
              .map((doc) => AttendanceSessionModel.fromMap(doc.data(), doc.id))
              .where((s) {
                if (s.grade != grade && s.grade != 'all') return false;
                final parsed = DateTime.tryParse(s.date);
                if (parsed == null) return true;
                final utcDay = DateTime.utc(
                  parsed.year,
                  parsed.month,
                  parsed.day,
                );
                if (fromDay != null && utcDay.isBefore(fromDay)) return false;
                if (toDayExclusive != null && !utcDay.isBefore(toDayExclusive)) {
                  return false;
                }
                return true;
              })
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          return SnapshotList<AttendanceSessionModel>(
            items,
            isFromCache: snap.metadata.isFromCache,
            hasPendingWrites: snap.metadata.hasPendingWrites,
          );
        })
        .handleError(
          (Object e, StackTrace st) => throw AppFailure.fromException(e, st),
        );
  }

  Stream<List<AttendanceSessionModel>> _withAttendanceFallback(
    Stream<List<AttendanceSessionModel>> primary,
    Stream<List<AttendanceSessionModel>> Function() fallbackFactory,
  ) {
    late StreamController<List<AttendanceSessionModel>> controller;
    StreamSubscription<List<AttendanceSessionModel>>? sub;
    controller = StreamController<List<AttendanceSessionModel>>.broadcast(
      onListen: () {
        sub = primary.listen(
          controller.add,
          onError: (Object e, StackTrace st) {
            if (e is FirebaseException &&
                (e.code == 'failed-precondition' ||
                    e.code == 'permission-denied')) {
              sub?.cancel();
              sub = fallbackFactory().listen(
                controller.add,
                onError: controller.addError,
                onDone: controller.close,
              );
            } else {
              controller.addError(AppFailure.fromException(e, st), st);
            }
          },
          onDone: controller.close,
        );
      },
      onCancel: () => sub?.cancel(),
    );
    return controller.stream;
  }

  @override
  Future<void> setPresence({
    required String sessionId,
    required String grade,
    required String makhdomId,
    required bool isPresent,
    required String date,
    required String type,
    required String khademId,
    required String khademName,
    String? taskId,
    String? operationId,
    bool onlyOwnMark = false,
  }) async {
    await _mutations.call('setAttendancePresence', {
      'expectedUid': khademId,
      'khademName': khademName,
      'sessionId': sessionId,
      'grade': grade,
      'makhdomId': makhdomId,
      'isPresent': isPresent,
      'onlyOwnMark': onlyOwnMark,
      'date': date,
      'type': type,
      if (taskId != null) 'taskId': taskId,
      'operationId': operationId ?? newOperationId('presence'),
    });
  }

  @override
  Future<void> setExcuse({
    required String sessionId,
    required String grade,
    required String makhdomId,
    required String? note,
    required String date,
    required String type,
    required String khademId,
    required String khademName,
    String? operationId,
  }) async {
    await _mutations.call('setAttendanceExcuse', {
      'expectedUid': khademId,
      'khademName': khademName,
      'sessionId': sessionId,
      'grade': grade,
      'makhdomId': makhdomId,
      'note': note?.trim() ?? '',
      'date': date,
      'type': type,
      'operationId': operationId ?? newOperationId('excuse'),
    });
  }

  @override
  Future<bool> acquireSessionLock({
    required String sessionId,
    required String grade,
    required String khademId,
    required String khademName,
    bool force = false,
  }) async {
    if (_providedFirestore == null && Firebase.apps.isEmpty) {
      return true;
    }
    try {
      final now = DateTime.now();
      final expiresAt = Timestamp.fromDate(now.add(lockLeaseDuration));
      final grades = grade == 'all' ? ['1st', '2nd', '3rd'] : [grade];
      final targetGrade = grades.first;
      final partRef = _firestore
          .collection(AppConstants.colAttendance)
          .doc(sessionId)
          .collection('grades')
          .doc(targetGrade);

      if (!force) {
        final snap = await partRef
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 3));
        if (snap.exists && snap.data() != null) {
          final currentSession = AttendanceSessionModel.fromMap(
            snap.data()!,
            sessionId,
          );
          if (currentSession.isLockedByOther(khademId, now: now)) {
            return false;
          }
        }
      }

      final lockPayload = <String, dynamic>{
        'sessionId': sessionId,
        'lockedByKhademId': khademId,
        'lockedByKhademName': khademName,
        'lockExpiresAt': expiresAt,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      for (final g in grades) {
        await _firestore
            .collection(AppConstants.colAttendance)
            .doc(sessionId)
            .collection('grades')
            .doc(g)
            .set({...lockPayload, 'grade': g}, SetOptions(merge: true));
      }
      await _firestore
          .collection(AppConstants.colAttendance)
          .doc(sessionId)
          .set({...lockPayload, 'grade': grade}, SetOptions(merge: true));
      return true;
    } catch (_) {
      // When offline, allow local editing; CRDT per-servant/per-channel merge
      // reconciles all changes into a single unified version upon reconnect.
      return true;
    }
  }

  @override
  Future<void> releaseSessionLock({
    required String sessionId,
    required String grade,
    required String khademId,
    bool force = false,
  }) async {
    if (_providedFirestore == null && Firebase.apps.isEmpty) {
      return;
    }
    try {
      final grades = grade == 'all' ? ['1st', '2nd', '3rd'] : [grade];
      final targetGrade = grades.first;
      final partRef = _firestore
          .collection(AppConstants.colAttendance)
          .doc(sessionId)
          .collection('grades')
          .doc(targetGrade);

      if (!force) {
        final snap = await partRef.get().timeout(const Duration(seconds: 2));
        final holder = snap.data()?['lockedByKhademId']?.toString();
        if (holder != null && holder.isNotEmpty && holder != khademId) {
          return;
        }
      }

      final unlockPayload = <String, dynamic>{
        'lockedByKhademId': FieldValue.delete(),
        'lockedByKhademName': FieldValue.delete(),
        'lockExpiresAt': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      for (final g in grades) {
        await _firestore
            .collection(AppConstants.colAttendance)
            .doc(sessionId)
            .collection('grades')
            .doc(g)
            .set(unlockPayload, SetOptions(merge: true));
      }
      await _firestore
          .collection(AppConstants.colAttendance)
          .doc(sessionId)
          .set(unlockPayload, SetOptions(merge: true));
    } catch (_) {
      // Ignore network errors on exit; the 45s TTL lease expires automatically.
    }
  }

  @override
  Future<void> finalizeAttendance({
    required String sessionId,
    required String grade,
    String? taskId,
  }) async {
    await _mutations.call('finalizeAttendance', {
      'sessionId': sessionId,
      'grade': grade,
      if (taskId != null) 'taskId': taskId,
    });
  }

  @override
  Future<void> reopenAttendance({
    required String sessionId,
    required String grade,
    required String reason,
    required String operationId,
  }) async {
    await _mutations.call('reopenAttendance', {
      'sessionId': sessionId,
      'grade': grade,
      'reason': reason,
      'operationId': operationId,
    });
  }
}
