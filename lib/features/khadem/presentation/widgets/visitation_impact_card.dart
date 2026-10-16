import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/attendance_analytics_service.dart';

class VisitationImpactCard extends StatelessWidget {
  final VisitationImpactInfo impact;
  final bool isDark;

  const VisitationImpactCard({
    super.key,
    required this.impact,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (!impact.hasSufficientData) {
      return Padding(
        padding: EdgeInsets.all(12.r),
        child: Text(
          context.tr.insufficientAttendanceData,
          style: TextStyle(fontSize: 13.sp, color: AppColors.textMuted),
        ),
      );
    }

    final formatters = AppFormatters(Localizations.localeOf(context));

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.lightbulb_rounded,
                  color: Colors.amber,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr.visitationImpactHeader,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5.sp,
                      ),
                    ),
                    Text(
                      context.tr.visitationImpactSubtitle,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr.messageVisited,
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${formatters.formatNumber(impact.visitedAttendanceRate!, decimalDigits: 0)}%',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.successColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6.r),
                      child: LinearProgressIndicator(
                        value: (impact.visitedAttendanceRate! / 100).clamp(0.0, 1.0),
                        minHeight: 8.h,
                        backgroundColor: isDark
                            ? Colors.white12
                            : const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.successColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr.messageUnvisited,
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${formatters.formatNumber(impact.unvisitedAttendanceRate!, decimalDigits: 0)}%',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.errorColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6.r),
                      child: LinearProgressIndicator(
                        value: (impact.unvisitedAttendanceRate! / 100).clamp(0.0, 1.0),
                        minHeight: 8.h,
                        backgroundColor: isDark
                            ? Colors.white12
                            : const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.errorColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: impact.impactPercentage! > 0
                  ? AppColors.successColor.withValues(alpha: 0.1)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              context.tr.visitationImpactValue(impact.impactPercentage!),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11.5.sp,
                color: impact.impactPercentage! > 0
                    ? AppColors.successColor
                    : (isDark ? Colors.white70 : AppColors.textDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
