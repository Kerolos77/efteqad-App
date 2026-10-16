import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/khadem_model.dart';

/// User profile and role branding header for AppDrawer.
class AppDrawerHeader extends StatelessWidget {
  final bool isAdmin;
  final KhademModel? user;
  final bool isDark;
  final Color khademColor;

  const AppDrawerHeader({
    super.key,
    required this.isAdmin,
    required this.user,
    required this.isDark,
    required this.khademColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isAdmin ? AppColors.accentGold : khademColor;

    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(20.w, 20.h, 20.w, 20.h),
      margin: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50.r,
            height: 50.r,
            decoration: BoxDecoration(
              color: effectiveColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: effectiveColor,
                width: 1.5,
              ),
            ),
            child: Center(
              child: isAdmin
                  ? Icon(
                      Icons.shield_rounded,
                      color: AppColors.accentGold,
                      size: 26.r,
                    )
                  : Text(
                      (user?.name != null && user!.name.isNotEmpty)
                          ? user!.name[0]
                          : context.tr.messageS,
                      style: TextStyle(
                        color: khademColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 20.sp,
                      ),
                    ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isAdmin
                            ? context.tr.headServant
                            : (user?.name ?? context.tr.servant),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 7.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: effectiveColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        isAdmin ? context.tr.adminRole : context.tr.servantRole,
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w800,
                          color: effectiveColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3.h),
                Text(
                  user?.email ?? AppConstants.constAdminEmail,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
