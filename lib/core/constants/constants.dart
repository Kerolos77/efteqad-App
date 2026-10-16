import 'firestore_collections.dart';

export '../theme/app_colors.dart';
export 'firestore_collections.dart';

/// ثوابت التطبيق العامة
class AppConstants {
  AppConstants._();

  // معلومات عامة عن التطبيق
  static const String appName = 'الراعي';
  static const String appTagline = '«أَنَا هُوَ الرَّاعِي الصَّالِحُ»';
  static const String appVersion = '1.0.0';
  static const String appDownloadPageUrl =
      'https://kerolos77.github.io/efteqad-App/';
  static const String docAppVersion = 'app_version';

  // مسار شعار التطبيق وخلفية الاسبلاش
  static const String appLogoPath = 'assets/images/logo.png';
  static const String splashScreenBgPath = 'assets/images/splash_screen_bg.png';

  // إيميل الأدمن المعتمد
  static const String constAdminEmail = 'admin@efteqad.com';

  // مجموعات فايرستور (Firestore Collections)
  static const String colMakhdomeen = FirestoreCollections.makhdomeen;
  static const String colKhodam = FirestoreCollections.khodam;
  static const String colVisits = FirestoreCollections.visits;
  static const String colSettings = FirestoreCollections.settings;
  static const String colTasks = FirestoreCollections.tasks;
  static const String colAttendance = FirestoreCollections.attendance;
  static const String colNotifications = FirestoreCollections.notifications;
  static const String colServices = FirestoreCollections.services;
  static const String colClasses = FirestoreCollections.classes;

  // المراحل الدراسية (Grades)
  static const String grade1st = '1st'; // أولى ثانوي
  static const String grade2nd = '2nd'; // ثانية ثانوي
  static const String grade3rd = '3rd'; // ثالثة ثانوي
  static const String gradeAll = 'all'; // مرحلة ثانوي كاملة

  // أنواع المهام (Task Types)
  static const String taskTypeGeneral = 'general';
  static const String taskTypeVisitation = 'visitation';
  static const String taskTypeAttendanceKhedma = 'attendance_khedma'; // حضور الخدمة
  static const String taskTypeAttendanceQoddas = 'attendance_qoddas'; // حضور القداس

  // الأدوار (Roles)
  static const String roleStageAdmin = 'stageAdmin'; // أمين مرحلة ثانوي
  static const String roleGradeAdmin = 'gradeAdmin'; // أمين سنة (1 أو 2 أو 3 ثانوي)
  static const String roleServant = 'servant'; // خادم مسكن في سنة
  static const String rolePending = 'pending'; // خادم جديد في الانتظار
}
