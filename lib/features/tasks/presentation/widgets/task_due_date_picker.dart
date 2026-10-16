import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/localization/app_localizations.dart';

class TaskDueDatePicker extends StatelessWidget {
  final DateTime? dueDate;
  final String taskType;
  final bool isDark;
  final bool enabled;
  final DateTime nextFriday;
  final ValueChanged<DateTime> onDateSelected;

  const TaskDueDatePicker({
    super.key,
    required this.dueDate,
    required this.taskType,
    required this.isDark,
    required this.enabled,
    required this.nextFriday,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        if (!enabled) return;
        final picked = await showDatePicker(
          context: context,
          initialDate: dueDate ?? nextFriday,
          firstDate: DateTime.now().subtract(const Duration(days: 7)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          selectableDayPredicate: taskType.startsWith('attendance')
              ? (DateTime day) => day.weekday == DateTime.friday
              : null,
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131D31) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
          ),
        ),
        child: Row(
          children: [
            Icon(
              taskType.startsWith('attendance')
                  ? Icons.event_available_rounded
                  : Icons.calendar_today_outlined,
              size: 18.sp,
              color: AppColors.primaryLight,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                dueDate != null
                    ? context.tr.messageDate(
                        (AppFormatters(Localizations.localeOf(context))
                                .formatDate(dueDate!, format: 'yyyy-MM-dd'))
                            .toString(),
                      )
                    : context.tr.messageSelectDueDateOptional,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight:
                      dueDate != null ? FontWeight.bold : FontWeight.w500,
                  color: dueDate != null
                      ? (isDark ? Colors.white : AppColors.textDark)
                      : AppColors.textMuted,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            if (taskType.startsWith('attendance'))
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  AppFormatters(Localizations.localeOf(context))
                      .formatWeekday(dueDate ?? nextFriday),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
