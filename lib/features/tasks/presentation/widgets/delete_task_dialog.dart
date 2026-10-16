import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';

class DeleteTaskDialog extends StatelessWidget {
  const DeleteTaskDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => const DeleteTaskDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      title: Row(
        children: [
          Icon(
            Icons.delete_outline_rounded,
            color: AppColors.errorColor,
            size: 22.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              context.tr.deleteMakhdomTitle,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        context.tr.deleteTaskPrompt,
        style: TextStyle(
          fontSize: 13.sp,
          color: AppColors.textMuted,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.tr.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.errorColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            context.tr.delete,
            style: TextStyle(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
