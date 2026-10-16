import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';

class AttendanceStatusBanners extends StatelessWidget {
  final bool isLockedByOther;
  final String? lockedByKhademName;
  final bool isAdmin;
  final VoidCallback onTakeOverLock;
  final bool isAuthorized;
  final bool isFinalized;

  const AttendanceStatusBanners({
    super.key,
    required this.isLockedByOther,
    required this.lockedByKhademName,
    required this.isAdmin,
    required this.onTakeOverLock,
    required this.isAuthorized,
    required this.isFinalized,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLockedByOther)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: 8.h,
              horizontal: 14.w,
            ),
            color: AppColors.warningColor.withValues(alpha: 0.16),
            child: Row(
              children: [
                Icon(
                  Icons.lock_person_rounded,
                  size: 18.sp,
                  color: AppColors.warningColor,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'يقوم حالياً "${lockedByKhademName ?? 'خادم آخر'}" برصد الغياب (وضع المشاهدة اللحظية)',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.warningColor,
                    ),
                  ),
                ),
                if (isAdmin)
                  TextButton(
                    onPressed: onTakeOverLock,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'استلام الرصد',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (!isAuthorized)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: 8.h,
              horizontal: 16.w,
            ),
            color: AppColors.warningColor.withValues(alpha: 0.15),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16.sp,
                  color: AppColors.warningColor,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    context.tr.notAuthorizedAttendance,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warningColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (isFinalized)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: 8.h,
              horizontal: 16.w,
            ),
            color: AppColors.successColor.withValues(alpha: 0.15),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 16.sp,
                  color: AppColors.successColor,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    context.tr.messageAttendanceSessionIsFinalizedAndLockedRead,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.successColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
