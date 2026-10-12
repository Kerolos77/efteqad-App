import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/trusted_mutations.dart';
import '../services/visit_draft_store.dart';
import '../constants/constants.dart';
import '../errors/app_failure.dart';
import '../models/page_result.dart';
import '../models/snapshot_list.dart';
import '../utils/calendar_dates.dart';
import '../models/visit_model.dart';

abstract class VisitRepository {
  Stream<List<VisitModel>> watchVisitsForMakhdom(String makhdomId);
  Future<PageResult<VisitModel>> fetchVisitPage({
    required String makhdomId,
    DocumentSnapshot? cursor,
    int limit = 50,
    DateTime? from,
    DateTime? to,
  });
  Future<String> recordVisit({required VisitModel visit, String? operationId});
  Future<void> updateVisitNotes({
    required String visitId,
    required String makhdomId,
    required String notes,
  });
}

class FirestoreVisitRepository implements VisitRepository {
  final FirebaseFirestore? _providedFirestore;
  FirebaseFirestore get _firestore =>
      _providedFirestore ?? FirebaseFirestore.instance;
  final TrustedMutations _mutations;
  final VisitDraftStore _drafts;
  final String Function() _userId;

  FirestoreVisitRepository({
    FirebaseFirestore? firestore,
    TrustedMutations? mutations,
    VisitDraftStore? drafts,
    String Function()? userId,
  }) : _providedFirestore = firestore,
       _mutations = mutations ?? TrustedMutations(),
       _drafts = drafts ?? VisitDraftStore(),
       _userId = userId ?? (() => FirebaseAuth.instance.currentUser?.uid ?? '');

