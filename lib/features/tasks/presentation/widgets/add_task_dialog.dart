import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/trusted_mutations.dart';
import 'add_task_header.dart';
import 'task_due_date_picker.dart';

class AddTaskDialog extends StatefulWidget {
  final List<KhademModel> availableKhodam;
  final String grade; // '1st', '2nd', '3rd', or 'all'
  final String? serviceId;

  final FirestoreService? firestoreService;
  final AuthService? authService;

  const AddTaskDialog({
    super.key,
    this.firestoreService,
    this.authService,
    required this.availableKhodam,
    required this.grade,
    this.serviceId,
  });

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  late final FirestoreService _firestoreService;
  AuthService get _authService => widget.authService ?? AuthService();

  String? _selectedKhademId;
  String _taskType = 'general';
  DateTime? _dueDate;
  bool _isSaving = false;
  final String _operationId = newOperationId('task');
  TaskModel? _submittedTask;

  DateTime _getNextFriday() {
    final now = DateTime.now();
    int daysUntilFriday = (DateTime.friday - now.weekday) % 7;
    if (daysUntilFriday == 0 && now.hour >= 18) {
      daysUntilFriday = 7;
    }
    return DateTime(now.year, now.month, now.day + daysUntilFriday);
  }

  @override
  void initState() {
    super.initState();
    _firestoreService = widget.firestoreService ?? FirestoreService();
    if (widget.availableKhodam.isNotEmpty) {
      _selectedKhademId = widget.availableKhodam.first.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving ||
        (_submittedTask == null && !_formKey.currentState!.validate())) {
      return;
    }
    if (_selectedKhademId == null) return;

    final selectedKhadem = _submittedTask == null
        ? widget.availableKhodam.firstWhere((k) => k.id == _selectedKhademId)
        : null;
    final currentUser = _authService.currentUser;
    final successText = context.tr.taskCreatedSuccess;

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);
    try {
      final task = _submittedTask ??= TaskModel(
        id: '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        assignedKhademId: selectedKhadem!.id,
        assignedKhademName: selectedKhadem.name,
        grade: widget.grade,
        createdById: currentUser?.uid ?? 'admin',
        createdByName: currentUser?.displayName ?? (context.tr.messageAdmin),
        type: _taskType,
        dueDate: _dueDate,
        serviceId: widget.serviceId ?? 'thanawy',
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      String notifBody;
      if (task.type == AppConstants.taskTypeAttendanceKhedma) {
        notifBody = context.tr.messageYouAreAssignedToTakeServiceAttendance;
      } else if (task.type == AppConstants.taskTypeAttendanceQoddas) {
        notifBody = context.tr.messageYouAreAssignedToTakeMassAttendance;
      } else if (task.description.isNotEmpty) {
        notifBody = task.description;
      } else {
        notifBody = context.tr.messageAssignedYouANewTask(
          (task.createdByName).toString(),
        );
      }

      final notifTitle = context.tr.messageNewTask((task.title).toString());

      await _firestoreService.createTaskWithOutbox(
        task: task,
        outboxTitle: notifTitle,
        outboxBody: notifBody,
        operationId: _operationId,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successText),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    } catch (e) {
      final failure = AppFailure.fromException(e);
      if (!failure.retryable) {
        _submittedTask = null;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.localizedMessage(context.tr)),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: EdgeInsets.all(22.r),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_submittedTask != null)
                    Text(
                      context
                          .tr
                          .messageSubmissionIsLockedUntilConfirmationRetryTo,
                    ),
                  AddTaskHeader(onClose: () => Navigator.pop(context)),
                  SizedBox(height: 20.h),

                  // عنوان المهمة
                  TextFormField(
                    enabled: _submittedTask == null,
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: context.tr.taskTitleLabel,
                      prefixIcon: Icon(Icons.title_rounded, size: 20.sp),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return context.tr.taskTitleRequired;
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 14.h),

                  // نوع المهمة
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    itemHeight: null,
                    initialValue: _taskType,
                    decoration: InputDecoration(
                      labelText: context.tr.taskTypeLabel,
                      prefixIcon: Icon(Icons.category_outlined, size: 20.sp),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'general',
                        child: Text(context.tr.taskTypeGeneral),
                      ),
                      if (widget.grade == AppConstants.gradeAll)
                        DropdownMenuItem(
                          value: AppConstants.taskTypeAttendanceQoddas,
                          child: Text(context.tr.taskTypeAttendanceQoddas),
                        )
                      else
                        DropdownMenuItem(
                          value: AppConstants.taskTypeAttendanceKhedma,
                          child: Text(context.tr.taskTypeAttendanceKhedma),
                        ),
                      DropdownMenuItem(
                        value: 'visitation',
                        child: Text(context.tr.taskTypeVisitation),
                      ),
                    ],
                    onChanged: _submittedTask != null
                        ? null
                        : (val) {
                            if (val != null) {
                              setState(() {
                                _taskType = val;
                                if (_taskType.startsWith('attendance')) {
                                  _dueDate ??= _getNextFriday();
                                  if (_titleController.text.isEmpty ||
                                      _titleController.text ==
                                          context.tr.taskTypeAttendanceKhedma ||
                                      _titleController.text ==
                                          context.tr.taskTypeAttendanceQoddas) {
                                    _titleController.text =
                                        _taskType ==
                                                AppConstants
                                                    .taskTypeAttendanceQoddas
                                            ? context.tr.taskTypeAttendanceQoddas
                                            : context.tr.taskTypeAttendanceKhedma;
                                  }
                                }
                              });
                            }
                          },
                  ),
                  SizedBox(height: 14.h),

                  // تاريخ الاستحقاق / يوم الجمعة
                  TaskDueDatePicker(
                    dueDate: _dueDate,
                    taskType: _taskType,
                    isDark: isDark,
                    enabled: _submittedTask == null,
                    nextFriday: _getNextFriday(),
                    onDateSelected: (picked) => setState(() => _dueDate = picked),
                  ),
                  SizedBox(height: 14.h),

                  // اختيار الخادم المكلف
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    itemHeight: null,
                    initialValue: _selectedKhademId,
                    decoration: InputDecoration(
                      labelText: context.tr.taskAssigneeLabel,
                      prefixIcon: Icon(Icons.person_outline, size: 20.sp),
                    ),
                    items: widget.availableKhodam.map((khadem) {
                      return DropdownMenuItem(
                        value: khadem.id,
                        child: Text(
                          khadem.name.isNotEmpty ? khadem.name : khadem.email,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: _submittedTask != null
                        ? null
                        : (val) {
                            if (val != null) {
                              setState(() => _selectedKhademId = val);
                            }
                          },
                  ),
                  SizedBox(height: 14.h),

                  // تفاصيل المهمة
                  TextFormField(
                    enabled: _submittedTask == null,
                    controller: _descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: context.tr.taskDescLabel,
                      alignLabelWithHint: true,
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // أزرار الحفظ والإلغاء
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(context.tr.cancel),
                      ),
                      SizedBox(width: 8.w),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryLight,
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 12.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: _isSaving
                            ? SizedBox(
                                width: 16.w,
                                height: 16.h,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                context.tr.save,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
