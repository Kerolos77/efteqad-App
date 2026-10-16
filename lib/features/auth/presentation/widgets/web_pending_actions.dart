import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/responsive/responsive_breakpoints.dart';
import '../../../../core/session/session_cubit.dart';

/// Action buttons (Retry and Sign Out) for Web Pending Assignment screen.
class WebPendingActions extends StatelessWidget {
  const WebPendingActions({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final isDesktop = context.isDesktopScreen;

    return Row(
      children: [
        // Refresh status button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.read<SessionCubit>().retry(),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                vertical: isDesktop ? 14 : 12.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isDesktop ? 12 : 12.r),
              ),
            ),
            icon: Icon(
              Icons.refresh_rounded,
              size: isDesktop ? 18 : 18.r,
            ),
            label: Text(
              tr.retryAction,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: isDesktop ? 14 : 13.sp,
              ),
            ),
          ),
        ),
        SizedBox(width: isDesktop ? 14 : 12.w),

        // Sign out button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.read<SessionCubit>().signOut(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.errorColor,
              side: BorderSide(
                color: AppColors.errorColor.withValues(alpha: 0.4),
              ),
              padding: EdgeInsets.symmetric(
                vertical: isDesktop ? 14 : 12.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isDesktop ? 12 : 12.r),
              ),
            ),
            icon: Icon(
              Icons.logout_rounded,
              size: isDesktop ? 18 : 18.r,
            ),
            label: Text(
              tr.signOut,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: isDesktop ? 14 : 13.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
