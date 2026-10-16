import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/auth_service.dart';

/// Bottom sheet dialog for Administrator credentials authentication.
class AdminLoginBottomSheet extends StatefulWidget {
  final void Function(String text, {bool isError})? onMessage;

  const AdminLoginBottomSheet({
    super.key,
    this.onMessage,
  });

  /// Helper static method to display the AdminLoginBottomSheet.
  static Future<void> show(
    BuildContext context, {
    void Function(String text, {bool isError})? onMessage,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AdminLoginBottomSheet(onMessage: onMessage),
    );
  }

  @override
  State<AdminLoginBottomSheet> createState() => _AdminLoginBottomSheetState();
}

class _AdminLoginBottomSheetState extends State<AdminLoginBottomSheet> {
  final AuthService _authService = AuthService();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: AppConstants.constAdminEmail,
    );
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      widget.onMessage?.call(
        context.tr.pleaseFillAllFields,
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.signInAdmin(
        email: email,
        password: password,
      );
      if (mounted) {
        final route = ModalRoute.of(context);
        if (route != null && route.isCurrent && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        widget.onMessage?.call(
          context.tr.loginFailedCheckCredentials,
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28.r),
          ),
          border: Border.all(
            color: isDark
                ? AppColors.cardBorderDark
                : AppColors.cardBorderLight,
          ),
        ),
        padding: EdgeInsetsDirectional.fromSTEB(24.w, 12.h, 24.w, 24.h),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: AppColors.accentGold,
                      size: 24.r,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr.adminSignInTitle,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          context.tr.adminSignInSubtitle,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              // Admin Email Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: context.tr.adminEmailLabel,
                  prefixIcon: Icon(
                    Icons.alternate_email,
                    size: 20.r,
                  ),
                ),
              ),
              SizedBox(height: 14.h),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: context.tr.passwordLabel,
                  prefixIcon: Icon(Icons.lock_outline, size: 20.r),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20.r,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              // Login Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 22.r,
                        height: 22.r,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.2,
                        ),
                      )
                    : Text(
                        context.tr.enterDashboardButton,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
