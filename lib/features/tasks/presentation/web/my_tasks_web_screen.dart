import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/domain_labels.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/widgets/web/web_widgets.dart';

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
            backgroundColor: AppConstants.errorColor,
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
      builder: (ctx) => _TaskDetailsWebDialog(
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
    final formatters = AppFormatters(Localizations.localeOf(context));
    final domainLabels = DomainLabels(Localizations.localeOf(context));
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Page Header
            WebPageHeader(
              title: context.tr.myTasksTitle,
              description: 'متابعة وإنجاز التكليفات الموجهة إليك من أمين المرحلة وأمين الأسرة',
              actions: [
                SegmentedButton<TasksViewMode>(
                  segments: const [
                    ButtonSegment(
                      value: TasksViewMode.grid,
                      icon: Icon(Icons.grid_view_rounded, size: 18),
                      label: Text('بطاقات'),
                    ),
                    ButtonSegment(
                      value: TasksViewMode.kanban,
                      icon: Icon(Icons.view_column_rounded, size: 18),
                      label: Text('أعمدة'),
                    ),
                    ButtonSegment(
                      value: TasksViewMode.table,
                      icon: Icon(Icons.table_rows_rounded, size: 18),
                      label: Text('جدول'),
                    ),
                  ],
                  selected: {_viewMode},
                  onSelectionChanged: (val) {
                    setState(() => _viewMode = val.first);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // KPI Summary Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final kpiCards = [
                  _buildStatCard(
                    title: 'إجمالي المهام',
                    value: formatters.formatNumber(totalCount),
                    subtitle: 'نسبة الإنجاز ${(completionRate * 100).toInt()}%',
                    icon: Icons.assignment_outlined,
                    color: AppConstants.primaryLight,
                    isDark: isDark,
                  ),
                  _buildStatCard(
                    title: 'قيد التنفيذ',
                    value: formatters.formatNumber(pendingCount),
                    subtitle: 'مهام مطلوب إنجازها',
                    icon: Icons.hourglass_top_rounded,
                    color: AppConstants.warningColor,
                    isDark: isDark,
                    onTap: () => setState(() => _statusFilter = 'pending'),
                  ),
                  _buildStatCard(
                    title: 'مكتملة',
                    value: formatters.formatNumber(completedCount),
                    subtitle: 'تمت بنجاح',
                    icon: Icons.check_circle_outline_rounded,
                    color: AppConstants.successColor,
                    isDark: isDark,
                    onTap: () => setState(() => _statusFilter = 'completed'),
                  ),
                  _buildStatCard(
                    title: 'متأخرة',
                    value: formatters.formatNumber(overdueCount),
                    subtitle: overdueCount > 0 ? 'تجاوزت موعد الاستحقاق' : 'لا توجد مهام متأخرة',
                    icon: Icons.warning_amber_rounded,
                    color: overdueCount > 0 ? AppConstants.errorColor : Colors.grey,
                    isDark: isDark,
                    isCritical: overdueCount > 0,
                    onTap: overdueCount > 0 ? () => setState(() => _statusFilter = 'overdue') : null,
                  ),
                ];

                if (isWide) {
                  return Row(
                    children: kpiCards
                        .map(
                          (c) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: c,
                            ),
                          ),
                        )
                        .toList(),
                  );
                }

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: kpiCards
                      .map(
                        (c) => SizedBox(
                          width: (constraints.maxWidth - 12) / 2,
                          child: c,
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 20),

            // Toolbar: Search & Filters
            WebCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          decoration: InputDecoration(
                            hintText: 'ابحث في العنوان، الوصف، أو اسم المشرف...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Type dropdown
                      DropdownButtonHideUnderline(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark ? Colors.white24 : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButton<String>(
                            value: _typeFilter,
                            icon: const Icon(Icons.filter_list_rounded, size: 18),
                            isDense: true,
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('جميع الأنواع')),
                              DropdownMenuItem(value: 'attendance', child: Text('حضور وغياب')),
                              DropdownMenuItem(value: 'visitation', child: Text('افتقاد وزيارة')),
                              DropdownMenuItem(value: 'general', child: Text('عام')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _typeFilter = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Status filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'الكل (${widget.tasks.length})', isDark),
                        const SizedBox(width: 8),
                        _buildFilterChip('pending', 'قيد التنفيذ ($pendingCount)', isDark),
                        const SizedBox(width: 8),
                        _buildFilterChip('completed', 'مكتملة ($completedCount)', isDark),
                        const SizedBox(width: 8),
                        _buildFilterChip('overdue', 'متأخرة ($overdueCount)', isDark, isAlert: overdueCount > 0),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tasks Content
            if (filteredList.isEmpty)
              _buildEmptyState(isDark)
            else if (_viewMode == TasksViewMode.kanban)
              _buildKanbanView(filteredList, isDark, formatters, domainLabels, today)
            else if (_viewMode == TasksViewMode.grid)
              _buildGridView(filteredList, isDark, formatters, domainLabels, today)
            else
              _buildTableView(filteredList, isDark, formatters, domainLabels, today),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, bool isDark, {bool isAlert = false}) {
    final isSelected = _statusFilter == key;
    Color activeColor = AppConstants.primaryLight;
    if (isAlert) activeColor = AppConstants.errorColor;

    return InkWell(
      onTap: () => setState(() => _statusFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: isAlert && !isSelected
              ? Border.all(color: AppConstants.errorColor.withValues(alpha: 0.5))
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isAlert
                    ? AppConstants.errorColor
                    : (isDark ? Colors.white70 : AppConstants.textDark)),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    VoidCallback? onTap,
    bool isCritical = false,
  }) {
    return WebCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              if (isCritical)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    'عاجل',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppConstants.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConstants.primaryLight.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                size: 54,
                color: AppConstants.primaryLight,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد مهام تطابق هذا الفلتر',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'أحسنت! جميع التكليفات إما منجزة أو لا توجد مهام حالية.',
              style: TextStyle(fontSize: 13, color: AppConstants.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Grid View
  // ===========================================================================
  Widget _buildGridView(
    List<TaskModel> tasks,
    bool isDark,
    AppFormatters formatters,
    DomainLabels domainLabels,
    DateTime today,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 380).floor().clamp(1, 3);
        final itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: tasks.map((task) {
            return SizedBox(
              width: itemWidth,
              child: _buildTaskCard(task, isDark, formatters, domainLabels, today),
            );
          }).toList(),
        );
      },
    );
  }

  // ===========================================================================
  // Kanban View (Columns: Pending vs Completed)
  // ===========================================================================
  Widget _buildKanbanView(
    List<TaskModel> tasks,
    bool isDark,
    AppFormatters formatters,
    DomainLabels domainLabels,
    DateTime today,
  ) {
    final pending = tasks.where((t) => !t.isCompleted).toList();
    final completed = tasks.where((t) => t.isCompleted).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pending Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildKanbanHeader(
                title: 'قيد التنفيذ',
                count: pending.length,
                color: AppConstants.warningColor,
                icon: Icons.hourglass_top_rounded,
              ),
              const SizedBox(height: 12),
              ...pending.map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTaskCard(task, isDark, formatters, domainLabels, today),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Completed Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildKanbanHeader(
                title: 'مكتملة',
                count: completed.length,
                color: AppConstants.successColor,
                icon: Icons.check_circle_outline_rounded,
              ),
              const SizedBox(height: 12),
              ...completed.map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTaskCard(task, isDark, formatters, domainLabels, today),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Table View
  // ===========================================================================
  Widget _buildTableView(
    List<TaskModel> tasks,
    bool isDark,
    AppFormatters formatters,
    DomainLabels domainLabels,
    DateTime today,
  ) {
    return WebCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              isDark ? Colors.white10 : const Color(0xFFF8FAFC),
            ),
            dataRowMinHeight: 64,
            dataRowMaxHeight: 72,
            columns: const [
              DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('نوع المهمة', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('عنوان المهمة', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('تاريخ الاستحقاق', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('المشرف', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: tasks.map((task) {
              final isToggling = _togglingTaskIds.contains(task.id);
              final isOverdue = !task.isCompleted &&
                  task.dueDate != null &&
                  DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day).isBefore(today);

              return DataRow(
                cells: [
                  DataCell(
                    isToggling
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Checkbox(
                            value: task.isCompleted,
                            activeColor: AppConstants.successColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (_) => _toggleTaskStatus(task),
                          ),
                  ),
                  DataCell(_buildTypeBadge(task, domainLabels)),
                  DataCell(
                    InkWell(
                      onTap: () => _openTaskDetails(task),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                              color: task.isCompleted ? AppConstants.textMuted : null,
                            ),
                          ),
                          if (task.description.isNotEmpty)
                            Text(
                              task.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: AppConstants.textMuted),
                            ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(_buildDueDateBadge(task, formatters, today, isOverdue)),
                  DataCell(
                    Text(
                      task.createdByName.isNotEmpty ? task.createdByName : 'الإدارة',
                      style: const TextStyle(fontSize: 12, color: AppConstants.textMuted),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (task.isAttendanceTask)
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.how_to_reg_rounded, size: 16),
                            label: const Text('رصد الحضور'),
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            ),
                            onPressed: () => context.push(AppRoutes.taskAttendance(task.id)),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.info_outline_rounded, size: 18),
                            tooltip: 'تفاصيل المهمة',
                            onPressed: () => _openTaskDetails(task),
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

  // ===========================================================================
  // Single Task Card Widget (Shared by Grid & Kanban)
  // ===========================================================================
  Widget _buildTaskCard(
    TaskModel task,
    bool isDark,
    AppFormatters formatters,
    DomainLabels domainLabels,
    DateTime today,
  ) {
    final isToggling = _togglingTaskIds.contains(task.id);
    final isOverdue = !task.isCompleted &&
        task.dueDate != null &&
        DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day).isBefore(today);

    return WebCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Type Badge + Due Date Badge
          Row(
            children: [
              _buildTypeBadge(task, domainLabels),
              const Spacer(),
              _buildDueDateBadge(task, formatters, today, isOverdue),
            ],
          ),
          const SizedBox(height: 12),

          // Title & Description
          InkWell(
            onTap: () => _openTaskDetails(task),
            borderRadius: BorderRadius.circular(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted
                        ? AppConstants.textMuted
                        : (isDark ? Colors.white : AppConstants.textDark),
                  ),
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    task.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppConstants.textMutedDark : AppConstants.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Bottom Actions Row
          Row(
            children: [
              // Checkbox Toggle
              if (isToggling)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: Padding(
                    padding: EdgeInsets.all(4.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                Checkbox(
                  value: task.isCompleted,
                  activeColor: AppConstants.successColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  onChanged: (_) => _toggleTaskStatus(task),
                ),
              const SizedBox(width: 4),
              Text(
                task.isCompleted ? 'مكتملة' : 'وضع علامة إنجاز',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: task.isCompleted ? AppConstants.successColor : AppConstants.textMuted,
                ),
              ),

              const Spacer(),

              // Quick Action: Open attendance if attendance task
              if (task.isAttendanceTask)
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.how_to_reg_rounded, size: 15),
                  label: const Text('دفتر الحضور'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => context.push(AppRoutes.taskAttendance(task.id)),
                )
              else
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  tooltip: 'عرض التفاصيل',
                  onPressed: () => _openTaskDetails(task),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(TaskModel task, DomainLabels domainLabels) {
    Color color;
    IconData icon;
    switch (task.type) {
      case 'attendance_qoddas':
        color = AppConstants.accentGold;
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
        color = AppConstants.primaryLight;
        icon = Icons.task_alt_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            domainLabels.taskTypeName(task.type),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDueDateBadge(
    TaskModel task,
    AppFormatters formatters,
    DateTime today,
    bool isOverdue,
  ) {
    if (task.dueDate == null) {
      return const SizedBox.shrink();
    }

    final due = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
    final isToday = due.isAtSameMomentAs(today);

    Color bg;
    Color fg;
    String label;

    if (task.isCompleted) {
      bg = Colors.grey.withValues(alpha: 0.12);
      fg = Colors.grey;
      label = formatters.formatDate(task.dueDate!);
    } else if (isOverdue) {
      bg = AppConstants.errorColor.withValues(alpha: 0.12);
      fg = AppConstants.errorColor;
      final diff = today.difference(due).inDays;
      label = 'متأخرة ($diff يوم)';
    } else if (isToday) {
      bg = AppConstants.warningColor.withValues(alpha: 0.15);
      fg = AppConstants.warningColor;
      label = 'اليوم';
    } else {
      bg = AppConstants.primaryLight.withValues(alpha: 0.1);
      fg = AppConstants.primaryLight;
      label = formatters.formatDate(task.dueDate!);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_rounded, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: fg),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Task Details Dialog for Web
// =============================================================================
class _TaskDetailsWebDialog extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggleStatus;

  const _TaskDetailsWebDialog({
    required this.task,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final formatters = AppFormatters(Localizations.localeOf(context));
    final domainLabels = DomainLabels(Localizations.localeOf(context));

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(
            task.isCompleted ? Icons.check_circle_rounded : Icons.assignment_rounded,
            color: task.isCompleted ? AppConstants.successColor : AppConstants.primaryLight,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              task.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty) ...[
              const Text(
                'التفاصيل والتعليمات:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  task.description,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
              const SizedBox(height: 14),
            ],

            _buildDetailRow('نوع التكليف:', domainLabels.taskTypeName(task.type)),
            if (task.dueDate != null)
              _buildDetailRow('موعد الاستحقاق:', formatters.formatDate(task.dueDate!)),
            _buildDetailRow('المشرف المنشئ:', task.createdByName.isNotEmpty ? task.createdByName : 'الإدارة'),
            _buildDetailRow('الحالة:', task.isCompleted ? 'مكتملة ومُنجزة ✅' : 'قيد التنفيذ ⏳'),
          ],
        ),
      ),
      actions: [
        if (task.isAttendanceTask)
          FilledButton.tonal(
            onPressed: () {
              Navigator.pop(context);
              context.push(AppRoutes.taskAttendance(task.id));
            },
            child: const Text('فتح دفتر الحضور'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: task.isCompleted ? AppConstants.warningColor : AppConstants.successColor,
          ),
          onPressed: onToggleStatus,
          child: Text(task.isCompleted ? 'إعادة إلى قيد التنفيذ' : 'إتمام المهمة'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppConstants.textMuted)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
