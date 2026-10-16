import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';

class AttendanceFinalizeDialog extends StatelessWidget {
  const AttendanceFinalizeDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => const AttendanceFinalizeDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.r),
      ),
      title: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppColors.successColor,
            size: 22.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              context.tr.messageFinalizeAttendance,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        context.tr.messageAreYouSureYouWantToFinalize,
        style: TextStyle(
          fontSize: 13.sp,
          color: AppColors.textMuted,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.tr.messageCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.successColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(context.tr.messageConfirmFinalization),
        ),
      ],
    );
  }
}
