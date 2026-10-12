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
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  /// تعيين خادم كأمين لسنة دراسية معينة (بواسطة أمين المرحلة)
  Future<void> setGradeAdmin({
    required String khademId,
    required String grade,
  }) async {
    if (_providedFunctions != null) {
      final callable = _providedFunctions.httpsCallable('setGradeAdmin');
      await callable.call<Map<String, dynamic>>({
        'khademId': khademId,
        'grade': grade,
      });
      return;
    }
    final firestore = FirebaseFirestore.instance;
    final currentAdmins = await firestore
        .collection(AppConstants.colKhodam)
        .where('grade', isEqualTo: grade)
        .where('role', isEqualTo: AppConstants.roleGradeAdmin)
        .get();
    final batch = firestore.batch();
    for (final doc in currentAdmins.docs) {
      if (doc.id != khademId) {
        batch.update(doc.reference, {
          'role': AppConstants.roleServant,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
    batch.update(
      firestore.collection(AppConstants.colKhodam).doc(khademId),
      {
        'grade': grade,
        'role': AppConstants.roleGradeAdmin,
        'status': 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
    await batch.commit();
  }
}
