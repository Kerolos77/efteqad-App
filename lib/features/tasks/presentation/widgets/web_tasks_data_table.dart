import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/web/web_widgets.dart';
import 'web_task_badge.dart';

class WebTasksDataTable extends StatelessWidget {
  final List<TaskModel> tasks;
  final bool isDark;
  final DateTime today;
  final Set<String> togglingTaskIds;
  final ValueChanged<TaskModel> onToggleTaskStatus;
  final ValueChanged<TaskModel> onOpenTaskDetails;

  const WebTasksDataTable({
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
    return WebCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              isDark ? Colors.white10 : const Color(0xFFF8FAFC),
            ),
            dataRowMinHeight: 64.h,
            dataRowMaxHeight: 72.h,
            columns: const [
              DataColumn(
                label: Text(
                  'الحالة',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'نوع المهمة',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'عنوان المهمة',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'تاريخ الاستحقاق',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'المشرف',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'الإجراءات',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: tasks.map((task) {
              final isToggling = togglingTaskIds.contains(task.id);
              final isOverdue = !task.isCompleted &&
                  task.dueDate != null &&
                  DateTime(
                    task.dueDate!.year,
                    task.dueDate!.month,
                    task.dueDate!.day,
                  ).isBefore(today);

              return DataRow(
                cells: [
                  DataCell(
                    isToggling
                        ? SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Checkbox(
                            value: task.isCompleted,
                            activeColor: AppColors.successColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            onChanged: (_) => onToggleTaskStatus(task),
                          ),
                  ),
                  DataCell(WebTaskTypeBadge(task: task)),
                  DataCell(
                    InkWell(
                      onTap: () => onOpenTaskDetails(task),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5.sp,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color:
                                  task.isCompleted ? AppColors.textMuted : null,
                            ),
                          ),
                          if (task.description.isNotEmpty)
                            Text(
                              task.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    WebTaskDueDateBadge(
                      task: task,
                      today: today,
                      isOverdue: isOverdue,
                    ),
                  ),
                  DataCell(
                    Text(
                      task.createdByName.isNotEmpty
                          ? task.createdByName
                          : 'الإدارة',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (task.isAttendanceTask)
                          FilledButton.tonalIcon(
                            icon: Icon(Icons.how_to_reg_rounded, size: 16.sp),
                            label: const Text('رصد الحضور'),
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.h,
                              ),
                            ),
                            onPressed: () => context.push(
                              AppRoutes.taskAttendance(task.id),
                            ),
                          )
                        else
                          IconButton(
                            icon: Icon(Icons.info_outline_rounded, size: 18.sp),
                            tooltip: 'تفاصيل المهمة',
                            onPressed: () => onOpenTaskDetails(task),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
