import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/web/web_widgets.dart';
import 'web_task_badge.dart';

class WebTaskCard extends StatelessWidget {
  final TaskModel task;
  final bool isDark;
  final DateTime today;
  final bool isToggling;
  final VoidCallback onToggleStatus;
  final VoidCallback onOpenDetails;

  const WebTaskCard({
    super.key,
    required this.task,
    required this.isDark,
    required this.today,
    required this.isToggling,
    required this.onToggleStatus,
    required this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = !task.isCompleted &&
        task.dueDate != null &&
        DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        ).isBefore(today);

    return WebCard(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              WebTaskTypeBadge(task: task),
              const Spacer(),
              WebTaskDueDateBadge(
                task: task,
                today: today,
                isOverdue: isOverdue,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          InkWell(
            onTap: onOpenDetails,
            borderRadius: BorderRadius.circular(8.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.bold,
                    decoration:
                        task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted
                        ? AppColors.textMuted
                        : (isDark ? Colors.white : AppColors.textDark),
                  ),
                ),
                if (task.description.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Text(
                    task.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 14.h),
          const Divider(height: 1),
          SizedBox(height: 10.h),
          Row(
            children: [
              if (isToggling)
                SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: Padding(
                    padding: EdgeInsets.all(4.r),
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                Checkbox(
                  value: task.isCompleted,
                  activeColor: AppColors.successColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.r),
                  ),
                  onChanged: (_) => onToggleStatus(),
                ),
              SizedBox(width: 4.w),
              Text(
                task.isCompleted ? 'مكتملة' : 'وضع علامة إنجاز',
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.bold,
                  color: task.isCompleted
                      ? AppColors.successColor
                      : AppColors.textMuted,
                ),
              ),
              const Spacer(),
              if (task.isAttendanceTask)
                FilledButton.tonalIcon(
                  icon: Icon(Icons.how_to_reg_rounded, size: 15.sp),
                  label: const Text('دفتر الحضور'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    textStyle: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () =>
                      context.push(AppRoutes.taskAttendance(task.id)),
                )
              else
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios_rounded, size: 14.sp),
                  tooltip: 'عرض التفاصيل',
                  onPressed: onOpenDetails,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
