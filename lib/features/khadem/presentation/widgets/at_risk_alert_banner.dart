import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/localization/app_localizations.dart';

class AtRiskAlertBanner extends StatelessWidget {
  final int atRiskCount;
  final bool isDark;
  final VoidCallback? onViewAnalytics;

  const AtRiskAlertBanner({
    super.key,
    required this.atRiskCount,
    required this.isDark,
    this.onViewAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    if (atRiskCount <= 0) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsetsDirectional.fromSTEB(16.w, 4.h, 16.w, 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: isDark ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.redAccent.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.redAccent,
            size: 22.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              context.tr.messageAlertBoysNeedUrgentVisitRepeatedAbsence(
                atRiskCount.toString(),
              ),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.sp,
                color: Colors.redAccent,
              ),
            ),
          ),
          if (onViewAnalytics != null)
            TextButton(
              onPressed: onViewAnalytics,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 4.h,
                ),
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                context.tr.messageView,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12.sp,
                  color: Colors.redAccent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
