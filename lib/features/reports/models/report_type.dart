import 'package:flutter/material.dart';
import '../../../core/session/session_state.dart';

enum ReportCategory {
  visitation,
  attendance,
  alerts,
  demographics,
  special,
}

enum ReportType {
  // 1. الافتقاد
  visitationLog,
  fieldVisitation,
  servantsVisitationStats,

  // 2. الحضور والغياب
  attendanceMatrix,
  attendanceRate,
  serviceVsQoddas,

  // 3. التقصير والإنذار
  repeatedAbsence,
  unvisitedMakhdomeen,
  unassignedMakhdomeen,

  // 4. المناسبات والبيانات
  birthdays,
  servantMakhdomeen,

  // 5. بطاقة أداء الخادم (للأمناء فقط)
  servantPerformanceCard,

  // 6. الحالات الخاصة وإخوة الرب (سري للأمناء فقط)
  brethrenOfLord,
}

extension ReportTypeExtension on ReportType {
  ReportCategory get category {
    switch (this) {
      case ReportType.visitationLog:
      case ReportType.fieldVisitation:
      case ReportType.servantsVisitationStats:
        return ReportCategory.visitation;

      case ReportType.attendanceMatrix:
      case ReportType.attendanceRate:
      case ReportType.serviceVsQoddas:
        return ReportCategory.attendance;

      case ReportType.repeatedAbsence:
      case ReportType.unvisitedMakhdomeen:
      case ReportType.unassignedMakhdomeen:
        return ReportCategory.alerts;

      case ReportType.birthdays:
      case ReportType.servantMakhdomeen:
        return ReportCategory.demographics;

      case ReportType.servantPerformanceCard:
      case ReportType.brethrenOfLord:
        return ReportCategory.special;
    }
  }

  String get title {
    switch (this) {
      case ReportType.visitationLog:
        return 'سجل الافتقادات التفصيلي';
      case ReportType.fieldVisitation:
        return 'كشف الافتقاد الميداني (لوكيشن وملاحظات)';
      case ReportType.servantsVisitationStats:
        return 'إحصائيات إنجاز وافتقاد الخدام';

      case ReportType.attendanceMatrix:
        return 'مصفوفة الحضور والغياب (جدول التواريخ)';
      case ReportType.attendanceRate:
        return 'تقرير نسب المواظبة والالتزام';
      case ReportType.serviceVsQoddas:
        return 'مقارنة حضور الخدمة بالقداس';

      case ReportType.repeatedAbsence:
        return 'تقرير الغياب المتكرر والانقطاع';
      case ReportType.unvisitedMakhdomeen:
        return 'مخدومين بلا افتقاد منذ فترة';
      case ReportType.unassignedMakhdomeen:
        return 'مخدومين غير مسكنين على خادم';

      case ReportType.birthdays:
        return 'كشف أعياد الميلاد';
      case ReportType.servantMakhdomeen:
        return 'كشف مخدومي خادم محدد';

      case ReportType.servantPerformanceCard:
        return 'بطاقة أداء الخادم (تقييم شهري)';
      case ReportType.brethrenOfLord:
        return 'تقرير إخوة الرب والحالات الخاصة (سري)';
    }
  }

