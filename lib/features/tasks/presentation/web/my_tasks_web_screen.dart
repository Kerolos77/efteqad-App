import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/widgets/web/web_widgets.dart';
import '../widgets/web_task_details_dialog.dart';
import '../widgets/web_tasks_controls_bar.dart';
import '../widgets/web_tasks_data_table.dart';
import '../widgets/web_tasks_empty_state.dart';
import '../widgets/web_tasks_grid_view.dart';
import '../widgets/web_tasks_kanban_view.dart';
import '../widgets/web_tasks_kpi_bar.dart';

enum TasksViewMode { kanban, grid, table }

class MyTasksWebScreen extends StatefulWidget {
  final List<TaskModel> tasks;

  const MyTasksWebScreen({
    super.key,
    required this.tasks,
  });

  @override
  State<MyTasksWebScreen> createState() => _MyTasksWebScreenState();
}

class _MyTasksWebScreenState extends State<MyTasksWebScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _statusFilter = 'all'; // all, pending, completed, overdue
  String _typeFilter = 'all'; // all, attendance, visitation, general
  TasksViewMode _viewMode = TasksViewMode.grid;
  final Set<String> _togglingTaskIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleTaskStatus(TaskModel task) async {
    if (_togglingTaskIds.contains(task.id)) return;
    setState(() => _togglingTaskIds.add(task.id));
    try {
      await _firestoreService.toggleTaskStatus(task.id, !task.isCompleted);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر تحديث حالة المهمة: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _togglingTaskIds.remove(task.id));
      }
    }
  }

  void _openTaskDetails(TaskModel task) {
    showDialog(
      context: context,
      builder: (ctx) => WebTaskDetailsDialog(
        task: task,
        onToggleStatus: () {
          Navigator.pop(ctx);
          _toggleTaskStatus(task);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 1. Calculate Analytics
    final totalCount = widget.tasks.length;
    final completedCount = widget.tasks.where((t) => t.isCompleted).length;
    final pendingCount = totalCount - completedCount;
    final overdueCount = widget.tasks.where((t) {
      if (t.isCompleted || t.dueDate == null) return false;
      final due = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return due.isBefore(today);
    }).length;
    final completionRate = totalCount > 0 ? (completedCount / totalCount) : 0.0;

    // 2. Filter Tasks
    final filteredList = widget.tasks.where((t) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matches = t.title.toLowerCase().contains(q) ||
            t.description.toLowerCase().contains(q) ||
            t.createdByName.toLowerCase().contains(q);
        if (!matches) return false;
      }

      // Type filter
      if (_typeFilter != 'all') {
        if (_typeFilter == 'attendance' && !t.isAttendanceTask) return false;
        if (_typeFilter == 'visitation' && t.type != 'visitation') return false;
        if (_typeFilter == 'general' && t.type != 'general') return false;
      }

      // Status filter
      if (_statusFilter == 'pending' && t.isCompleted) return false;
      if (_statusFilter == 'completed' && !t.isCompleted) return false;
      if (_statusFilter == 'overdue') {
        if (t.isCompleted || t.dueDate == null) return false;
        final due = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
        if (!due.isBefore(today)) return false;
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Page Header
            WebPageHeader(
              title: context.tr.myTasksTitle,
              description:
                  'متابعة وإنجاز التكليفات الموجهة إليك من أمين المرحلة وأمين الأسرة',
              actions: [
                SegmentedButton<TasksViewMode>(
                  segments: [
                    ButtonSegment(
                      value: TasksViewMode.grid,
                      icon: Icon(Icons.grid_view_rounded, size: 18.sp),
                      label: const Text('بطاقات'),
                    ),
                    ButtonSegment(
                      value: TasksViewMode.kanban,
                      icon: Icon(Icons.view_column_rounded, size: 18.sp),
                      label: const Text('أعمدة'),
                    ),
                    ButtonSegment(
                      value: TasksViewMode.table,
                      icon: Icon(Icons.table_rows_rounded, size: 18.sp),
                      label: const Text('جدول'),
                    ),
                  ],
                  selected: {_viewMode},
                  onSelectionChanged: (val) {
                    setState(() => _viewMode = val.first);
                  },
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // KPI Summary Cards
            WebTasksKpiBar(
              totalCount: totalCount,
              completedCount: completedCount,
              pendingCount: pendingCount,
              overdueCount: overdueCount,
              completionRate: completionRate,
              onStatusFilterSelected: (filter) {
                setState(() => _statusFilter = filter);
              },
              isDark: isDark,
            ),
            SizedBox(height: 20.h),

            // Toolbar: Search & Filters
            WebTasksControlsBar(
              searchController: _searchController,
              searchQuery: _searchQuery,
              typeFilter: _typeFilter,
              statusFilter: _statusFilter,
              totalCount: totalCount,
              pendingCount: pendingCount,
              completedCount: completedCount,
              overdueCount: overdueCount,
              onSearchChanged: (val) =>
                  setState(() => _searchQuery = val.trim()),
              onClearSearch: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              onTypeFilterChanged: (val) => setState(() => _typeFilter = val),
              onStatusFilterChanged: (val) =>
                  setState(() => _statusFilter = val),
              isDark: isDark,
            ),
            SizedBox(height: 20.h),

            // Tasks Content
            if (filteredList.isEmpty)
              WebTasksEmptyState(isDark: isDark)
            else if (_viewMode == TasksViewMode.kanban)
              WebTasksKanbanView(
                tasks: filteredList,
                isDark: isDark,
                today: today,
                togglingTaskIds: _togglingTaskIds,
                onToggleTaskStatus: _toggleTaskStatus,
                onOpenTaskDetails: _openTaskDetails,
              )
            else if (_viewMode == TasksViewMode.grid)
              WebTasksGridView(
                tasks: filteredList,
                isDark: isDark,
                today: today,
                togglingTaskIds: _togglingTaskIds,
                onToggleTaskStatus: _toggleTaskStatus,
                onOpenTaskDetails: _openTaskDetails,
              )
            else
              WebTasksDataTable(
                tasks: filteredList,
                isDark: isDark,
                today: today,
                togglingTaskIds: _togglingTaskIds,
                onToggleTaskStatus: _toggleTaskStatus,
                onOpenTaskDetails: _openTaskDetails,
              ),
          ],
        ),
      ),
    );
  }
}
