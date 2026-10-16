import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/models/khadem_model.dart';

class RejectedKhademCard extends StatelessWidget {
  final KhademModel khadem;
  final bool isDark;
  final VoidCallback onReopen;
  final VoidCallback onAssign;
  final VoidCallback? onMakeCall;

  const RejectedKhademCard({
    super.key,
    required this.khadem,
    required this.isDark,
    required this.onReopen,
    required this.onAssign,
    this.onMakeCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.errorColor.withValues(alpha: 0.35),
          width: 1.2,
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
          // Header: Avatar, Name, Phone & Call Button
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: AppColors.errorColor.withValues(alpha: 0.15),
                child: Icon(
                  Icons.person_off_rounded,
                  color: AppColors.errorColor,
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
          SizedBox(height: 10.h),

          // Rejection Reason Box
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.errorColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: AppColors.errorColor.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.errorColor,
                  size: 16.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.35,
                      ),
                      children: [
                        const TextSpan(
                          text: 'سبب الرفض: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.errorColor,
                          ),
                        ),
                        TextSpan(
                          text: (khadem.rejectionReason != null &&
                                  khadem.rejectionReason!.trim().isNotEmpty)
                              ? khadem.rejectionReason!
                              : 'لم يُحدد سبب معين.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),

          // Action Buttons: Reopen Application & Directly Accept
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReopen,
                  icon: Icon(Icons.replay_rounded, size: 16.sp),
                  label: Text(
                    'استعادة للانتظار',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warningColor,
                    side: BorderSide(
                      color: AppColors.warningColor.withValues(alpha: 0.6),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAssign,
                  icon: Icon(Icons.check_rounded, size: 16.sp),
                  label: Text(
                    'قبول وتسكين',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
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
