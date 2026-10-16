import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/localization/app_localizations.dart';

class VisitDatePickerTile extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime>? onDateSelected;
  final bool isEnabled;

  const VisitDatePickerTile({
    super.key,
    required this.selectedDate,
    this.onDateSelected,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: isEnabled
          ? () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                onDateSelected?.call(picked);
              }
            }
          : null,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14.w,
          vertical: 12.h,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131D31) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16.r,
              color: AppColors.primaryLight,
            ),
            SizedBox(width: 10.w),
            Text(
              context.tr.visitDateLabel(
                AppFormatters(
                  Localizations.localeOf(context),
                ).formatDate(selectedDate),
              ),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.sp,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_drop_down,
              color: AppColors.textMuted,
              size: 20.r,
            ),
          ],
        ),
      ),
    );
  }
}
