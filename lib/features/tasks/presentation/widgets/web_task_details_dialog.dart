import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/localization/domain_labels.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/router/app_routes.dart';

class WebTaskDetailsDialog extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggleStatus;

  const WebTaskDetailsDialog({
    super.key,
    required this.task,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final formatters = AppFormatters(Localizations.localeOf(context));
    final domainLabels = DomainLabels(Localizations.localeOf(context));

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Row(
        children: [
          Icon(
            task.isCompleted
                ? Icons.check_circle_rounded
                : Icons.assignment_rounded,
            color: task.isCompleted
                ? AppColors.successColor
                : AppColors.primaryLight,
            size: 24.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
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
              Text(
                'التفاصيل والتعليمات:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
              ),
              SizedBox(height: 6.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  task.description,
                  style: TextStyle(fontSize: 13.sp, height: 1.4),
                ),
              ),
              SizedBox(height: 14.h),
            ],
            _buildDetailRow(
              'نوع التكليف:',
              domainLabels.taskTypeName(task.type),
            ),
            if (task.dueDate != null)
              _buildDetailRow(
                'موعد الاستحقاق:',
                formatters.formatDate(task.dueDate!),
              ),
            _buildDetailRow(
              'المشرف المنشئ:',
              task.createdByName.isNotEmpty ? task.createdByName : 'الإدارة',
            ),
            _buildDetailRow(
              'الحالة:',
              task.isCompleted ? 'مكتملة ومُنجزة ✅' : 'قيد التنفيذ ⏳',
            ),
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
            backgroundColor: task.isCompleted
                ? AppColors.warningColor
                : AppColors.successColor,
          ),
          onPressed: onToggleStatus,
          child: Text(
            task.isCompleted ? 'إعادة إلى قيد التنفيذ' : 'إتمام المهمة',
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12.5.sp, color: AppColors.textMuted),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
