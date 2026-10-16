import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';

/// Avatar and welcome greeting header for pending servants.
class PendingServantAvatar extends StatelessWidget {
  final String displayName;
  final String email;
  final Color userColor;

  const PendingServantAvatar({
    super.key,
    required this.displayName,
    required this.email,
    required this.userColor,
  });

  @override
  Widget build(BuildContext context) {
    final initial = displayName.isNotEmpty ? displayName[0] : context.tr.messageS;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Custom Avatar Circle
        Container(
          width: 80.r,
          height: 80.r,
          decoration: BoxDecoration(
            color: userColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: userColor, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: userColor.withValues(alpha: 0.2),
                blurRadius: 20.r,
                offset: Offset(0, 6.h),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 34.sp,
                fontWeight: FontWeight.w900,
                color: userColor,
              ),
            ),
          ),
        ),
        SizedBox(height: 18.h),

        // Welcome Title
        Text(
          context.tr.pendingWelcome,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
          ),
          textAlign: TextAlign.center,
        ),
        if (email.isNotEmpty) ...[
          SizedBox(height: 6.h),
          Text(
            email,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}
