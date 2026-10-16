import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../constants/constants.dart';
import '../errors/app_failure.dart';
import '../models/task_model.dart';
import '../models/makhdom_model.dart';
import '../models/makhdom_profile_patch.dart';

typedef CallableTransport =
    Future<Map<String, dynamic>> Function(
      String name,
      Map<String, dynamic> payload,
    );
String newOperationId(String kind) =>
    '${kind}_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(0x7fffffff)}';

class PartialAssignmentFailure implements Exception {
  final int assignedCount;
  final List<Map<String, dynamic>> failures;
  const PartialAssignmentFailure(this.assignedCount, this.failures);
  List<String> get failedIds =>
      failures.map((r) => (r['id'] ?? r['makhdomId']).toString()).toList();
  @override
  String toString() =>
      '$assignedCount assignments saved; ${failures.map((r) => "${r['id'] ?? r['makhdomId']}: ${r['status']}").join(', ')}';
}

class TrustedMutations {
  final CallableTransport _transport;
  final String Function()? _userId;
  String? captureIdentity() {
    final uid = _userId?.call();
    if (uid != null && uid.isEmpty) {
      throw StateError('Authentication required.');
    }
    return uid;
  }

  void checkIdentity(String? uid) {
    if (uid != null && _userId != null && _userId() != uid) {
      throw StateError(
        'The initiating account changed. Resume with that account.',
      );
    }
  }

  TrustedMutations({
    CallableTransport? transport,
    FirebaseFunctions? functions,
    String Function()? userId,
  }) : _userId =
           userId ??
           (transport == null
               ? (() =>
                     (functions == null
                             ? FirebaseAuth.instance
                             : FirebaseAuth.instanceFor(app: functions.app))
                         .currentUser
                         ?.uid ??
                     '')
               : null),
       _transport =
           transport ??
           (functions != null
               ? ((name, payload) async {
                   final result = await functions
                       .httpsCallable(name)
                       .call<Map<dynamic, dynamic>>(payload);
                   return Map<String, dynamic>.from(result.data);
                 })
               : _executeDirectFirestore);

