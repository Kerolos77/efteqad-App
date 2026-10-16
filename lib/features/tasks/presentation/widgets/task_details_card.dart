import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/domain_labels.dart';
import '../../../../core/models/task_model.dart';

class TaskDetailsCard extends StatelessWidget {
  final TaskModel task;

  const TaskDetailsCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final domainLabels = DomainLabels(locale);
    final formatters = AppFormatters(locale);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: AppColors.sacredGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    task.isAttendanceTask
                        ? Icons.fact_check_rounded
                        : Icons.task_alt_rounded,
                    color: AppColors.sacredGold,
                    size: 28.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.royalGold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          domainLabels.taskTypeName(task.type),
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.royalGold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (task.description.isNotEmpty) ...[
              SizedBox(height: 20.h),
              const Divider(),
              SizedBox(height: 12.h),
              Text(
                context.tr.messageDescription,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                task.description,
                style: TextStyle(fontSize: 15.sp, height: 1.5),
              ),
            ],
            SizedBox(height: 20.h),
            const Divider(),
            SizedBox(height: 12.h),
            _buildInfoRow(
              icon: Icons.person_outline_rounded,
              label: context.tr.messageAssignedServant661,
              value: task.assignedKhademName,
            ),
            SizedBox(height: 10.h),
            _buildInfoRow(
              icon: Icons.school_outlined,
              label: context.tr.messageGrade,
              value: domainLabels.gradeName(task.grade),
            ),
            if (task.dueDate != null) ...[
              SizedBox(height: 10.h),
              _buildInfoRow(
                icon: Icons.calendar_today_rounded,
                label: context.tr.messageDueDate,
                value: formatters.formatDate(task.dueDate!),
              ),
            ],
            SizedBox(height: 10.h),
            _buildInfoRow(
              icon: Icons.create_rounded,
              label: context.tr.messageCreatedBy,
              value: task.createdByName,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: Colors.grey),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            '$label: ',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
