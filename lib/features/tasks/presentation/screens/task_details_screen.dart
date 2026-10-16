import 'package:efteqad/core/errors/app_failure.dart';
import 'package:efteqad/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/services/firestore_service.dart';
import '../widgets/task_action_buttons.dart';
import '../widgets/task_details_card.dart';

class TaskDetailsScreen extends StatelessWidget {
  final String taskId;
  final TaskModel? task;

  const TaskDetailsScreen({super.key, required this.taskId, this.task});

  @override
  Widget build(BuildContext context) =>
      _TaskDetailsView(key: ValueKey(task!.id), task: task!);
}

class _TaskDetailsView extends StatefulWidget {
  final TaskModel task;

  const _TaskDetailsView({super.key, required this.task});

  @override
  State<_TaskDetailsView> createState() => _TaskDetailsViewState();
}

class _TaskDetailsViewState extends State<_TaskDetailsView> {
  late bool _isCompleted;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.task.isCompleted;
  }

  @override
  void didUpdateWidget(covariant _TaskDetailsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task.isCompleted != oldWidget.task.isCompleted) {
      _isCompleted = widget.task.isCompleted;
    }
  }

  Future<void> _toggleCompleted() async {
    setState(() => _isLoading = true);
    final newStatus = !_isCompleted;
    try {
      await FirestoreService().toggleTaskStatus(widget.task.id, newStatus);
      if (mounted) {
        setState(() {
          _isCompleted = newStatus;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppFailure.fromException(e).localizedMessage(context.tr),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.messageTaskDetails),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TaskDetailsCard(task: widget.task),
            SizedBox(height: 24.h),
            TaskActionButtons(
              isAttendanceTask: widget.task.isAttendanceTask,
              isCompleted: _isCompleted,
              isLoading: _isLoading,
              onOpenAttendance: () {
                context.go(AppRoutes.taskAttendance(widget.task.id));
              },
              onToggleCompleted: _toggleCompleted,
            ),
          ],
        ),
      ),
    );
  }
}
