import 'package:efteqad/core/constants/constants.dart';
import 'package:efteqad/core/localization/app_localizations.dart';
import 'package:efteqad/core/models/khadem_model.dart';
import 'package:efteqad/core/models/service_model.dart';
import 'package:efteqad/features/admin/presentation/widgets/pending_khadem_card.dart';
import 'package:efteqad/features/admin/presentation/widgets/rejected_khadem_card.dart';
import 'package:efteqad/features/admin/presentation/widgets/stage_people_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createTestWidget({
    required List<KhademModel> allKhodam,
    required List<KhademModel> pendingKhodam,
    ServiceModel? service,
  }) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ar'),
        home: Scaffold(
          body: StagePeopleTab(
            allKhodam: allKhodam,
            pendingKhodam: pendingKhodam,
            allMakhdomeen: const [],
            service: service,
          ),
        ),
      ),
    );
  }

  final activeServant = KhademModel(
    id: 'k1',
    name: 'بيشوي عادل رمزي',
    phone: '01011112222',
    email: 'bishoy@test.com',
    role: AppConstants.roleServant,
    grade: AppConstants.grade1st,
    status: 'active',
    createdAt: DateTime.now(),
  );

  final pendingServant = KhademModel(
    id: 'k2',
    name: 'مينا سمير فايز',
    phone: '01233334444',
    email: 'mina@test.com',
    role: AppConstants.rolePending,
    status: 'pending',
    createdAt: DateTime.now(),
  );

  final rejectedServant = KhademModel(
    id: 'k3',
    name: 'جورج ماجد كامل',
    phone: '01155556666',
    email: 'george@test.com',
    role: AppConstants.rolePending,
    status: 'rejected',
    rejectionReason: 'يرجى اختيار المرحلة الإعدادية',
    createdAt: DateTime.now(),
  );

  testWidgets('StagePeopleTab switches between active, pending, and rejected tabs', (tester) async {
    await tester.pumpWidget(
      createTestWidget(
        allKhodam: [activeServant, pendingServant, rejectedServant],
        pendingKhodam: [pendingServant],
      ),
    );
    await tester.pumpAndSettle();

    // Verify Tab headers exist
    expect(find.text('الموافق عليهم'), findsOneWidget);
    expect(find.text('قيد الانتظار'), findsOneWidget);
    expect(find.text('المرفوضين'), findsOneWidget);

    // Active tab is selected by default
    expect(find.text('بيشوي عادل رمزي'), findsOneWidget);
    expect(find.byType(PendingKhademCard), findsNothing);
    expect(find.byType(RejectedKhademCard), findsNothing);

    // Switch to Pending tab
    await tester.tap(find.text('قيد الانتظار'));
    await tester.pumpAndSettle();

    expect(find.byType(PendingKhademCard), findsOneWidget);
    expect(find.text('مينا سمير فايز'), findsOneWidget);
    expect(find.text('رفض'), findsOneWidget);

    // Switch to Rejected tab
    await tester.tap(find.text('المرفوضين'));
    await tester.pumpAndSettle();

    expect(find.byType(RejectedKhademCard), findsOneWidget);
    expect(find.text('جورج ماجد كامل'), findsOneWidget);
    expect(find.textContaining('يرجى اختيار المرحلة الإعدادية'), findsOneWidget);
    expect(find.text('استعادة للانتظار'), findsOneWidget);
  });

  testWidgets('Pending servant card reject button opens reject dialog', (tester) async {
    await tester.pumpWidget(
      createTestWidget(
        allKhodam: [pendingServant],
        pendingKhodam: [pendingServant],
      ),
    );
    await tester.pumpAndSettle();

    // Go to pending tab
    await tester.tap(find.text('قيد الانتظار'));
    await tester.pumpAndSettle();

    // Tap reject button
    await tester.tap(find.text('رفض'));
    await tester.pumpAndSettle();

    // Verify dialog opened
    expect(find.text('رفض طلب الانضمام'), findsOneWidget);
    expect(find.text('تأكيد الرفض'), findsOneWidget);
  });
}
