import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';

class VisitDraftBanner extends StatelessWidget {
  const VisitDraftBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 8.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.warningColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: AppColors.warningColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 16.r,
            color: AppColors.warningColor,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              context.tr.messageLocalSubmissionLoadedConfirmationIsPending,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.warningColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
