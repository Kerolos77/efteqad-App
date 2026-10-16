import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/domain_labels.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/router/app_routes.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final bool isDark;
  final bool canDelete;
  final ValueChanged<bool> onToggleStatus;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.isDark,
    required this.canDelete,
    required this.onToggleStatus,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Color typeColor;
    IconData typeIcon;
    switch (task.type) {
      case 'attendance_qoddas':
        typeColor = AppColors.accentGold;
        typeIcon = Icons.church_rounded;
        break;
      case 'attendance':
      case 'attendance_khedma':
        typeColor = const Color(0xFF8B5CF6);
        typeIcon = Icons.fact_check_outlined;
        break;
      case 'visitation':
        typeColor = AppColors.accentGold;
        typeIcon = Icons.home_work_outlined;
        break;
      case 'general':
      default:
        typeColor = AppColors.primaryLight;
        typeIcon = Icons.task_alt_outlined;
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: task.isCompleted
              ? AppColors.successColor.withValues(alpha: 0.3)
              : (isDark
                  ? AppColors.cardBorderDark
                  : AppColors.cardBorderLight),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: task.isCompleted,
            activeColor: AppColors.successColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6.r),
            ),
            onChanged: (val) {
              if (val != null) {
                onToggleStatus(val);
              }
            },
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(typeIcon, size: 12.sp, color: typeColor),
                          SizedBox(width: 4.w),
                          Text(
                            DomainLabels(
                              Localizations.localeOf(context),
                            ).taskTypeName(task.type),
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: typeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white10
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person,
                              size: 12.sp,
                              color: AppColors.textMuted,
                            ),
                            SizedBox(width: 4.w),
                            Flexible(
                              child: Text(
                                task.assignedKhademName,
                                style: TextStyle(
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: task.isCompleted
                        ? AppColors.textMuted
                        : (isDark ? Colors.white : AppColors.textDark),
                  ),
                ),
                if (task.description.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    task.description,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMuted,
                    ),
                  ),
                ],
                if (task.isAttendanceTask) ...[
                  SizedBox(height: 10.h),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.push(AppRoutes.taskAttendance(task.id));
                    },
                    icon: Icon(Icons.how_to_reg_rounded, size: 16.sp),
                    label: Text(
                      context.tr.takeAttendanceAction,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: task.isMassAttendance
                          ? AppColors.accentGold
                          : const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 7.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (canDelete && onDelete != null)
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 18.sp,
                color: AppColors.errorColor,
              ),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
