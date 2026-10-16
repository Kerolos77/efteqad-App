import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/models/task_model.dart';
import 'web_task_card.dart';

class WebTasksKanbanView extends StatelessWidget {
  final List<TaskModel> tasks;
  final bool isDark;
  final DateTime today;
  final Set<String> togglingTaskIds;
  final void Function(TaskModel) onToggleTaskStatus;
  final void Function(TaskModel) onOpenTaskDetails;

  const WebTasksKanbanView({
    super.key,
    required this.tasks,
    required this.isDark,
    required this.today,
    required this.togglingTaskIds,
    required this.onToggleTaskStatus,
    required this.onOpenTaskDetails,
  });

  @override
  Widget build(BuildContext context) {
    final pending = tasks.where((t) => !t.isCompleted).toList();
    final completed = tasks.where((t) => t.isCompleted).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildKanbanHeader(
                title: 'قيد التنفيذ',
                count: pending.length,
                color: AppColors.warningColor,
                icon: Icons.hourglass_top_rounded,
              ),
              SizedBox(height: 12.h),
              ...pending.map(
                (task) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: WebTaskCard(
                    task: task,
                    isDark: isDark,
                    today: today,
                    isToggling: togglingTaskIds.contains(task.id),
                    onToggleStatus: () => onToggleTaskStatus(task),
                    onOpenDetails: () => onOpenTaskDetails(task),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildKanbanHeader(
                title: 'مكتملة',
                count: completed.length,
                color: AppColors.successColor,
                icon: Icons.check_circle_outline_rounded,
              ),
              SizedBox(height: 12.h),
              ...completed.map(
                (task) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: WebTaskCard(
                    task: task,
                    isDark: isDark,
                    today: today,
                    isToggling: togglingTaskIds.contains(task.id),
                    onToggleStatus: () => onToggleTaskStatus(task),
                    onOpenDetails: () => onOpenTaskDetails(task),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKanbanHeader({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: color),
          SizedBox(width: 8.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
