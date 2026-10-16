import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../constants/constants.dart';

class PrivilegedOperationsService {
  final FirebaseFunctions? _providedFunctions;

  PrivilegedOperationsService({FirebaseFunctions? functions})
    : _providedFunctions = functions;

  /// تسكين خادم في سنة دراسية معينة (بواسطة أمين المرحلة)
  Future<void> setKhademGrade({
    required String khademId,
    required String grade,
  }) async {
    if (_providedFunctions != null) {
      final callable = _providedFunctions.httpsCallable('setKhademGrade');
      await callable.call<Map<String, dynamic>>({
        'khademId': khademId,
        'grade': grade,
      });
      return;
    }
    await FirebaseFirestore.instance
        .collection(AppConstants.colKhodam)
        .doc(khademId)
        .update({
          'grade': grade,
          'role': AppConstants.roleServant,
          'status': 'active',
          'rejectionReason': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  /// تعيين خادم كأمين لسنة دراسية معينة (بواسطة أمين المرحلة - يدعم تعدد الأمناء للسنة)
  Future<void> setGradeAdmin({
    required String khademId,
    required String grade,
    String? serviceId,
  }) async {
    if (_providedFunctions != null) {
      final callable = _providedFunctions.httpsCallable('setGradeAdmin');
      await callable.call<Map<String, dynamic>>({
        'khademId': khademId,
        'grade': grade,
        if (serviceId != null) 'serviceId': serviceId,
      });
      return;
    }
    final firestore = FirebaseFirestore.instance;
    await firestore.collection(AppConstants.colKhodam).doc(khademId).update({
      'grade': grade,
      'role': AppConstants.roleGradeAdmin,
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// إلغاء صفة أمين السنة وإعادة الخادم لدور خادم عادي
  Future<void> removeGradeAdmin({
    required String khademId,
  }) async {
    if (_providedFunctions != null) {
      final callable = _providedFunctions.httpsCallable('removeGradeAdmin');
      await callable.call<Map<String, dynamic>>({
        'khademId': khademId,
      });
      return;
    }
    final firestore = FirebaseFirestore.instance;
    await firestore.collection(AppConstants.colKhodam).doc(khademId).update({
      'role': AppConstants.roleServant,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
