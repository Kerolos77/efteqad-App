import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';

class TasksEmptyView extends StatelessWidget {
  final bool isDark;
  final String? message;

  const TasksEmptyView({
    super.key,
    required this.isDark,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt_rounded,
            size: 48.sp,
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
          SizedBox(height: 12.h),
          Text(
            message ?? context.tr.noTasksYet,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
              color: isDark ? Colors.white70 : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
