import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/models/attendance_session_model.dart';

class AttendanceHistoryTile extends StatelessWidget {
  final AttendanceSessionModel session;
  final String currentUid;
  final bool isDark;
  final VoidCallback onTap;

  const AttendanceHistoryTile({
    super.key,
    required this.session,
    required this.currentUid,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lockedByOther = session.isLockedByOther(currentUid);
    final isMass = session.isMass;
    final accent = isMass ? AppColors.accentGold : const Color(0xFF8B5CF6);

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark
              ? AppColors.cardBorderDark
              : AppColors.cardBorderLight,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
        leading: Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            isMass ? Icons.church_rounded : Icons.fact_check_rounded,
            color: accent,
            size: 20.sp,
          ),
        ),
        title: Text(
          '${isMass ? "حضور القداس" : "حضور الخدمة"} — ${session.date}',
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          lockedByOther
              ? '🔒 يرصد الآن: ${session.lockedByKhademName ?? "خادم آخر"}'
              : 'حاضر: ${session.attendedCount} • بعذر: ${session.excusedCount} • ${session.isFinalized ? "معتمد" : "قيد الرصد"}',
          style: TextStyle(
            fontSize: 11.5.sp,
            color: lockedByOther
                ? AppColors.warningColor
                : AppColors.textMuted,
            fontWeight: lockedByOther ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        trailing: Icon(Icons.chevron_right_rounded, size: 20.sp),
      ),
    );
  }
}
