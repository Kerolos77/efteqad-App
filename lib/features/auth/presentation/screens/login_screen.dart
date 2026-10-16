import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/auth_service.dart';
import '../widgets/admin_login_bottom_sheet.dart';
import '../widgets/admin_sign_in_button.dart';
import '../widgets/auth_branding_header.dart';
import '../widgets/google_sign_in_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AuthService get _authService => AuthService();
  bool _isLoading = false;

  void _showMessage(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isError
            ? AppColors.errorColor
            : AppColors.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      ),
    );
  }

  // تسجيل دخول الخادم بـ Google
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        _showMessage(
          AppFailure.fromException(e).localizedMessage(context.tr),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // فتح نافذة تسجيل دخول الأدمن
  void _showAdminLoginSheet() {
    AdminLoginBottomSheet.show(
      context,
      onMessage: _showMessage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // خلفية بتدرج ضوئي ناعم متجاوب
          Positioned(
            top: -100.h,
            right: -80.w,
            child: Container(
              width: 300.r,
              height: 300.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLight.withValues(
                  alpha: isDark ? 0.08 : 0.06,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60.h,
            left: -60.w,
            child: Container(
              width: 240.r,
              height: 240.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentGold.withValues(
                  alpha: isDark ? 0.05 : 0.04,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 24.h,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // هيدر الهوية وشعار الخدمة
                    const AuthBrandingHeader(),
                    SizedBox(height: 40.h),

                    // كارت خيارات تسجيل الدخول (Floating Surface Card)
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(
                          color: isDark
                              ? AppColors.cardBorderDark
                              : AppColors.cardBorderLight,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.25 : 0.04,
                            ),
                            blurRadius: 20.r,
                            offset: Offset(0, 6.h),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(22.r),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // زر تسجيل دخول الخادم بحساب Google
                          GoogleSignInButton(
                            onPressed: _handleGoogleSignIn,
                            isLoading: _isLoading,
                          ),
                          SizedBox(height: 18.h),

                          // فاصل ناعم
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: isDark
                                      ? Colors.white12
                                      : AppColors.cardBorderLight,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12.w),
                                child: Text(
                                  context.tr.or,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white38
                                        : AppColors.textMuted,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: isDark
                                      ? Colors.white12
                                      : AppColors.cardBorderLight,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 18.h),

                          // زر دخول الأدمن
                          AdminSignInButton(
                            onTap: _isLoading ? null : _showAdminLoginSheet,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32.h),

                    // رقم الإصدار
                    Text(
                      context.tr.version(AppConstants.appVersion),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
