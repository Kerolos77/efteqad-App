import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/utils/color_generator.dart';

class AssignConflictWarningDialog extends StatelessWidget {
  final List<MakhdomModel> conflictingMakhdomeen;
  final String targetKhademName;

  const AssignConflictWarningDialog({
    super.key,
    required this.conflictingMakhdomeen,
    required this.targetKhademName,
  });

  static Future<bool?> show(
    BuildContext context, {
    required List<MakhdomModel> conflictingMakhdomeen,
    required String targetKhademName,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AssignConflictWarningDialog(
        conflictingMakhdomeen: conflictingMakhdomeen,
        targetKhademName: targetKhademName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
      ),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: AppColors.warningColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warningColor,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              context.tr.conflictWarningTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr.conflictWarningTransferCount(
                conflictingMakhdomeen.length,
                targetKhademName,
              ),
              style: TextStyle(
                fontSize: 13.sp,
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMuted,
                height: 1.4,
              ),
            ),
            SizedBox(height: 14.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.warningColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.warningColor.withValues(
                    alpha: 0.25,
                  ),
                ),
              ),
              child: Column(
                children: conflictingMakhdomeen.map((m) {
                  final currentKhademColor = ColorGenerator.getColorForId(
                    m.assignedKhademId,
                  );
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 5.h),
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_left_rounded,
                          size: 20.sp,
                          color: AppColors.warningColor,
                        ),
                        Expanded(
                          child: Text(
                            m.fullName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
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
                            color: currentKhademColor.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: currentKhademColor.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                          child: Text(
                            m.assignedKhademName ??
                                context.tr.otherServant,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: currentKhademColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              context.tr.confirmTransferQuestion,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.sp,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            context.tr.cancel,
            style: TextStyle(
              color: isDark
                  ? AppColors.textMutedDark
                  : AppColors.textMuted,
            ),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.warningColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            context.tr.conflictTransferBtn,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
