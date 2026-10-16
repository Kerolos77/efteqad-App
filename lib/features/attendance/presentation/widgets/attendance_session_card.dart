import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/models/attendance_session_model.dart';

class AttendanceSessionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String sessionType;
  final AttendanceSessionModel? session;
  final String currentUid;
  final bool isDark;
  final VoidCallback onOpen;

  const AttendanceSessionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.sessionType,
    required this.session,
    required this.currentUid,
    required this.isDark,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final lockedByOther = session?.isLockedByOther(currentUid) ?? false;
    final holderName = session?.lockedByKhademName ?? 'خادم آخر';
    final attendedCount = session?.attendedCount ?? 0;
    final excusedCount = session?.excusedCount ?? 0;
    final isFinalized = session?.isFinalized ?? false;

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: lockedByOther
              ? AppColors.warningColor.withValues(alpha: 0.6)
              : accentColor.withValues(alpha: 0.35),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: accentColor, size: 22.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (session != null)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: isFinalized
                        ? AppColors.successColor.withValues(alpha: 0.14)
                        : accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'حاضر: $attendedCount${excusedCount > 0 ? ' • بعذر: $excusedCount' : ''}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: isFinalized
                          ? AppColors.successColor
                          : accentColor,
                    ),
                  ),
                ),
            ],
          ),
          if (lockedByOther) ...[
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.warningColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_person_rounded,
                    size: 16.sp,
                    color: AppColors.warningColor,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      'يقوم حالياً "$holderName" بتسجيل الغياب في هذه الجلسة',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.warningColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: lockedByOther
                    ? AppColors.warningColor
                    : accentColor,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onPressed: onOpen,
              icon: Icon(
                lockedByOther
                    ? Icons.visibility_rounded
                    : (isFinalized
                          ? Icons.fact_check_outlined
                          : Icons.how_to_reg_rounded),
                size: 18.sp,
              ),
              label: Text(
                lockedByOther
                    ? 'مشاهدة الرصد المباشر ($holderName)'
                    : (isFinalized
                          ? 'مراجعة سجل الجلسة المعتمدة'
                          : 'فتح شاشة رصد الحضور والغياب'),
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
