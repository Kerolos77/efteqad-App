import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/localization/domain_labels.dart';
import '../../../../core/models/task_model.dart';

class WebTaskTypeBadge extends StatelessWidget {
  final TaskModel task;

  const WebTaskTypeBadge({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final domainLabels = DomainLabels(Localizations.localeOf(context));
    Color color;
    IconData icon;
    switch (task.type) {
      case 'attendance_qoddas':
        color = AppColors.accentGold;
        icon = Icons.church_rounded;
        break;
      case 'attendance':
      case 'attendance_khedma':
        color = const Color(0xFF8B5CF6);
        icon = Icons.fact_check_outlined;
        break;
      case 'visitation':
        color = const Color(0xFF10B981);
        icon = Icons.home_work_outlined;
        break;
      case 'general':
      default:
        color = AppColors.primaryLight;
        icon = Icons.task_alt_outlined;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            domainLabels.taskTypeName(task.type),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class WebTaskDueDateBadge extends StatelessWidget {
  final TaskModel task;
  final DateTime today;
  final bool isOverdue;

  const WebTaskDueDateBadge({
    super.key,
    required this.task,
    required this.today,
    required this.isOverdue,
  });

  @override
  Widget build(BuildContext context) {
    if (task.dueDate == null) {
      return const SizedBox.shrink();
    }

    final formatters = AppFormatters(Localizations.localeOf(context));
    final due = DateTime(
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
    );
    final isToday = due.isAtSameMomentAs(today);

    Color bg;
    Color fg;
    String label;

    if (task.isCompleted) {
      bg = Colors.grey.withValues(alpha: 0.12);
      fg = Colors.grey;
      label = formatters.formatDate(task.dueDate!);
    } else if (isOverdue) {
      bg = AppColors.errorColor.withValues(alpha: 0.12);
      fg = AppColors.errorColor;
      final diff = today.difference(due).inDays;
      label = 'متأخرة ($diff يوم)';
    } else if (isToday) {
      bg = AppColors.warningColor.withValues(alpha: 0.15);
      fg = AppColors.warningColor;
      label = 'اليوم';
    } else {
      bg = AppColors.primaryLight.withValues(alpha: 0.1);
      fg = AppColors.primaryLight;
      label = formatters.formatDate(task.dueDate!);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_rounded, size: 11.sp, color: fg),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5.sp,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
