import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/khadem_model.dart';

class PendingKhademCard extends StatelessWidget {
  final KhademModel khadem;
  final bool isDark;
  final VoidCallback onAssign;
  final VoidCallback? onReject;
  final VoidCallback? onMakeCall;

  const PendingKhademCard({
    super.key,
    required this.khadem,
    required this.isDark,
    required this.onAssign,
    this.onReject,
    this.onMakeCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.warningColor.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: AppColors.warningColor.withValues(alpha: 0.15),
                child: Icon(
                  Icons.person_add_rounded,
                  color: AppColors.warningColor,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      khadem.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                    if (khadem.phone.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        khadem.phone,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onMakeCall != null && khadem.phone.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.phone_outlined,
                    size: 20.sp,
                    color: AppColors.primaryLight,
                  ),
                  tooltip: 'اتصال',
                  onPressed: onMakeCall,
                ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              if (onReject != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: Icon(Icons.close_rounded, size: 16.sp),
                    label: const Text(
                      'رفض',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.errorColor,
                      side: BorderSide(
                        color: AppColors.errorColor.withValues(alpha: 0.6),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAssign,
                  icon: Icon(Icons.school_rounded, size: 16.sp),
                  label: Text(
                    context.tr.messageAssign,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
