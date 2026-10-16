import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/responsive/responsive_breakpoints.dart';
import '../../../../core/services/auth_service.dart';
import '../widgets/auth_widgets.dart';

/// A modern, fully responsive Web Login Screen designed specifically for:
/// - Desktop / Laptop screens (Split-Screen layout with theological branding)
/// - Mobile Web Browsers (Adaptive compact single-card layout)
class LoginWebScreen extends StatefulWidget {
  const LoginWebScreen({super.key});

  @override
  State<LoginWebScreen> createState() => _LoginWebScreenState();
}

class _LoginWebScreenState extends State<LoginWebScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController(
    text: AppConstants.constAdminEmail,
  );
  final TextEditingController _passwordController = TextEditingController();

  bool _isGoogleLoading = false;
  bool _isAdminLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor:
            isError ? AppColors.errorColor : AppColors.successColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
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
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _handleAdminSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isAdminLoading = true);
    try {
      await _authService.signInAdmin(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } catch (e) {
      if (mounted) {
        _showMessage(
          AppFailure.fromException(e).localizedMessage(context.tr),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isAdminLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = context.isDesktopScreen;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF09121D) : const Color(0xFFF1F5F9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 1040 : 480,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: isDesktop
                  ? IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // الهيدر واللوجو للديسكتوب
                          const Expanded(child: WebAuthBrandingPanel()),
                          // استمارة تسجيل الدخول
                          Expanded(
                            child: WebAdminLoginForm(
                              formKey: _formKey,
                              emailController: _emailController,
                              passwordController: _passwordController,
                              isGoogleLoading: _isGoogleLoading,
                              isAdminLoading: _isAdminLoading,
                              obscurePassword: _obscurePassword,
                              onToggleObscurePassword: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                              onGoogleSignIn: _handleGoogleSignIn,
                              onAdminSignIn: _handleAdminSignIn,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // الهيدر لشاشات الموبايل في المتصفح
                        const WebAuthMobileHeader(),
                        // استمارة تسجيل الدخول
                        WebAdminLoginForm(
                          formKey: _formKey,
                          emailController: _emailController,
                          passwordController: _passwordController,
                          isGoogleLoading: _isGoogleLoading,
                          isAdminLoading: _isAdminLoading,
                          obscurePassword: _obscurePassword,
                          onToggleObscurePassword: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                          onGoogleSignIn: _handleGoogleSignIn,
                          onAdminSignIn: _handleAdminSignIn,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
