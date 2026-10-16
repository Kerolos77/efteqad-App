import 'package:flutter/widgets.dart';
import '../../../core/constants/constants.dart';
import '../../../core/localization/app_localizations.dart';

class AttendanceGradeHelper {
  static String getGradeLabel(BuildContext context, String grade) {
    switch (grade) {
      case AppConstants.grade1st:
        return context.tr.grade1stName;
      case AppConstants.grade2nd:
        return context.tr.grade2ndName;
      case AppConstants.grade3rd:
        return context.tr.grade3rdName;
      default:
        return context.tr.messageSecondary;
    }
  }

  static String getGradeShortLabel(BuildContext context, String grade) {
    switch (grade) {
      case AppConstants.grade1st:
        return context.tr.message1st;
      case AppConstants.grade2nd:
        return context.tr.message2nd;
      case AppConstants.grade3rd:
        return context.tr.message3rd;
      default:
        return '';
    }
  }
}
