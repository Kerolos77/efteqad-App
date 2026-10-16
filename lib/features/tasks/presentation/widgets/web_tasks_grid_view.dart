import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/models/task_model.dart';
import 'web_task_card.dart';

class WebTasksGridView extends StatelessWidget {
  final List<TaskModel> tasks;
  final bool isDark;
  final DateTime today;
  final Set<String> togglingTaskIds;
  final void Function(TaskModel) onToggleTaskStatus;
  final void Function(TaskModel) onOpenTaskDetails;

  const WebTasksGridView({
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 380).floor().clamp(1, 3);
        final itemWidth =
            (constraints.maxWidth - (crossAxisCount - 1) * 16.w) / crossAxisCount;

        return Wrap(
          spacing: 16.w,
          runSpacing: 16.h,
          children: tasks.map((task) {
            return SizedBox(
              width: itemWidth,
              child: WebTaskCard(
                task: task,
                isDark: isDark,
                today: today,
                isToggling: togglingTaskIds.contains(task.id),
                onToggleStatus: () => onToggleTaskStatus(task),
                onOpenDetails: () => onOpenTaskDetails(task),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
