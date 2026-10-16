import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/widgets/query_content.dart';
import 'add_task_dialog.dart';
import 'delete_task_dialog.dart';
import 'task_card.dart';
import 'tasks_empty_view.dart';
import 'tasks_filter_bar.dart';

class TasksTab extends StatefulWidget {
  final Stream<List<TaskModel>> tasksStream;
  final Stream<List<TaskModel>> Function()? tasksQuery;
  final List<KhademModel> availableKhodam;
  final String grade; // '1st', '2nd', '3rd', or 'all'
  final bool canCreateTasks;
  final String? serviceId;

  const TasksTab({
    super.key,
    required this.tasksStream,
    this.tasksQuery,
    required this.availableKhodam,
    required this.grade,
    this.canCreateTasks = true,
    this.serviceId,
  });

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  final FirestoreService _firestoreService = FirestoreService();
  String _filter = 'all'; // 'all', 'pending', 'completed'

  void _openAddTaskDialog() {
    showDialog(
      context: context,
      builder: (_) => AddTaskDialog(
        availableKhodam: widget.availableKhodam,
        grade: widget.grade,
        serviceId: widget.serviceId,
      ),
    );
  }

  Future<void> _handleDeleteTask(TaskModel task) async {
    final bool? confirm = await DeleteTaskDialog.show(context);
    if (confirm == true) {
      await _firestoreService.deleteTask(task.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return QueryContent<List<TaskModel>>(
      queryKey: 'tasks/${widget.grade}',
      query: widget.tasksQuery ?? () => widget.tasksStream,
      builder: (context, allTasks) {
        final filteredTasks = allTasks.where((t) {
          if (_filter == 'pending') return !t.isCompleted;
          if (_filter == 'completed') return t.isCompleted;
          return true;
        }).toList();

        final completedCount = allTasks.where((t) => t.isCompleted).length;
        final pendingCount = allTasks.length - completedCount;

        return Column(
          children: [
            TasksFilterBar(
              currentFilter: _filter,
              totalCount: allTasks.length,
              pendingCount: pendingCount,
              completedCount: completedCount,
              canCreateTasks: widget.canCreateTasks,
              hasKhodam: widget.availableKhodam.isNotEmpty,
              onFilterSelected: (val) => setState(() => _filter = val),
              onAddTask: _openAddTaskDialog,
              isDark: isDark,
            ),
            const Divider(height: 1),
            Expanded(
              child: filteredTasks.isEmpty
                  ? TasksEmptyView(isDark: isDark)
                  : ListView.builder(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        16.w,
                        12.h,
                        16.w,
                        85.h,
                      ),
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];
                        return TaskCard(
                          task: task,
                          isDark: isDark,
                          canDelete: widget.canCreateTasks,
                          onToggleStatus: (val) =>
                              _firestoreService.toggleTaskStatus(task.id, val),
                          onDelete: () => _handleDeleteTask(task),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
