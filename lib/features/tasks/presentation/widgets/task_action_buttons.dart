import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';

class TaskActionButtons extends StatelessWidget {
  final bool isAttendanceTask;
  final bool isCompleted;
  final bool isLoading;
  final VoidCallback onOpenAttendance;
  final VoidCallback onToggleCompleted;

  const TaskActionButtons({
    super.key,
    required this.isAttendanceTask,
    required this.isCompleted,
    required this.isLoading,
    required this.onOpenAttendance,
    required this.onToggleCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isAttendanceTask) ...[
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              backgroundColor: AppColors.primaryLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            onPressed: onOpenAttendance,
            icon: Icon(Icons.assignment_turned_in_rounded, size: 20.sp),
            label: Text(
              context.tr.messageOpenAttendanceSheet,
              style: TextStyle(fontSize: 16.sp),
            ),
          ),
          SizedBox(height: 16.h),
        ],
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 14.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            side: BorderSide(
              color: isCompleted ? Colors.green : Colors.grey,
            ),
          ),
          onPressed: isLoading || isAttendanceTask ? null : onToggleCompleted,
          icon: isLoading
              ? SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isCompleted ? Colors.green : null,
                  size: 20.sp,
                ),
          label: Text(
            isCompleted
                ? context.tr.messageCompleted
                : context.tr.messageMarkAsCompleted,
            style: TextStyle(
              color: isCompleted ? Colors.green : null,
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
        ),
      ],
    );
  }
}
