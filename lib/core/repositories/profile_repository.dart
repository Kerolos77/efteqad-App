import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/constants.dart';
import '../models/khadem_model.dart';

abstract class ProfileRepository {
  Stream<KhademModel?> watchProfile(String uid);
  Future<KhademModel?> getProfile(String uid);
}

class FirestoreProfileRepository implements ProfileRepository {
  final FirebaseFirestore? _providedFirestore;
  FirebaseFirestore get _firestore =>
      _providedFirestore ?? FirebaseFirestore.instance;

  FirestoreProfileRepository({FirebaseFirestore? firestore})
    : _providedFirestore = firestore;

  bool _isConstAdminUser(String uid) {
    if (_providedFirestore != null) return false;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != uid) return false;
    final email = user.email?.toLowerCase().trim();
    return email != null &&
        email == AppConstants.constAdminEmail.toLowerCase().trim();
  }

  KhademModel _ensureConstAdminModel(
    String uid,
    Map<String, dynamic>? data,
  ) {
    final user = FirebaseAuth.instance.currentUser;
    final map = <String, dynamic>{
      ...?data,
      'email': data?['email'] ?? user?.email ?? AppConstants.constAdminEmail,
      'name': (data?['name']?.toString().trim().isNotEmpty == true)
          ? data!['name']
          : (user?.displayName?.trim().isNotEmpty == true
                ? user!.displayName!.trim()
                : 'أمين المرحلة'),
      'role': AppConstants.roleStageAdmin,
      'status': 'active',
    };
    if (data == null ||
        data['role'] != AppConstants.roleStageAdmin ||
        data['status'] != 'active') {
      unawaited(
        _firestore
            .collection(AppConstants.colKhodam)
            .doc(uid)
            .set({
              'email': map['email'],
              'name': map['name'],
              'phone': data?['phone'] ?? '',
              'role': AppConstants.roleStageAdmin,
              'status': 'active',
              'grade': null,
              if (data?['createdAt'] == null)
                'createdAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true))
            .catchError((_) {}),
      );
    }
    return KhademModel.fromMap(map, uid);
  }

  @override
  Stream<KhademModel?> watchProfile(String uid) {
    return _firestore
        .collection(AppConstants.colKhodam)
        .doc(uid)
        .snapshots()
        .map((doc) {
          if (_isConstAdminUser(uid)) {
            if (doc.data()?['status'] == 'deleting') {
              return KhademModel.fromMap(doc.data()!, doc.id);
            }
            return _ensureConstAdminModel(uid, doc.data());
          }
          return doc.exists && doc.data() != null
              ? KhademModel.fromMap(doc.data()!, doc.id)
              : null;
        });
  }

  @override
  Future<KhademModel?> getProfile(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.colKhodam)
        .doc(uid)
        .get();
    if (_isConstAdminUser(uid)) {
      if (doc.data()?['status'] == 'deleting') {
        return KhademModel.fromMap(doc.data()!, doc.id);
      }
      return _ensureConstAdminModel(uid, doc.data());
    }
    if (!doc.exists || doc.data() == null) return null;
    return KhademModel.fromMap(doc.data()!, doc.id);
  }
}