  String get description {
    switch (this) {
      case ReportType.visitationLog:
        return 'عرض كافة الزيارات والمكالمات المنفذة خلال فترة معينة مع الملاحظات.';
      case ReportType.fieldVisitation:
        return 'كشف مخصص للنزول الميداني يشمل العناوين وأرقام الهواتف وQR الخريطة.';
      case ReportType.servantsVisitationStats:
        return 'تحليل أداء الخدام في الافتقاد ونسب تغطية مخدوميهم.';

      case ReportType.attendanceMatrix:
        return 'جدول تفصيلي يوضح أيام الحضور والغياب والأعذار لكل مخدوم.';
      case ReportType.attendanceRate:
        return 'ترتيب المخدومين تنازلياً حسب نسبة حضورهم والتزامهم خلال الفترة.';
      case ReportType.serviceVsQoddas:
        return 'مقارنة دقيقة بين الحضور في درس الكتاب/الخدمة وحضور القداس الإلهي.';

      case ReportType.repeatedAbsence:
        return 'حصر المخدومين المنقطعين لأسابيع متتالية دون عذر للتدخل السريع.';
      case ReportType.unvisitedMakhdomeen:
        return 'كشف بالمخدومين الذين لم يتم افتقادهم (زيارة أو اتصال) منذ مدة طويلة.';
      case ReportType.unassignedMakhdomeen:
        return 'قائمة بالمخدومين غير المربوطين بأي خادم لتوزيعهم رعوياً.';

      case ReportType.birthdays:
        return 'المخدومين الذين تصادف أعياد ميلادهم في الشهر أو الأسبوع المحدد.';
      case ReportType.servantMakhdomeen:
        return 'كشف شامل ببيانات المخدومين المخصصين لخادم بعينه مع بيانات الاتصال.';

      case ReportType.servantPerformanceCard:
        return 'صفحة ملخصة لأمين الخدمة أو السنة توضح أداء خادم معين ونشاطه ونسب أولاده.';
      case ReportType.brethrenOfLord:
        return 'تقرير عالي السرية يوضح حالات الدعم والظروف الخاصة (للأمناء فقط).';
    }
  }

  IconData get icon {
    switch (this) {
      case ReportType.visitationLog:
        return Icons.menu_book_rounded;
      case ReportType.fieldVisitation:
        return Icons.explore_outlined;
      case ReportType.servantsVisitationStats:
        return Icons.leaderboard_rounded;

      case ReportType.attendanceMatrix:
        return Icons.table_chart_rounded;
      case ReportType.attendanceRate:
        return Icons.show_chart_rounded;
      case ReportType.serviceVsQoddas:
        return Icons.church_outlined;

      case ReportType.repeatedAbsence:
        return Icons.warning_amber_rounded;
      case ReportType.unvisitedMakhdomeen:
        return Icons.person_off_outlined;
      case ReportType.unassignedMakhdomeen:
        return Icons.person_add_disabled_outlined;

      case ReportType.birthdays:
        return Icons.cake_outlined;
      case ReportType.servantMakhdomeen:
        return Icons.badge_outlined;

      case ReportType.servantPerformanceCard:
        return Icons.assignment_ind_outlined;
      case ReportType.brethrenOfLord:
        return Icons.lock_outline_rounded;
    }
  }

  /// التحقق من صلاحية الوصول للتقرير
  bool isAccessibleBy(SessionState session) {
    if (session.isStageAdmin) return true;

    if (session.isGradeAdmin) {
      // أمين السنة يرى كل شيء ما عدا لو كانت تقارير تقتصر على أمين الخدمة العام
      return true;
    }

    // الخادم العادي (Servant)
    switch (this) {
      case ReportType.servantsVisitationStats:
      case ReportType.servantPerformanceCard:
      case ReportType.brethrenOfLord:
      case ReportType.unassignedMakhdomeen:
        return false;
      default:
        return true;
    }
  }

  /// هل التقرير يحتاج اختيار خادم بعينه؟
  bool get requiresSingleKhadem {
    return this == ReportType.servantPerformanceCard ||
        this == ReportType.servantMakhdomeen;
  }
}

extension ReportCategoryExtension on ReportCategory {
  String get title {
    switch (this) {
      case ReportCategory.visitation:
        return 'تقارير الافتقاد والرعاية';
      case ReportCategory.attendance:
        return 'تقارير الحضور والغياب';
      case ReportCategory.alerts:
        return 'التقصير والإنذار المبكر';
      case ReportCategory.demographics:
        return 'المناسبات والبيانات';
      case ReportCategory.special:
        return 'تقارير إشرافية وخاصة';
    }
  }

  IconData get icon {
    switch (this) {
      case ReportCategory.visitation:
        return Icons.volunteer_activism_outlined;
      case ReportCategory.attendance:
        return Icons.how_to_reg_outlined;
      case ReportCategory.alerts:
        return Icons.notification_important_outlined;
      case ReportCategory.demographics:
        return Icons.people_outline_rounded;
      case ReportCategory.special:
        return Icons.admin_panel_settings_outlined;
    }
  }
}