  @override
  Stream<List<VisitModel>> watchVisitsForMakhdom(String makhdomId) {
    return _firestore
        .collection(AppConstants.colVisits)
        .where('makhdomId', isEqualTo: makhdomId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => VisitModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) {
            final dateComp = b.visitDate.compareTo(a.visitDate);
            if (dateComp != 0) return dateComp;
            final createdComp = b.createdAt.compareTo(a.createdAt);
            if (createdComp != 0) return createdComp;
            return b.id.compareTo(a.id);
          });
          return list;
        });
  }

  @override
  Future<String> recordVisit({
    required VisitModel visit,
    String? operationId,
  }) async {
    final uid = _userId();
    if (uid.isEmpty) throw StateError('Authentication required.');
    void checkIdentity() {
      if (_userId() != uid) {
        throw StateError(
          'The initiating account changed. Resume the visit as its owner.',
        );
      }
    }

    final saved = (await _drafts.getDrafts(
      uid,
    )).where((d) => d['makhdomId'] == visit.makhdomId).firstOrNull;
    final op =
        operationId ??
        saved?['operationId'] as String? ??
        newOperationId('visit');
    final payload = <String, dynamic>{
      'makhdomId': visit.makhdomId,
      'visitDate': visit.visitDate.toIso8601String(),
      'visitType': canonicalVisitType(visit.visitType),
      'notes': visit.notes,
      'operationId': op,
    };
    final submitted = saved?['submittedPayload'];
    if (submitted is Map && jsonEncode(submitted) != jsonEncode(payload)) {
      await _drafts.saveDraft(uid, {...saved!, 'editedDraft': payload});
      throw StateError(
        'Resolve the original submitted visit before saving changed fields. New edits remain in the local draft.',
      );
    }
    await _drafts.saveDraft(uid, {
      'id': visit.makhdomId,
      ...payload,
      'submittedPayload': payload,
      if (saved?['editedDraft'] != null) 'editedDraft': saved!['editedDraft'],
    });
    checkIdentity();
    final result = await _mutations.call(
      'recordVisit',
      payload,
      expectedUid: uid,
    );
    checkIdentity();
    if (saved?['editedDraft'] != null) {
      await _drafts.saveDraft(uid, {
        ...saved!,
        'resolvedVisitId': result['visitId'],
      });
      throw StateError(
        'Original visit confirmed; newer draft is retained for review and was not saved under that receipt.',
      );
    }
    await _drafts.removeDraft(uid, visit.makhdomId);
    checkIdentity();
    return result['visitId'] as String;
  }

  @override
  Future<void> updateVisitNotes({
    required String visitId,
    required String makhdomId,
    required String notes,
  }) async {
    await _mutations.call('updateVisitNotes', {
      'visitId': visitId,
      'notes': notes.trim(),
    });
  }

  @override
  Future<PageResult<VisitModel>> fetchVisitPage({
    required String makhdomId,
    DocumentSnapshot? cursor,
    int limit = 50,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection(AppConstants.colVisits)
          .where('makhdomId', isEqualTo: makhdomId)
          .orderBy('visitDate', descending: true)
          .orderBy('createdAt', descending: true)
          .orderBy(FieldPath.documentId, descending: true)
          .limit(limit);

      if (from != null) {
        query = query.where(
          'visitDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(calendarDay(from)),
        );
      }
      if (to != null) {
        query = query.where(
          'visitDate',
          isLessThan: Timestamp.fromDate(calendarDay(to, 1)),
        );
      }
      if (cursor != null) {
        query = query.startAfterDocument(cursor);
      }

      try {
        final snap = await query.get();
        final items = snap.docs
            .map((doc) => VisitModel.fromMap(doc.data(), doc.id))
            .toList();

        final hasMore = snap.docs.length == limit;
        final newCursor = snap.docs.isNotEmpty ? snap.docs.last : null;

        return PageResult<VisitModel>(
          items: SnapshotList(
            items,
            isFromCache: snap.metadata.isFromCache,
            hasPendingWrites: snap.metadata.hasPendingWrites,
          ),
          cursor: newCursor,
          hasMore: hasMore,
        );
      } on FirebaseException catch (e) {
        if (e.code != 'failed-precondition') rethrow;
        final snap = await _firestore
            .collection(AppConstants.colVisits)
            .where('makhdomId', isEqualTo: makhdomId)
            .get();
        final fromBound = from != null ? calendarDay(from) : null;
        final toBoundExclusive = to != null ? calendarDay(to, 1) : null;
        final entries = snap.docs
            .map(
              (doc) => (
                doc: doc,
                visit: VisitModel.fromMap(doc.data(), doc.id),
              ),
            )
            .where((entry) {
              if (fromBound != null &&
                  entry.visit.visitDate.isBefore(fromBound)) {
                return false;
              }
              if (toBoundExclusive != null &&
                  !entry.visit.visitDate.isBefore(toBoundExclusive)) {
                return false;
              }
              return true;
            })
            .toList()
          ..sort((a, b) {
            final d = b.visit.visitDate.compareTo(a.visit.visitDate);
            if (d != 0) return d;
            final c = b.visit.createdAt.compareTo(a.visit.createdAt);
            if (c != 0) return c;
            return b.visit.id.compareTo(a.visit.id);
          });

        var startIndex = 0;
        if (cursor != null) {
          final idx = entries.indexWhere((e) => e.doc.id == cursor.id);
          if (idx >= 0) startIndex = idx + 1;
        }
        final pageEntries = entries.skip(startIndex).take(limit).toList();
        final items = pageEntries.map((e) => e.visit).toList();
        final hasMore = startIndex + pageEntries.length < entries.length;
        final newCursor = pageEntries.isNotEmpty ? pageEntries.last.doc : null;

        return PageResult<VisitModel>(
          items: SnapshotList(
            items,
            isFromCache: snap.metadata.isFromCache,
            hasPendingWrites: snap.metadata.hasPendingWrites,
          ),
          cursor: newCursor,
          hasMore: hasMore,
        );
      }
    } catch (e, st) {
      throw AppFailure.fromException(e, st);
    }
  }
}
