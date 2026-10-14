import 'package:efteqad/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../services/trusted_mutations.dart' show canonicalVisitType;

import '../models/service_model.dart';

class DomainLabels {
  final Locale locale;

  const DomainLabels(this.locale);

  GeneratedAppLocalizations get tr => lookupGeneratedAppLocalizations(locale);

  bool get isArabic => locale.languageCode == 'ar';

  String gradeName(String? grade, [List<ServiceGrade>? serviceGrades]) {
    if (serviceGrades != null && grade != null) {
      final match = serviceGrades.where((g) => g.id == grade).firstOrNull;
      if (match != null && match.name.isNotEmpty) return match.name;
    }
    switch (grade) {
      case AppConstants.grade1st:
        return tr.message1stSecondary;
      case AppConstants.grade2nd:
        return tr.message2ndSecondary;
      case AppConstants.grade3rd:
        return tr.message3rdSecondary;
      case 'all':
        return tr.messageAllGrades;
      default:
        if (grade != null && grade.startsWith('grade_')) {
          final numStr = grade.replaceFirst('grade_', '');
          final order = int.tryParse(numStr);
          if (order != null) {
            final ordinals = isArabic
                ? const [
                    'الصف الأول',
                    'الصف الثاني',
                    'الصف الثالث',
                    'الصف الرابع',
                    'الصف الخامس',
                    'الصف السادس',
                    'الصف السابع',
                    'الصف الثامن',
                  ]
                : const [
                    '1st Grade',
                    '2nd Grade',
                    '3rd Grade',
                    '4th Grade',
                    '5th Grade',
                    '6th Grade',
                    '7th Grade',
                    '8th Grade',
                  ];
            if (order >= 1 && order <= ordinals.length) {
              return ordinals[order - 1];
            }
            return isArabic ? 'الصف $order' : 'Grade $order';
          }
        }
        return (grade != null && grade.isNotEmpty) ? grade : tr.messageSecondary;
    }
  }

  String gradeShort(String? grade) {
    switch (grade) {
      case AppConstants.grade1st:
        return tr.message1st;
      case AppConstants.grade2nd:
        return tr.message2nd;
      case AppConstants.grade3rd:
        return tr.message3rd;
      default:
        if (grade != null && grade.startsWith('grade_')) {
          final numStr = grade.replaceFirst('grade_', '');
          final order = int.tryParse(numStr);
          if (order != null) {
            final ordinals = isArabic
                ? const ['أولى', 'ثانية', 'ثالثة', 'رابعة', 'خامسة', 'سادسة']
                : const ['1st', '2nd', '3rd', '4th', '5th', '6th'];
            if (order >= 1 && order <= ordinals.length) {
              return ordinals[order - 1];
            }
            return '$order';
          }
        }
        return grade ?? '';
    }
  }

  String roleName(String? role) {
    switch (role) {
      case AppConstants.roleStageAdmin:
        return tr.messageStageAdministrator;
      case AppConstants.roleGradeAdmin:
        return tr.messageGradeAdministrator;
      case AppConstants.roleServant:
        return tr.messageServant;
      case AppConstants.rolePending:
        return tr.messagePending;
      default:
        return tr.messageServant;
    }
  }

  String taskTypeName(String? type) {
    switch (type) {
      case 'attendance':
      case AppConstants.taskTypeAttendanceKhedma:
        return tr.messageServiceAttendance;
      case AppConstants.taskTypeAttendanceQoddas:
        return tr.messageMassAttendance;
      case 'visitation':
      case 'visit':
        return tr.messageVisitationTask;
      default:
        return tr.messageGeneralTask;
    }
  }

  String secondaryTypeCode(String type) {
    switch (type) {
      case 'ثانوية عامة':
      case 'General':
      case 'General secondary':
        return 'general';
      case 'صنايع / فني':
      case 'Technical / vocational':
        return 'technical';
      case 'خدمات':
      case 'Services':
        return 'services';
      case 'تجاري':
      case 'Commercial':
        return 'commercial';
      case 'أخرى':
      case 'Other':
        return 'other';
      default:
        return type;
    }
  }

  String secondaryTypeName(String type, {String? customLabel}) {
    final label = customLabel?.trim().isNotEmpty == true ? customLabel : null;
    switch (secondaryTypeCode(type)) {
      case 'general':
      case 'ثانوية عامة':
        return tr.secondaryGeneral;
      case 'technical':
      case 'صنايع / فني':
        return tr.secondaryTechnical;
      case 'services':
      case 'خدمات':
        return tr.secondaryService;
      case 'commercial':
      case 'تجاري':
        return tr.secondaryCommercial;
      case 'other':
      case 'أخرى':
        return label ?? tr.secondaryOther;
      case 'custom':
        return label ?? tr.notSpecified;
      default:
        return label ?? type;
    }
  }

  String visitTypeName(String? type) {
    switch (type == null ? null : canonicalVisitType(type)) {
      case 'home':
      case 'منزلية':
      case 'زيارة منزلية':
        return tr.messageHomeVisit;
      case 'phone':
      case 'تليفونية':
      case 'مكالمة هاتفية':
        return tr.messagePhoneCall;
      case 'church':
      case 'كنيسة':
      case 'لقاء بالكنيسة':
        return tr.messageChurchMeetup;
      case 'other':
      case 'أخرى':
      case 'اخرى':
        return tr.messageOther;
      default:
        return type ?? (tr.messageVisit);
    }
  }
}
