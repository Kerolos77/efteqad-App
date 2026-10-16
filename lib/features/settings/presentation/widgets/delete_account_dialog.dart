import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';

class DeleteAccountWarningDialog extends StatelessWidget {
  final bool isStageAdmin;

  const DeleteAccountWarningDialog({
    super.key,
    required this.isStageAdmin,
  });

  static Future<bool?> show(
    BuildContext context, {
    required bool isStageAdmin,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => DeleteAccountWarningDialog(isStageAdmin: isStageAdmin),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppColors.errorColor,
            size: 28.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              context.tr.deleteAccountWarningTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr.deleteAccountWarningPrompt,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            if (isStageAdmin)
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Text(
                  context.tr.stageSuccessorRequired,
                  style: TextStyle(
                    color: AppColors.errorColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5.sp,
                  ),
                ),
              ),
            Text(
              context.tr.deleteAccountPoints,
              style: TextStyle(fontSize: 12.sp, height: 1.4),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.tr.back),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.errorColor,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            context.tr.deleteAccountConfirmBtn,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class ConfirmDeletePasswordDialog extends StatefulWidget {
  final TextEditingController controller;

  const ConfirmDeletePasswordDialog({
    super.key,
    required this.controller,
  });

  static Future<bool?> show(
    BuildContext context, {
    required TextEditingController controller,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmDeletePasswordDialog(controller: controller),
    );
  }

  @override
  State<ConfirmDeletePasswordDialog> createState() =>
      _ConfirmDeletePasswordDialogState();
}

class _ConfirmDeletePasswordDialogState
    extends State<ConfirmDeletePasswordDialog> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text(
        context.tr.messageConfirmPassword,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.tr.messageToDeleteYourAccountPleaseEnterYour,
            style: TextStyle(fontSize: 13.sp),
          ),
          SizedBox(height: 16.h),
          TextField(
            controller: widget.controller,
            obscureText: _obscure,
            autofocus: true,
            decoration: InputDecoration(
              labelText: context.tr.messagePassword,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  size: 20.sp,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.tr.back),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.errorColor,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            context.tr.messageProceed,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
