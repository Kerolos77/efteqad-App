import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/localization/app_localizations.dart';

class AttendanceAppBarTitle extends StatelessWidget {
  final String sessionType;
  final String gradeLabel;
  final DateTime dueDate;

  const AttendanceAppBarTitle({
    super.key,
    required this.sessionType,
    required this.gradeLabel,
    required this.dueDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          sessionType == 'qoddas'
              ? context.tr.attendanceScreenTitleMass
              : '${context.tr.attendanceScreenTitleService} ($gradeLabel)',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16.sp,
          ),
        ),
        Text(
          AppFormatters(
            Localizations.localeOf(context),
          ).formatDayAndDate(dueDate),
          style: TextStyle(
            fontSize: 11.sp,
            color: AppColors.textMuted,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
