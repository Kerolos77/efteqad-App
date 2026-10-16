import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/attendance_roster_repository.dart';
import '../../../../core/utils/color_generator.dart';

class AttendanceTopSummaryBar extends StatelessWidget {
  final List<AttendanceRosterRow> attendedList;
  final int excusedCount;
  final int absentCount;
  final int totalCount;
  final bool isDark;
  final bool isAuthorized;
  final String sessionType;
  final String Function(String) getGradeShortLabel;
  final ValueChanged<AttendanceRosterRow> onRemoveAttendance;

  const AttendanceTopSummaryBar({
    super.key,
    required this.attendedList,
    required this.excusedCount,
    required this.absentCount,
    required this.totalCount,
    required this.isDark,
    required this.isAuthorized,
    required this.sessionType,
    required this.getGradeShortLabel,
    required this.onRemoveAttendance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 86.h, maxHeight: 240.h),
      margin: EdgeInsetsDirectional.fromSTEB(16.w, 6.h, 16.w, 2.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: attendedList.isNotEmpty
              ? AppColors.primaryLight.withValues(alpha: 0.35)
              : (isDark
                  ? AppColors.cardBorderDark
                  : AppColors.cardBorderLight),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(5.r),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.how_to_reg_rounded,
                  size: 15.sp,
                  color: AppColors.primaryLight,
                ),
              ),
              Text(
                context.tr.selectedAttendedHeader,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5.sp,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryNavy,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  context.tr.totalAttendedCount(
                    attendedList.length,
                    totalCount,
                  ),
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              if (excusedCount > 0)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 3.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    'بعذر: $excusedCount',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accentGold,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 6.h),
          const Divider(height: 1),
          SizedBox(height: 6.h),
          Flexible(
            child: attendedList.isEmpty
                ? Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          size: 16.sp,
                          color: isDark
                              ? Colors.white38
                              : AppColors.textMuted,
                        ),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: Text(
                            context.tr.noAttendedYetHint,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white38
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: attendedList.map((m) {
                        return Padding(
                          padding: EdgeInsetsDirectional.only(end: 6.w),
                          child: _buildAttendedChip(context, m),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendedChip(BuildContext context, AttendanceRosterRow m) {
    final color = ColorGenerator.getColorForId(m.id);

    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(6.w, 4.h, 10.w, 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAuthorized)
            InkWell(
              onTap: () => onRemoveAttendance(m),
              borderRadius: BorderRadius.circular(10.r),
              child: Container(
                padding: EdgeInsets.all(2.r),
                margin: EdgeInsetsDirectional.only(start: 4.w),
                decoration: BoxDecoration(
                  color: AppColors.errorColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 14.sp,
                  color: AppColors.errorColor,
                ),
              ),
            ),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              m.fullName,
              style: TextStyle(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
            ),
          ),
          if (sessionType == 'qoddas') ...[
            SizedBox(width: 4.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                getGradeShortLabel(m.grade),
                style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
