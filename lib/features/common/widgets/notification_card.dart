import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/notification_text.dart';
import '../../../../core/models/notification_model.dart';

/// Reusable card displaying an individual notification item with time, status, and icon.
class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final bool isRead;
  final bool isDark;
  final String formattedTime;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.isRead,
    required this.isDark,
    required this.formattedTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    IconData iconData;

    if (notification.isTask) {
      iconColor = AppColors.primaryLight;
      iconData = Icons.task_alt_rounded;
    } else if (notification.isAbsenceAlert) {
      iconColor = AppColors.errorColor;
      iconData = Icons.warning_amber_rounded;
    } else {
      iconColor = AppColors.accentGold;
      iconData = Icons.notifications_rounded;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: isRead
              ? (isDark ? AppColors.surfaceDark : Colors.white)
              : (isDark
                    ? AppColors.primaryLight.withValues(alpha: 0.15)
                    : const Color(0xFFEFF6FF)),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isRead
                ? (isDark
                      ? AppColors.cardBorderDark
                      : AppColors.cardBorderLight)
                : AppColors.primaryLight.withValues(alpha: 0.4),
            width: isRead ? 1 : 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(iconData, color: iconColor, size: 20.r),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.readerTitle(context.tr),
                          style: TextStyle(
                            fontWeight: isRead
                                ? FontWeight.bold
                                : FontWeight.w900,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    notification.readerBody(context.tr),
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
