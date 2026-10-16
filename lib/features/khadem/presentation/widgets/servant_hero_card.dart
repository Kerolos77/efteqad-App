import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/localization/app_localizations.dart';

class ServantHeroCard extends StatelessWidget {
  final String servantName;
  final Color khademColor;
  final int visitedCount;
  final int totalCount;
  final bool isDark;

  const ServantHeroCard({
    super.key,
    required this.servantName,
    required this.khademColor,
    required this.visitedCount,
    required this.totalCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final formatters = AppFormatters(Localizations.localeOf(context));
    final percentage = totalCount > 0 ? (visitedCount / totalCount) : 0.0;
    final initialChar = servantName.trim().isNotEmpty ? servantName.trim()[0] : context.tr.messageS;

    return Container(
      margin: EdgeInsetsDirectional.fromSTEB(16.w, 10.h, 16.w, 8.h),
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 18.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48.r,
                height: 48.r,
                decoration: BoxDecoration(
                  color: khademColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: khademColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    initialChar,
                    style: TextStyle(
                      color: khademColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 20.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr.servantGreeting(servantName),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      context.tr.shepherdVerseGoodShepherd,
                      style: TextStyle(
                        color: AppColors.accentGold,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // شريط الإنجاز
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr.visitedRatio(visitedCount, totalCount),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.sp,
                ),
              ),
              Text(
                '${formatters.formatNumber(percentage * 100, decimalDigits: 0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14.sp,
                  color: khademColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8.h,
              backgroundColor: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(khademColor),
            ),
          ),
        ],
      ),
    );
  }
}
