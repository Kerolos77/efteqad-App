import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/responsive/responsive_breakpoints.dart';

/// Form component for Web Login Screen supporting Google auth and Admin credentials.
class WebAdminLoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isGoogleLoading;
  final bool isAdminLoading;
  final bool obscurePassword;
  final VoidCallback onToggleObscurePassword;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onAdminSignIn;

  const WebAdminLoginForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isGoogleLoading,
    required this.isAdminLoading,
    required this.obscurePassword,
    required this.onToggleObscurePassword,
    required this.onGoogleSignIn,
    required this.onAdminSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = context.tr;
    final isDesktop = context.isDesktopScreen;
    final isBusy = isGoogleLoading || isAdminLoading;

    return Padding(
      padding: EdgeInsets.all(isDesktop ? 48.0 : 24.0.r),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'تسجيل الدخول',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                fontSize: isDesktop ? null : 20.sp,
              ),
            ),
            SizedBox(height: isDesktop ? 6 : 6.h),
            Text(
              'سجل الدخول للمتابعة إلى حسابك في منصة افتقاد',
              style: TextStyle(
                fontSize: isDesktop ? 13 : 13.sp,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            SizedBox(height: isDesktop ? 28 : 24.h),

            // Google Sign-In Outlined Button
            SizedBox(
              height: isDesktop ? 50 : 50.h,
              child: OutlinedButton(
                onPressed: isBusy ? null : onGoogleSignIn,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 16 : 16.w,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isDesktop ? 12 : 12.r),
                  ),
                  side: BorderSide(
                    color: theme.dividerColor,
                    width: 1.2,
                  ),
                ),
                child: isGoogleLoading
                    ? SizedBox(
                        width: isDesktop ? 22 : 22.r,
                        height: isDesktop ? 22 : 22.r,
                        child: const CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(
                            FontAwesomeIcons.google,
                            color: const Color(0xFFEA4335),
                            size: isDesktop ? 19 : 19.r,
                          ),
                          SizedBox(width: isDesktop ? 12 : 12.w),
                          Text(
                            tr.continueWithGoogle,
                            style: TextStyle(
                              fontSize: isDesktop ? 14 : 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            SizedBox(height: isDesktop ? 24 : 20.h),

            // Divider "Or"
            Row(
              children: [
                Expanded(child: Divider(color: theme.dividerColor)),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 14 : 14.w,
                  ),
                  child: Text(
                    'أو بحساب المسؤول',
                    style: TextStyle(
                      fontSize: isDesktop ? 12 : 12.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: theme.dividerColor)),
              ],
            ),
            SizedBox(height: isDesktop ? 22 : 18.h),

            // Admin Email Input Field
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: tr.adminEmailLabel,
                hintText: 'admin@efteqad.com',
                prefixIcon: Icon(
                  Icons.alternate_email_rounded,
                  size: isDesktop ? 20 : 20.r,
                ),
                filled: true,
                fillColor: theme.brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.grey.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isDesktop ? 12 : 12.r),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return tr.pleaseFillAllFields;
                }
                return null;
              },
            ),
            SizedBox(height: isDesktop ? 14 : 14.h),

            // Password Field
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              onFieldSubmitted: (_) => onAdminSignIn(),
              decoration: InputDecoration(
                labelText: tr.passwordLabel,
                prefixIcon: Icon(
                  Icons.lock_outline_rounded,
                  size: isDesktop ? 20 : 20.r,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: isDesktop ? 20 : 20.r,
                  ),
                  onPressed: onToggleObscurePassword,
                ),
                filled: true,
                fillColor: theme.brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.grey.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isDesktop ? 12 : 12.r),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return tr.pleaseFillAllFields;
                }
                return null;
              },
            ),
            SizedBox(height: isDesktop ? 24 : 20.h),

            // Submit Admin Button
            SizedBox(
              height: isDesktop ? 50 : 50.h,
              child: FilledButton(
                onPressed: isBusy ? null : onAdminSignIn,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isDesktop ? 12 : 12.r),
                  ),
                ),
                child: isAdminLoading
                    ? SizedBox(
                        width: isDesktop ? 22 : 22.r,
                        height: isDesktop ? 22 : 22.r,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.login_rounded,
                            size: isDesktop ? 20 : 20.r,
                          ),
                          SizedBox(width: isDesktop ? 8 : 8.w),
                          Text(
                            tr.adminSignInButton,
                            style: TextStyle(
                              fontSize: isDesktop ? 15 : 15.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