  static Future<void> _recalculateAssignedCount(
    FirebaseFirestore firestore,
    String khademId,
  ) async {
    try {
      final snap = await firestore
          .collection(AppConstants.colMakhdomeen)
          .where('assignedKhademId', isEqualTo: khademId)
          .get();
      final activeCount = snap.docs
          .where((d) => d.data()['active'] != false)
          .length;
      await firestore.collection(AppConstants.colKhodam).doc(khademId).update({
        'assignedCount': activeCount,
      });
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> _executeDirectFirestore(
    String name,
    Map<String, dynamic> payload,
  ) async {
    final firestore = FirebaseFirestore.instance;
    switch (name) {
      case 'saveMakhdomProfile':
        final id = payload['makhdomId'] as String?;
        final patch = Map<String, dynamic>.from(payload['patch'] as Map? ?? {});
        final docRef = (id != null && id.isNotEmpty)
            ? firestore.collection(AppConstants.colMakhdomeen).doc(id)
            : firestore.collection(AppConstants.colMakhdomeen).doc();
        final data = <String, dynamic>{};
        for (final entry in patch.entries) {
          final k = entry.key;
          final v = entry.value;
          if (v == null) {
            if (id != null && id.isNotEmpty) {
              data[k] = FieldValue.delete();
              if (k == 'notes') data['description'] = FieldValue.delete();
            }
          } else if ((k == 'birthDate' || k == 'trackingStartDate') &&
              v is String) {
            final parsed = DateTime.tryParse(v);
            if (parsed != null) data[k] = Timestamp.fromDate(parsed);
          } else {
            data[k] = v;
            if (k == 'notes') data['description'] = v;
          }
        }
        data['updatedAt'] = FieldValue.serverTimestamp();
        if (id == null || id.isEmpty) {
          data['active'] = true;
          data['visitCount'] = 0;
          data['createdAt'] = FieldValue.serverTimestamp();
          await docRef.set(data);
        } else {
          await docRef.set(data, SetOptions(merge: true));
        }
        try {
          await firestore.collection('attendance_roster').doc(docRef.id).set({
            'id': docRef.id,
            if (patch['fullName'] != null) 'fullName': patch['fullName'],
            if (patch['grade'] != null) 'grade': patch['grade'],
            'active': true,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (_) {}
        return {'success': true, 'makhdomId': docRef.id};

      case 'importRows':
        final importId = (payload['importId'] ?? 'import').toString();
        final grade = (payload['grade'] ?? AppConstants.grade1st).toString();
        final rows = (payload['rows'] as List? ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        final batch = firestore.batch();
        var imported = 0;
        for (var i = 0; i < rows.length; i++) {
          final row = rows[i];
          final docId = '${importId}_$i'.replaceAll('/', '_');
          final docRef = firestore
              .collection(AppConstants.colMakhdomeen)
              .doc(docId);
          final data = <String, dynamic>{
            'fullName': row['fullName'] ?? '',
            'phone': row['phone'] ?? '',
            'fatherPhone': row['fatherPhone'] ?? '',
            'motherPhone': row['motherPhone'] ?? '',
            'address': row['address'] ?? '',
            'area': row['area'] ?? '',
            'school': row['school'] ?? '',
            'secondaryType': row['secondaryType'] ?? '',
            if (row['secondaryTypeCustomLabel'] != null)
              'secondaryTypeCustomLabel': row['secondaryTypeCustomLabel'],
            'grade': grade,
            if (row['serviceId'] != null) 'serviceId': row['serviceId'],
            if (row['classId'] != null) 'classId': row['classId'],
            if (row['className'] != null) 'className': row['className'],
            'homeLocationUrl': row['homeLocationUrl'],
            'isBrethrenOfLord': row['isBrethrenOfLord'] == true,
            'photoUrl': row['photoUrl'],
            'notes': row['notes'],
            'description': row['notes'],
            'active': true,
            'visitCount': 0,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };
          if (row['birthDate'] is String) {
            final dt = DateTime.tryParse(row['birthDate'] as String);
            if (dt != null) data['birthDate'] = Timestamp.fromDate(dt);
          }
          if (row['trackingStartDate'] is String) {
            final dt = DateTime.tryParse(row['trackingStartDate'] as String);
            if (dt != null) data['trackingStartDate'] = Timestamp.fromDate(dt);
          }
          batch.set(docRef, data, SetOptions(merge: true));
          imported++;
        }
        await batch.commit();
        return {
          'success': true,
          'imported': imported,
          'rejectedDetails': <Map<String, dynamic>>[],
        };

      case 'createTask':
        final taskData = Map<String, dynamic>.from(
          payload['taskData'] as Map? ?? {},
        );
        final uid =
            (payload['expectedUid'] ??
                    FirebaseAuth.instance.currentUser?.uid ??
                    'admin')
                .toString();
        final assignedKhademId = (taskData['assignedKhademId'] ?? '')
            .toString();
        var assignedKhademName = '';
        var createdByName =
            FirebaseAuth.instance.currentUser?.displayName ?? 'أمين الخدمة';
        try {
          if (assignedKhademId.isNotEmpty) {
            final assigneeSnap = await firestore
                .collection(AppConstants.colKhodam)
                .doc(assignedKhademId)
                .get();
            assignedKhademName = (assigneeSnap.data()?['name'] ?? '')
                .toString();
          }
          final creatorSnap = await firestore
              .collection(AppConstants.colKhodam)
              .doc(uid)
              .get();
          final cName = creatorSnap.data()?['name']?.toString();
          if (cName != null && cName.isNotEmpty) createdByName = cName;
        } catch (_) {}

        final taskRef = firestore.collection(AppConstants.colTasks).doc();
        Timestamp? dueTimestamp;
        if (taskData['dueDate'] != null) {
          final parsed = DateTime.tryParse(taskData['dueDate'].toString());
          if (parsed != null) dueTimestamp = Timestamp.fromDate(parsed);
        }
        final title = (taskData['title'] ?? '').toString();
        final description = (taskData['description'] ?? '').toString();
        final type = (taskData['type'] ?? AppConstants.taskTypeGeneral)
            .toString();
        final grade = (taskData['grade'] ?? 'all').toString();
        final serviceId = (taskData['serviceId'] ?? 'thanawy').toString();

        await taskRef.set({
          'title': title,
          'description': description,
          'assignedKhademId': assignedKhademId,
          'assignedKhademName': assignedKhademName,
          'grade': grade,
          'serviceId': serviceId,
          'createdById': uid,
          'createdByName': createdByName,
          'type': type,
          'dueDate': dueTimestamp,
          'isCompleted': false,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (assignedKhademId.isNotEmpty) {
          try {
            await firestore.collection(AppConstants.colNotifications).add({
              'recipientId': assignedKhademId,
              'title': 'مهمة جديدة: $title 📋',
              'body': description.isNotEmpty
                  ? description
                  : 'قام $createdByName بتكليفك بمهمة جديدة',
              'type': type,
              'taskId': taskRef.id,
              'grade': grade,
              'isRead': false,
              'createdAt': FieldValue.serverTimestamp(),
            });
          } catch (_) {}
        }
        return {'success': true, 'taskId': taskRef.id};

      case 'deleteTask':
        final taskId = (payload['taskId'] ?? '').toString();
        if (taskId.isNotEmpty) {
          await firestore.collection(AppConstants.colTasks).doc(taskId).delete();
        }
        return {'success': true};

      case 'archiveMakhdom':
        final makhdomId = (payload['makhdomId'] ?? '').toString();
        if (makhdomId.isNotEmpty) {
          final mRef = firestore
              .collection(AppConstants.colMakhdomeen)
              .doc(makhdomId);
          final mSnap = await mRef.get();
          final oldKhademId = mSnap.data()?['assignedKhademId']?.toString();
          await mRef.update({
            'active': false,
            'assignedKhademId': null,
            'assignedKhademName': null,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          if (oldKhademId != null && oldKhademId.isNotEmpty) {
            await _recalculateAssignedCount(firestore, oldKhademId);
          }
          try {
            await firestore.collection('attendance_roster').doc(makhdomId).set({
              'active': false,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          } catch (_) {}
        }
        return {'success': true};

      case 'assignMakhdoms':
        final ids = (payload['ids'] as List? ?? const [])
            .map((e) => e.toString())
            .toList();
        final targetKhademId = payload['targetKhademId']?.toString();
        String? targetKhademName;
        if (targetKhademId != null && targetKhademId.isNotEmpty) {
          final kSnap = await firestore
              .collection(AppConstants.colKhodam)
              .doc(targetKhademId)
              .get();
          targetKhademName = kSnap.data()?['name']?.toString();
        }
        final affectedKhodam = <String>{
          if (targetKhademId != null && targetKhademId.isNotEmpty)
            targetKhademId,
        };
        final batch = firestore.batch();
        final results = <Map<String, dynamic>>[];
        for (final id in ids) {
          final mRef = firestore.collection(AppConstants.colMakhdomeen).doc(id);
          final mSnap = await mRef.get();
          final prevKhademId = mSnap.data()?['assignedKhademId']?.toString();
          if (prevKhademId != null && prevKhademId.isNotEmpty) {
            affectedKhodam.add(prevKhademId);
          }
          batch.update(mRef, {
            'assignedKhademId':
                (targetKhademId != null && targetKhademId.isNotEmpty)
                ? targetKhademId
                : null,
            'assignedKhademName':
                (targetKhademId != null && targetKhademId.isNotEmpty)
                ? (targetKhademName ?? '')
                : null,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          results.add({'id': id, 'status': 'assigned'});
        }
        await batch.commit();
        for (final kId in affectedKhodam) {
          await _recalculateAssignedCount(firestore, kId);
        }
        return {
          'success': true,
          'assignedCount': ids.length,
          'results': results,
        };

      case 'recordVisit':
        final makhdomId = (payload['makhdomId'] ?? '').toString();
        final uid =
            (payload['expectedUid'] ??
                    FirebaseAuth.instance.currentUser?.uid ??
                    '')
                .toString();
        final visitDate =
            DateTime.tryParse(payload['visitDate']?.toString() ?? '') ??
            DateTime.now();
        final visitType = (payload['visitType'] ?? 'home').toString();
        final notes = payload['notes']?.toString().trim();

        final mRef = firestore
            .collection(AppConstants.colMakhdomeen)
            .doc(makhdomId);
        final mSnap = await mRef.get();
        final mData = mSnap.data() ?? {};
        final makhdomName = (mData['fullName'] ?? '').toString();
        final grade = (mData['grade'] ?? AppConstants.grade1st).toString();
        final serviceId = (payload['serviceId'] ?? mData['serviceId'] ?? 'thanawy').toString();

        var khademName = FirebaseAuth.instance.currentUser?.displayName ?? '';
        if (uid.isNotEmpty) {
          final kSnap = await firestore
              .collection(AppConstants.colKhodam)
              .doc(uid)
              .get();
          final kName = kSnap.data()?['name']?.toString();
          if (kName != null && kName.isNotEmpty) khademName = kName;
        }

        final visitDoc = firestore.collection(AppConstants.colVisits).doc();
        DateTime? currentLastVisitDate;
        final rawDate = mData['lastVisitDate'];
        if (rawDate is Timestamp) currentLastVisitDate = rawDate.toDate();

        final isNewest =
            currentLastVisitDate == null ||
            !visitDate.isBefore(currentLastVisitDate);
        final makhdomUpdates = <String, dynamic>{
          'visitCount': FieldValue.increment(1),
        };
        if (isNewest) {
          makhdomUpdates['lastVisitDate'] = Timestamp.fromDate(visitDate);
          makhdomUpdates['lastVisitId'] = visitDoc.id;
          if (notes != null && notes.isNotEmpty) {
            makhdomUpdates['lastVisitNotes'] = notes;
          }
        }

        final visitBatch = firestore.batch();
        visitBatch.set(visitDoc, {
          'makhdomId': makhdomId,
          'makhdomName': makhdomName,
          'grade': grade,
          'serviceId': serviceId,
          'khademId': uid,
          'khademName': khademName,
          'visitDate': Timestamp.fromDate(visitDate),
          'visitType': visitType,
          'notes': (notes != null && notes.isNotEmpty) ? notes : null,
          'description': (notes != null && notes.isNotEmpty) ? notes : null,
          'createdAt': FieldValue.serverTimestamp(),
        });
        visitBatch.update(mRef, makhdomUpdates);
        await visitBatch.commit();
        return {'success': true, 'visitId': visitDoc.id};

      case 'updateVisitNotes':
        final visitId = (payload['visitId'] ?? '').toString();
        final cleanNotes = (payload['notes'] ?? '').toString().trim();
        final visitRef = firestore
            .collection(AppConstants.colVisits)
            .doc(visitId);
        final visitSnap = await visitRef.get();
        if (visitSnap.exists) {
          await visitRef.update({
            'notes': cleanNotes.isNotEmpty ? cleanNotes : null,
            'description': cleanNotes.isNotEmpty ? cleanNotes : null,
          });
          final makhdomId = visitSnap.data()?['makhdomId']?.toString();
          if (makhdomId != null && makhdomId.isNotEmpty) {
            final mRef = firestore
                .collection(AppConstants.colMakhdomeen)
                .doc(makhdomId);
            final mSnap = await mRef.get();
            if (mSnap.data()?['lastVisitId'] == visitId) {
              await mRef.update({
                'lastVisitNotes': cleanNotes.isNotEmpty
                    ? cleanNotes
                    : FieldValue.delete(),
              });
            }
          }
        }
        return {'success': true};

      case 'initializeAttendance':
        final sessionId = (payload['sessionId'] ?? '').toString();
        final grade = (payload['grade'] ?? '1st').toString();
        final parts = sessionId.split('_');
        final dateStr = parts.isNotEmpty ? parts[0] : '';
        final parsedInitDate = DateTime.tryParse(dateStr);
        final dynamic dateVal = parsedInitDate != null
            ? Timestamp.fromDate(
                DateTime.utc(
                  parsedInitDate.year,
                  parsedInitDate.month,
                  parsedInitDate.day,
                ),
              )
            : dateStr;
        final type = parts.length > 1 ? parts[1] : 'khedma';
        final grades = grade == 'all' ? ['1st', '2nd', '3rd'] : [grade];
        for (final g in grades) {
          final ref = firestore
              .collection(AppConstants.colAttendance)
              .doc(sessionId)
              .collection('grades')
              .doc(g);
          final snap = await ref.get();
          if (!snap.exists) {
            await ref.set({
              'sessionId': sessionId,
              'date': dateVal,
              'type': type,
              'grade': g,
              'attendedMakhdomIds': <String>[],
              'status': 'draft',
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
        return {'success': true};

      case 'setAttendancePresence':
        final sessionId = (payload['sessionId'] ?? '').toString();
        final grade = (payload['grade'] ?? '1st').toString();
        final makhdomId = (payload['makhdomId'] ?? '').toString();
        final isPresent = payload['isPresent'] == true;
        final onlyOwnMark = payload['onlyOwnMark'] == true;
        final dateStr = (payload['date'] ?? sessionId.split('_').first)
            .toString();
        final parsedPresDate = DateTime.tryParse(dateStr);
        final dynamic presDateVal = parsedPresDate != null
            ? Timestamp.fromDate(
                DateTime.utc(
                  parsedPresDate.year,
                  parsedPresDate.month,
                  parsedPresDate.day,
                ),
              )
            : dateStr;
        final type = (payload['type'] ?? 'khedma').toString();
        final uid =
            (payload['expectedUid'] ??
                    FirebaseAuth.instance.currentUser?.uid ??
                    '')
                .toString();
        final khademName = (payload['khademName'] ?? '').toString();

        var targetGrade = grade;
        if (grade == 'all') {
          final mSnap = await firestore
              .collection(AppConstants.colMakhdomeen)
              .doc(makhdomId)
              .get();
          targetGrade = (mSnap.data()?['grade'] ?? '1st').toString();
        }

        final partRef = firestore
            .collection(AppConstants.colAttendance)
            .doc(sessionId)
            .collection('grades')
            .doc(targetGrade);
        final topRef = firestore
            .collection(AppConstants.colAttendance)
            .doc(sessionId);
        final change = isPresent
            ? FieldValue.arrayUnion([makhdomId])
            : FieldValue.arrayRemove([makhdomId]);

        final effectiveUid = uid.isEmpty ? 'anonymous' : uid;
        final dynamic presentByUpdate = isPresent
            ? {
                makhdomId: {effectiveUid: true},
              }
            : (onlyOwnMark
                  ? {
                      makhdomId: {effectiveUid: FieldValue.delete()},
                    }
                  : {makhdomId: FieldValue.delete()});

        final dataUpdate = <String, dynamic>{
          'sessionId': sessionId,
          'date': presDateVal,
          'type': type,
          'attendedMakhdomIds': change,
          'presentBy': presentByUpdate,
          'takenByKhademId': uid,
          if (khademName.isNotEmpty) 'takenByKhademName': khademName,
          'status': 'draft',
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await partRef.set({
          ...dataUpdate,
          'grade': targetGrade,
        }, SetOptions(merge: true));

        await topRef.set({
          ...dataUpdate,
          'grade': grade,
        }, SetOptions(merge: true));
        return {'success': true};

      case 'setAttendanceExcuse':
        final sessionId = (payload['sessionId'] ?? '').toString();
        final grade = (payload['grade'] ?? '1st').toString();
        final makhdomId = (payload['makhdomId'] ?? '').toString();
        final cleanNote = (payload['note'] ?? '').toString().trim();
        final dateStr = (payload['date'] ?? sessionId.split('_').first)
            .toString();
        final parsedExcDate = DateTime.tryParse(dateStr);
        final dynamic excDateVal = parsedExcDate != null
            ? Timestamp.fromDate(
                DateTime.utc(
                  parsedExcDate.year,
                  parsedExcDate.month,
                  parsedExcDate.day,
                ),
              )
            : dateStr;
        final type = (payload['type'] ?? 'khedma').toString();
        final uid =
            (payload['expectedUid'] ??
                    FirebaseAuth.instance.currentUser?.uid ??
                    '')
                .toString();
        final khademName = (payload['khademName'] ?? '').toString();

        var targetGrade = grade;
        if (grade == 'all') {
          final mSnap = await firestore
              .collection(AppConstants.colMakhdomeen)
              .doc(makhdomId)
              .get();
          targetGrade = (mSnap.data()?['grade'] ?? '1st').toString();
        }

        final partRef = firestore
            .collection(AppConstants.colAttendance)
            .doc(sessionId)
            .collection('grades')
            .doc(targetGrade);
        final topRef = firestore
            .collection(AppConstants.colAttendance)
            .doc(sessionId);

        final excusePayload = cleanNote.isNotEmpty
            ? {
                'note': cleanNote,
                'byKhademId': uid,
                'byKhademName': khademName,
                'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
              }
            : FieldValue.delete();

        final excuseUpdate = <String, dynamic>{
          'sessionId': sessionId,
          'date': excDateVal,
          'type': type,
          'excuses': {makhdomId: excusePayload},
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await partRef.set({
          ...excuseUpdate,
          'grade': targetGrade,
        }, SetOptions(merge: true));

        await topRef.set({
          ...excuseUpdate,
          'grade': grade,
        }, SetOptions(merge: true));
        return {'success': true};

      case 'finalizeAttendance':
        final sessionId = (payload['sessionId'] ?? '').toString();
        final grade = (payload['grade'] ?? '1st').toString();
        final grades = grade == 'all' ? ['1st', '2nd', '3rd'] : [grade];
        for (final g in grades) {
          await firestore
              .collection(AppConstants.colAttendance)
              .doc(sessionId)
              .collection('grades')
              .doc(g)
              .set({
                'sessionId': sessionId,
                'grade': g,
                'status': 'finalized',
                'finalizedAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        }
        await firestore.collection(AppConstants.colAttendance).doc(sessionId).set(
          {
            'status': 'finalized',
            'finalizedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        return {'success': true};

      case 'reopenAttendance':
        final sessionId = (payload['sessionId'] ?? '').toString();
        final grade = (payload['grade'] ?? '1st').toString();
        final grades = grade == 'all' ? ['1st', '2nd', '3rd'] : [grade];
        for (final g in grades) {
          await firestore
              .collection(AppConstants.colAttendance)
              .doc(sessionId)
              .collection('grades')
              .doc(g)
              .set({
                'status': 'draft',
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        }
        await firestore.collection(AppConstants.colAttendance).doc(sessionId).set(
          {'status': 'draft', 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
        return {'success': true};

      case 'getAttendanceRoster':
        final snap = await firestore
            .collection(AppConstants.colMakhdomeen)
            .get();
        final rows = snap.docs
            .where((d) => d.data()['active'] != false)
            .map(
              (d) => {
                'id': d.id,
                'fullName': (d.data()['fullName'] ?? '').toString(),
                'grade': (d.data()['grade'] ?? '1st').toString(),
                'active': true,
              },
            )
            .toList();
        return {'success': true, 'rows': rows, 'nextCursor': null};

      case 'sendChildAlert':
        final makhdomId = (payload['makhdomId'] ?? '').toString();
        final mSnap = await firestore
            .collection(AppConstants.colMakhdomeen)
            .doc(makhdomId)
            .get();
        final mData = mSnap.data() ?? {};
        final khademId = mData['assignedKhademId']?.toString();
        final fullName = (mData['fullName'] ?? '').toString();
        if (khademId == null || khademId.isEmpty) {
          return {'success': true, 'status': 'no_devices'};
        }
        await firestore.collection(AppConstants.colNotifications).add({
          'recipientId': khademId,
          'title': 'تنبيه افتقاد عاجل ⚠️',
          'body': 'المخدوم $fullName يحتاج إلى متابعة وافتقاد عاجل.',
          'type': 'makhdom_history',
          'makhdomId': makhdomId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return {'success': true, 'status': 'sent'};

      case 'requestAccountDeletion':
        final uid =
            (payload['expectedUid'] ??
                    FirebaseAuth.instance.currentUser?.uid ??
                    '')
                .toString();
        if (uid.isNotEmpty) {
          final assigned = await firestore
              .collection(AppConstants.colMakhdomeen)
              .where('assignedKhademId', isEqualTo: uid)
              .get();
          final batch = firestore.batch();
          for (final doc in assigned.docs) {
            batch.update(doc.reference, {
              'assignedKhademId': null,
              'assignedKhademName': null,
            });
          }
          batch.delete(firestore.collection(AppConstants.colKhodam).doc(uid));
          await batch.commit();
        }
        return {'success': true, 'authDeleted': false};

      default:
        return {'success': true};
    }
  }
  Future<Map<String, dynamic>> call(
    String name,
    Map<String, dynamic> payload, {
    String? expectedUid,
  }) async {
    final uid =
        expectedUid ?? payload['expectedUid'] as String? ?? captureIdentity();
    checkIdentity(uid);
    try {
      final result = await _transport(name, {
        ...payload,
        if (uid != null) 'expectedUid': uid,
      });
      checkIdentity(uid);
      if (result['success'] == false) {
        throw StateError(result['error']?.toString() ?? 'Operation failed');
      }
      return result;
    } catch (e, st) {
      throw AppFailure.fromException(e, st);
    }
  }

    Future<String> createTask(TaskModel task, String operationId) async =>
      (await call('createTask', {
            'operationId': operationId,
            'taskData': {
              'title': task.title,
              'description': task.description,
              'assignedKhademId': task.assignedKhademId,
              'grade': task.grade,
              'type': task.type,
              if (task.serviceId.isNotEmpty && task.serviceId != 'thanawy')
                'serviceId': task.serviceId,
              if (task.dueDate != null)
                'dueDate': task.dueDate!.toIso8601String(),
            },
          }))['taskId']
          as String;
  static Map<String, dynamic> profileFields(MakhdomModel m) => {
    'fullName': m.fullName,
    'phone': m.phone,
    'fatherPhone': m.fatherPhone,
    'motherPhone': m.motherPhone,
    'address': m.address,
    'area': m.area,
    'school': m.school,
    'secondaryType': m.secondaryType,
    'secondaryTypeCustomLabel': m.secondaryTypeCustomLabel,
    'grade': m.grade,
    'serviceId': m.serviceId,
    if (m.classId != null) 'classId': m.classId,
    if (m.className != null) 'className': m.className,
    'homeLocationUrl': m.homeLocationUrl,
    'isBrethrenOfLord': m.isBrethrenOfLord,
    'photoUrl': m.photoUrl,
    'birthDate': m.birthDate?.toIso8601String(),
    'notes': m.notes,
    if (m.trackingStartDate != null && !m.isTrackingEstimated)
      'trackingStartDate': m.trackingStartDate!.toIso8601String(),
  };
  static Map<String, dynamic> patchFields(MakhdomProfilePatch p) {
    if (p.active != null) {
      throw ArgumentError('Use archiveMakhdom for protected active state.');
    }
    return {
      if (p.fullName != null) 'fullName': p.fullName,
      if (p.phone != null) 'phone': p.phone,
      if (p.fatherPhone != null) 'fatherPhone': p.fatherPhone,
      if (p.motherPhone != null) 'motherPhone': p.motherPhone,
      if (p.address != null) 'address': p.address,
      if (p.area != null) 'area': p.area,
      if (p.school != null) 'school': p.school,
      if (p.secondaryType != null) 'secondaryType': p.secondaryType,
      if (p.clearSecondaryTypeCustomLabel || p.secondaryTypeCustomLabel != null)
        'secondaryTypeCustomLabel': p.clearSecondaryTypeCustomLabel
            ? null
            : p.secondaryTypeCustomLabel,
      if (p.clearTrackingStartDate || p.trackingStartDate != null)
        'trackingStartDate': p.clearTrackingStartDate
            ? null
            : p.trackingStartDate!.toIso8601String(),
      if (p.grade != null) 'grade': p.grade,
      if (p.isBrethrenOfLord != null) 'isBrethrenOfLord': p.isBrethrenOfLord,
      if (p.clearPhotoUrl || p.photoUrl != null)
        'photoUrl': p.clearPhotoUrl ? null : p.photoUrl,
      if (p.clearBirthDate || p.birthDate != null)
        'birthDate': p.clearBirthDate ? null : p.birthDate!.toIso8601String(),
      if (p.clearHomeLocationUrl || p.homeLocationUrl != null)
        'homeLocationUrl': p.clearHomeLocationUrl ? null : p.homeLocationUrl,
      if (p.clearNotes || p.notes != null)
        'notes': p.clearNotes ? null : p.notes,
    };
  }

  Future<String> saveProfile({
    String? id,
    required Map<String, dynamic> patch,
    String? operationId,
    String? expectedUid,
  }) async =>
      (await call('saveMakhdomProfile', {
            if (id != null) 'makhdomId': id,
            'patch': patch,
            'operationId': operationId ?? newOperationId('profile'),
          }, expectedUid: expectedUid))['makhdomId']
          as String;
  Future<void> assign({
    required List<String> ids,
    String? targetKhademId,
    required Map<String, String?> expectedAssignments,
    String? operationId,
    String? expectedUid,
  }) async {
    final uid = expectedUid ?? captureIdentity();
    checkIdentity(uid);
    if (ids.isEmpty) return;
    final unique = ids.toSet().toList();
    final base = operationId ?? newOperationId('assignment');
    var assigned = 0;
    final failures = <Map<String, dynamic>>[];
    for (var offset = 0; offset < unique.length; offset += 200) {
      final end = offset + 200 < unique.length ? offset + 200 : unique.length;
      final chunk = unique.sublist(offset, end);
      if (chunk.any((id) => !expectedAssignments.containsKey(id))) {
        throw ArgumentError(
          'Every child requires an explicit expected assignment.',
        );
      }
      final result = await call('assignMakhdoms', {
        'ids': chunk,
        'targetKhademId': targetKhademId,
        'expectedAssignments': {
          for (final id in chunk) id: expectedAssignments[id],
        },
        'operationId': '${base}_chunk_${offset ~/ 200}',
      }, expectedUid: uid);
      assigned += (result['assignedCount'] as num?)?.toInt() ?? 0;
      failures.addAll(
        (result['results'] as List)
            .map((r) => Map<String, dynamic>.from(r as Map))
            .where((r) => !['assigned', 'unchanged'].contains(r['status'])),
      );
    }
    if (failures.isNotEmpty) throw PartialAssignmentFailure(assigned, failures);
  }
}

String canonicalVisitType(String value) {
  switch (value
      .trim()
      .replaceFirst(RegExp(r'^[🏠📞⛪💬]\s*', unicode: true), '')
      .toLowerCase()) {
    case 'home':
    case 'منزلية':
    case 'زيارة منزلية':
    case 'زيارة بيت':
    case 'home visit':
      return 'home';
    case 'phone':
    case 'مكالمة تليفونية':
    case 'تليفونية':
    case 'مكالمة':
    case 'مكالمة هاتفية':
    case 'phone call':
      return 'phone';
    case 'church':
    case 'كنيسة':
    case 'church meetup':
    case 'لقاء في الكنيسة':
    case 'لقاء بالكنيسة':
    case 'church meeting':
      return 'church';
    case 'other':
    case 'message / other':
    case 'رسالة / أخرى':
    case 'أخرى':
    case 'اخرى':
      return 'other';
    default:
      return value; // Legacy custom labels remain user text.
  }
}
