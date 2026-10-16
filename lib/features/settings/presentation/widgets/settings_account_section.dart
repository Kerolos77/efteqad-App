import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/session/session_state.dart';
import 'settings_card.dart';
import 'settings_section_title.dart';

class SettingsAccountSection extends StatelessWidget {
  final bool isDark;
  final SessionState session;
  final bool isDeleting;
  final VoidCallback onSignOut;
  final VoidCallback onDeleteAccount;

  const SettingsAccountSection({
    super.key,
    required this.isDark,
    required this.session,
    required this.isDeleting,
    required this.onSignOut,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionTitle(
          title: context.tr.accountSection,
          icon: Icons.security_outlined,
        ),
        SettingsCard(
          isDark: isDark,
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                leading: Icon(
                  Icons.logout_rounded,
                  color: AppColors.errorColor,
                  size: 22.sp,
                ),
                title: Text(
                  context.tr.signOut,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
                subtitle: Text(
                  context.tr.signOutAccountDesc,
                  style: TextStyle(fontSize: 11.sp),
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 14.sp),
                onTap: onSignOut,
              ),
              if (session.isAuthenticated && !session.isDeleting) ...[
                Divider(
                  height: 1,
                  color: isDark
                      ? AppColors.cardBorderDark
                      : AppColors.cardBorderLight,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  leading: isDeleting
                      ? SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: const CircularProgressIndicator(
                            color: AppColors.errorColor,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          Icons.delete_forever_rounded,
                          color: AppColors.errorColor,
                          size: 22.sp,
                        ),
                  title: Text(
                    context.tr.deleteAccount,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                      color: AppColors.errorColor,
                    ),
                  ),
                  subtitle: Text(
                    session.isStageAdmin
                        ? context.tr.stageSuccessorRequired
                        : context.tr.deleteAccountDesc,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.errorColor,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 14.sp,
                    color: AppColors.errorColor,
                  ),
                  onTap: isDeleting ? null : onDeleteAccount,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
