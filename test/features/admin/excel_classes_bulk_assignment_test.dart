import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:excel/excel.dart';
import 'package:efteqad/core/constants/constants.dart';
import 'package:efteqad/core/localization/app_localizations.dart';
import 'package:efteqad/core/localization/excel_column_labels.dart';
import 'package:efteqad/core/models/class_model.dart';
import 'package:efteqad/core/models/makhdom_model.dart';
import 'package:efteqad/core/services/excel_service.dart';
import 'package:efteqad/core/services/firestore_service.dart';
import 'package:efteqad/features/admin/presentation/widgets/class_makhdomeen_dialog.dart';
import 'package:efteqad/features/admin/presentation/widgets/assign_makhdomeen_modal.dart';
import 'package:efteqad/core/models/khadem_model.dart';

class MockFirestoreForClasses extends Fake implements FirestoreService {
  final List<MakhdomModel> students;
  List<String>? lastAssignedIds;
  String? lastAssignedClassId;
  String? lastAssignedClassName;

  MockFirestoreForClasses({required this.students});

  @override
  Stream<List<MakhdomModel>> getMakhdomeenByGradeStream(String grade, {String? serviceId}) {
    return Stream.value(students);
  }

  @override
  Future<void> bulkAssignMakhdomeenToClass({
    required List<String> makhdomIds,
    required String? classId,
    required String? className,
  }) async {
    lastAssignedIds = makhdomIds;
    lastAssignedClassId = classId;
    lastAssignedClassName = className;
  }
}

