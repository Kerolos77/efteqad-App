import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../application/attendance_cubit.dart';

class AttendanceStatusBadge extends StatelessWidget {
  final AttendanceState state;

  const AttendanceStatusBadge({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    if (!state.hasLoadedRemote) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 8.w,
              height: 8.h,
              child: const CircularProgressIndicator(strokeWidth: 1.5),
            ),
            SizedBox(width: 5.w),
            Flexible(
              child: Text(
                context.tr.messageLoading,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state.isFinalized) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: AppColors.primaryNavy.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: AppColors.primaryNavy.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_rounded,
              size: 12.sp,
              color: AppColors.primaryNavy,
            ),
            SizedBox(width: 4.w),
            Flexible(
              child: Text(
                context.tr.messageFinalized,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state.status == 'saving' ||
        state.pendingById.isNotEmpty ||
        state.pendingExcusesById.isNotEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: AppColors.warningColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: AppColors.warningColor.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 8.w,
              height: 8.h,
              child: const CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.warningColor,
              ),
            ),
            SizedBox(width: 5.w),
            Flexible(
              child: Text(
                context.tr.messageSaving,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.warningColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state.status == 'error' || state.saveErrors.isNotEmpty) {
      return InkWell(
        onTap: () {
          final firstError = state.saveErrors.values.firstOrNull;
          if (firstError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppFailure.fromException(firstError).localizedMessage(context.tr),
                ),
                backgroundColor: AppColors.errorColor,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: AppColors.errorColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: AppColors.errorColor.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 10.sp,
                color: AppColors.errorColor,
              ),
              SizedBox(width: 4.w),
              Flexible(
                child: Text(
                  context.tr.messageSaveError,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.errorColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.successColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: AppColors.successColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7.r,
            height: 7.r,
            decoration: const BoxDecoration(
              color: AppColors.successColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 5.w),
          Flexible(
            child: Text(
              context.tr.autoSavedNotice,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.successColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
