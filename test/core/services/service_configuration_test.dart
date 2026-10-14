import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/constants/constants.dart';
import 'package:efteqad/core/localization/domain_labels.dart';
import 'package:efteqad/core/models/service_model.dart';

void main() {
  group('Phase 2 - Dynamic Service and Grade Labels', () {
    test('DomainLabels.gradeName returns standard legacy names for 1st, 2nd, 3rd', () {
      const arLabels = DomainLabels(Locale('ar'));
      expect(arLabels.gradeName(AppConstants.grade1st), contains('أولى ثانوي'));
      expect(arLabels.gradeName(AppConstants.grade2nd), contains('تانية ثانوي'));
      expect(arLabels.gradeName(AppConstants.grade3rd), contains('تالتة ثانوي'));

      const enLabels = DomainLabels(Locale('en'));
      expect(enLabels.gradeName(AppConstants.grade1st), contains('1st'));
    });

    test('DomainLabels.gradeName formats dynamic grades grade_1 to grade_6 automatically', () {
      const arLabels = DomainLabels(Locale('ar'));
      expect(arLabels.gradeName('grade_1'), 'الصف الأول');
      expect(arLabels.gradeName('grade_2'), 'الصف الثاني');
      expect(arLabels.gradeName('grade_3'), 'الصف الثالث');
      expect(arLabels.gradeName('grade_4'), 'الصف الرابع');
      expect(arLabels.gradeName('grade_5'), 'الصف الخامس');
      expect(arLabels.gradeName('grade_6'), 'الصف السادس');

      const enLabels = DomainLabels(Locale('en'));
      expect(enLabels.gradeName('grade_1'), '1st Grade');
      expect(enLabels.gradeName('grade_4'), '4th Grade');
      expect(enLabels.gradeName('grade_6'), '6th Grade');
    });

    test('DomainLabels.gradeName resolves exact custom grade names when serviceGrades are provided', () {
      const arLabels = DomainLabels(Locale('ar'));
      final customGrades = [
        const ServiceGrade(id: 'grade_1', name: 'الصف الأول الابتدائي', order: 1),
        const ServiceGrade(id: 'grade_2', name: 'الصف الثاني الابتدائي', order: 2),
        const ServiceGrade(id: 'grade_3', name: 'الصف الثالث الابتدائي', order: 3),
        const ServiceGrade(id: 'grade_4', name: 'الصف الرابع الابتدائي', order: 4),
        const ServiceGrade(id: 'grade_5', name: 'الصف الخامس الابتدائي', order: 5),
        const ServiceGrade(id: 'grade_6', name: 'الصف السادس الابتدائي', order: 6),
      ];

      expect(arLabels.gradeName('grade_1', customGrades), 'الصف الأول الابتدائي');
      expect(arLabels.gradeName('grade_4', customGrades), 'الصف الرابع الابتدائي');
      expect(arLabels.gradeName('grade_6', customGrades), 'الصف السادس الابتدائي');
    });

    test('DomainLabels.gradeShort formats dynamic grades grade_1 to grade_6', () {
      const arLabels = DomainLabels(Locale('ar'));
      expect(arLabels.gradeShort('grade_1'), 'أولى');
      expect(arLabels.gradeShort('grade_4'), 'رابعة');
      expect(arLabels.gradeShort('grade_6'), 'سادسة');

      const enLabels = DomainLabels(Locale('en'));
      expect(enLabels.gradeShort('grade_1'), '1st');
      expect(enLabels.gradeShort('grade_4'), '4th');
      expect(enLabels.gradeShort('grade_6'), '6th');
    });

    test('ServiceModel serialization and copyWith with custom grades', () {
      final grades = [
        const ServiceGrade(id: 'grade_1', name: 'الصف الأول الابتدائي', order: 1),
        const ServiceGrade(id: 'grade_2', name: 'الصف الثاني الابتدائي', order: 2),
      ];

      final service = ServiceModel(
        id: 'ebtedai',
        name: 'المرحلة الابتدائية',
        gradesCount: 2,
        grades: grades,
        createdAt: DateTime(2026, 1, 1),
      );

      final map = service.toMap();
      expect(map['name'], 'المرحلة الابتدائية');
      expect(map['gradesCount'], 2);
      expect((map['grades'] as List).length, 2);

      final deserialized = ServiceModel.fromMap(map, 'ebtedai');
      expect(deserialized.id, 'ebtedai');
      expect(deserialized.name, 'المرحلة الابتدائية');
      expect(deserialized.grades.length, 2);
      expect(deserialized.grades[0].name, 'الصف الأول الابتدائي');
      expect(deserialized.grades[1].name, 'الصف الثاني الابتدائي');
    });
  });
}
