import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:efteqad/core/localization/app_formatters.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../models/history_analysis.dart';

class HistoryAttendanceTimelineCard extends StatelessWidget {
  final FridayAttendanceRecord item;
  final bool isDark;

  const HistoryAttendanceTimelineCard({
    super.key,
    required this.item,
    required this.isDark,
  });

  Widget _buildSessionChip(
    BuildContext context, {
    required String label,
    required bool attended,
  }) {
    final color = attended
        ? AppColors.successColor
        : AppColors.errorColor;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            attended ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 13.sp,
            color: color,
          ),
          SizedBox(width: 5.w),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayDateFormat = AppFormatters(Localizations.localeOf(context));
    final dateStr = displayDateFormat.formatDate(
      item.date,
      format: 'EEEE d MMMM yyyy',
    );
    final isFruitful = item.isAttendedAny && item.precedingVisit != null;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isFruitful
              ? AppColors.successColor.withValues(alpha: 0.4)
              : (isDark
                    ? AppColors.cardBorderDark
                    : AppColors.cardBorderLight),
          width: 1.2.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isFruitful
                  ? AppColors.successColor.withValues(
                      alpha: isDark ? 0.14 : 0.09,
                    )
                  : (item.isAttendedAny
                        ? AppColors.primaryLight.withValues(
                            alpha: isDark ? 0.12 : 0.08,
                          )
                        : AppColors.errorColor.withValues(
                            alpha: isDark ? 0.12 : 0.08,
                          )),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(19.r),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.church_rounded,
                  size: 16.sp,
                  color: item.isAttendedAny
                      ? AppColors.primaryLight
                      : AppColors.errorColor,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    dateStr,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 3.h,
                  ),
                  decoration: BoxDecoration(
                    color: item.isAttendedAny
                        ? AppColors.successColor.withValues(alpha: 0.18)
                        : AppColors.errorColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    item.isAttendedBoth
                        ? context.tr.attendedMassAndService
                        : (item.isAttendedAny
                              ? context.tr.attendedPartial
                              : context.tr.absentBoth),
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w900,
                      color: item.isAttendedAny
                          ? AppColors.successColor
                          : AppColors.errorColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(14.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (item.hasMassSession)
                      _buildSessionChip(
                        context,
                        label: context.tr.massLabel,
                        attended: item.attendedMass,
                      ),
                    if (item.hasMassSession && item.hasServiceSession)
                      SizedBox(width: 8.w),
                    if (item.hasServiceSession)
                      _buildSessionChip(
                        context,
                        label: context.tr.serviceLabel,
                        attended: item.attendedService,
                      ),
                  ],
                ),
                if (item.precedingVisit != null) ...[
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.sacredGold.withValues(
                        alpha: isDark ? 0.15 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.sacredGold.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.volunteer_activism_rounded,
                          size: 14.sp,
                          color: AppColors.sacredGold,
                        ),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: Text(
                            context.tr.precededByVisitNote(
                              AppFormatters(
                                Localizations.localeOf(context),
                              ).formatDate(
                                item.precedingVisit!.visitDate,
                                format: 'yyyy/MM/dd',
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
