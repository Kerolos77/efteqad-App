import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';

class SignOutDialog extends StatelessWidget {
  const SignOutDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => const SignOutDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Row(
        children: [
          Icon(Icons.logout_rounded, color: AppColors.errorColor, size: 22.sp),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              context.tr.signOutConfirmTitle,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
            ),
          ),
        ],
      ),
      content: Text(
        context.tr.signOutConfirmMsg,
        style: TextStyle(fontSize: 13.sp),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.tr.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.errorColor),
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            context.tr.signOut,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