Widget testableWidget(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (context, _) => MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('Excel Classes & Bulk Assignment Tests', () {
    test('generateTemplateBytes includes studentClass column in both ar and en', () {
      final arLabels = ExcelColumnLabels(const Locale('ar'));
      final arTemplate = Excel.decodeBytes(
        ExcelService.generateTemplateBytes(labels: arLabels),
      );
      final arHeaders = arTemplate.tables[arLabels.templateSheetName]!.rows[0]
          .map((c) => c?.value?.toString())
          .toList();
      expect(arHeaders, contains('الفصل'));

      final enLabels = ExcelColumnLabels(const Locale('en'));
      final enTemplate = Excel.decodeBytes(
        ExcelService.generateTemplateBytes(labels: enLabels),
      );
      final enHeaders = enTemplate.tables[enLabels.templateSheetName]!.rows[0]
          .map((c) => c?.value?.toString())
          .toList();
      expect(enHeaders, contains('Class'));
    });

    test('exportMakhdomeenBytes includes className in exported row', () {
      final labels = ExcelColumnLabels(const Locale('ar'));
      final student = MakhdomModel(
        id: 's1',
        fullName: 'بيشوي يوسف كمال',
        phone: '01012345678',
        grade: '1st',
        className: 'فصل القديس أبانوب',
        createdAt: DateTime(2026),
      );

      final bytes = ExcelService.exportMakhdomeenBytes([student], labels: labels);
      final workbook = Excel.decodeBytes(bytes);
      final sheet = workbook.tables[labels.sheetName]!;

      // Verify header has الفصل
      final headers = sheet.rows[0].map((c) => c?.value?.toString()).toList();
      expect(headers, contains('الفصل'));

      // Verify row contains فصل القديس أبانوب
      final row = sheet.rows[1].map((c) => c?.value?.toString()).toList();
      expect(row, contains('فصل القديس أبانوب'));
    });

    test('parseMakhdomeen correctly extracts className from Excel with Class column', () {
      final excel = Excel.createExcel();
      final sheet = excel['ورقة1'];
      excel.delete('Sheet1');

      sheet.appendRow([
        TextCellValue('الاسم رباعي'),
        TextCellValue('تليفون الطالب'),
        TextCellValue('الفصل'),
      ]);
      sheet.appendRow([
        TextCellValue('مارك عماد نصحي'),
        TextCellValue('01234567890'),
        TextCellValue('فصل مارجرجس'),
      ]);

      final result = ExcelService.parseMakhdomeen(
        excel.encode()!,
        grade: '2nd',
      );

      expect(result.rowErrors, isEmpty);
      expect(result.rows.length, 1);
      expect(result.rows.first.fullName, 'مارك عماد نصحي');
      expect(result.rows.first.phone, '01234567890');
      expect(result.rows.first.grade, '2nd');
      expect(result.rows.first.className, 'فصل مارجرجس');
    });

    test('parseMakhdomeen without Class column sets className to null cleanly', () {
      final excel = Excel.createExcel();
      final sheet = excel['ورقة1'];
      excel.delete('Sheet1');

      sheet.appendRow([
        TextCellValue('الاسم'),
        TextCellValue('الموبايل'),
      ]);
      sheet.appendRow([
        TextCellValue('طوني ميلاد بطرس'),
        TextCellValue('01122334455'),
      ]);

      final result = ExcelService.parseMakhdomeen(
        excel.encode()!,
        grade: '3rd',
      );

      expect(result.rowErrors, isEmpty);
      expect(result.rows.length, 1);
      expect(result.rows.first.fullName, 'طوني ميلاد بطرس');
      expect(result.rows.first.className, isNull);
    });

    testWidgets('ClassMakhdomeenDialog renders students and triggers bulk assignment', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final students = [
        MakhdomModel(
          id: 'm1',
          fullName: 'فادي سمير عزيز',
          phone: '01011111111',
          grade: '1st',
          classId: 'c1',
          className: 'فصل 1',
          createdAt: DateTime(2026),
        ),
        MakhdomModel(
          id: 'm2',
          fullName: 'كيرلس مجدي إبراهيم',
          phone: '01022222222',
          grade: '1st',
          createdAt: DateTime(2026),
        ),
      ];

      final mockService = MockFirestoreForClasses(students: students);
      final classModel = ClassModel(
        id: 'c1',
        name: 'فصل 1',
        serviceId: 'thanawy',
        gradeId: '1st',
        servantIds: ['kh1'],
        servantNames: ['أستاذ جورج'],
        createdAt: DateTime(2026),
      );

      await tester.pumpWidget(
        testableWidget(
          ClassMakhdomeenDialog(
            classModel: classModel,
            gradeTitle: 'أولى ثانوي',
            firestoreService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('مخدومي فصل: فصل 1'), findsOneWidget);
      expect(find.text('فادي سمير عزيز'), findsOneWidget);
      expect(find.text('كيرلس مجدي إبراهيم'), findsOneWidget);

      // Check m2 to add him to this class
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsWidgets);
      await tester.tap(checkboxes.at(1));
      await tester.pumpAndSettle();

      // Tap save
      final saveBtn = find.text('حفظ التسكين');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(mockService.lastAssignedIds, contains('m2'));
      expect(mockService.lastAssignedClassId, 'c1');
      expect(mockService.lastAssignedClassName, 'فصل 1');
    });

    testWidgets('AssignMakhdomeenModal displays class filter chips', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final khadem = KhademModel(
        id: 'k1',
        name: 'الخادم رامي',
        email: 'rami@test.com',
        phone: '01000000000',
        role: AppConstants.roleServant,
        grade: '1st',
        createdAt: DateTime(2026),
      );

      final students = [
        MakhdomModel(
          id: 'm1',
          fullName: 'بيتر هاني',
          phone: '01011111111',
          grade: '1st',
          className: 'فصل أ',
          createdAt: DateTime(2026),
        ),
        MakhdomModel(
          id: 'm2',
          fullName: 'يوسف رفيق',
          phone: '01022222222',
          grade: '1st',
          className: 'فصل ب',
          createdAt: DateTime(2026),
        ),
      ];

      await tester.pumpWidget(
        testableWidget(
          AssignMakhdomeenModal(
            targetKhadem: khadem,
            allMakhdomeen: students,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('كل الفصول (2)'), findsOneWidget);
      expect(find.text('فصل أ (1)'), findsOneWidget);
      expect(find.text('فصل ب (1)'), findsOneWidget);

      // Filter by 'فصل أ'
      await tester.tap(find.text('فصل أ (1)'));
      await tester.pumpAndSettle();

      expect(find.text('بيتر هاني'), findsOneWidget);
      expect(find.text('يوسف رفيق'), findsNothing);
    });
  });
}
