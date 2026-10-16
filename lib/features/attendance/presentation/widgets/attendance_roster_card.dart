import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/attendance_session_model.dart';
import '../../../../core/services/attendance_roster_repository.dart';
import '../../../../core/utils/color_generator.dart';

class AttendanceRosterCard extends StatelessWidget {
  final AttendanceRosterRow makhdom;
  final bool isAttended;
  final AttendanceExcuse? excuse;
  final bool isPending;
  final bool hasError;
  final bool isDark;
  final bool isAuthorized;
  final String sessionType;
  final String gradeLabel;
  final ValueChanged<bool> onToggleAttendance;
  final VoidCallback onExcuseTap;
  final VoidCallback onErrorTap;

  const AttendanceRosterCard({
    super.key,
    required this.makhdom,
    required this.isAttended,
    required this.excuse,
    required this.isPending,
    required this.hasError,
    required this.isDark,
    required this.isAuthorized,
    required this.sessionType,
    required this.gradeLabel,
    required this.onToggleAttendance,
    required this.onExcuseTap,
    required this.onErrorTap,
  });

  @override
  Widget build(BuildContext context) {
    final khademColor = ColorGenerator.getColorForId(makhdom.id);
    final isExcused = !isAttended && excuse != null;

    return InkWell(
      onTap: isAuthorized && !isPending
          ? () => onToggleAttendance(!isAttended)
          : null,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isAttended
              ? AppColors.primaryLight.withValues(alpha: isDark ? 0.2 : 0.08)
              : isExcused
                  ? AppColors.accentGold.withValues(alpha: isDark ? 0.16 : 0.08)
                  : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: hasError
                ? AppColors.errorColor
                : isAttended
                    ? AppColors.primaryLight
                    : isExcused
                        ? AppColors.accentGold
                        : (isDark
                            ? AppColors.cardBorderDark
                            : AppColors.cardBorderLight),
            width: isAttended || isExcused || hasError ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            if (isPending)
              SizedBox(
                width: 24.w,
                height: 24.h,
                child: Padding(
                  padding: EdgeInsets.all(4.r),
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Checkbox(
                value: isAttended,
                activeColor: AppColors.primaryLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.r),
                ),
                onChanged: isAuthorized
                    ? (val) => onToggleAttendance(val ?? false)
                    : null,
              ),
            SizedBox(width: 8.w),

            CircleAvatar(
              radius: 16.r,
              backgroundColor: khademColor.withValues(alpha: 0.15),
              child: Text(
                makhdom.fullName.isNotEmpty
                    ? makhdom.fullName[0]
                    : context.tr.messageM,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: khademColor,
                ),
              ),
            ),
            SizedBox(width: 10.w),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          makhdom.fullName,
                          style: TextStyle(
                            fontSize: 13.5.sp,
                            fontWeight: isAttended || isExcused
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textDark,
                          ),
                        ),
                      ),
                      if (hasError)
                        InkWell(
                          onTap: onErrorTap,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            child: Icon(
                              Icons.error_outline,
                              size: 16.sp,
                              color: AppColors.errorColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (excuse != null) ...[
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Icon(
                          Icons.event_available_outlined,
                          size: 12.sp,
                          color: AppColors.accentGold,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            'عذر: ${excuse!.note}${excuse!.byKhademName.isNotEmpty ? ' (${excuse!.byKhademName})' : ''}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentGold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (sessionType == 'qoddas')
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 5.w,
                            vertical: 1.h,
                          ),
                          decoration: BoxDecoration(
                            color: khademColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5.r),
                          ),
                          child: Text(
                            gradeLabel,
                            style: TextStyle(
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.bold,
                              color: khademColor,
                            ),
                          ),
                        ),
                        SizedBox(width: 6.w),
                      ],
                    ),
                ],
              ),
            ),

            if (isAuthorized && !isPending)
              IconButton(
                onPressed: onExcuseTap,
                tooltip: 'تسجيل عذر غياب',
                icon: Icon(
                  excuse != null
                      ? Icons.speaker_notes_rounded
                      : Icons.edit_note_rounded,
                  size: 20.sp,
                  color: excuse != null
                      ? AppColors.accentGold
                      : AppColors.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
