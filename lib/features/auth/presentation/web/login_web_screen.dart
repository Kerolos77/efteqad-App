import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/responsive/responsive_breakpoints.dart';
import '../../../../core/services/auth_service.dart';

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
        backgroundColor: isError ? AppConstants.errorColor : AppConstants.successColor,
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
      backgroundColor: isDark ? const Color(0xFF09121D) : const Color(0xFFF1F5F9),
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
                          // Left/Branding Side (Desktop Hero)
                          Expanded(child: _buildBrandingPanel(context)),
                          // Right/Form Side
                          Expanded(child: _buildFormPanel(context)),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMobileHeader(context),
                        _buildFormPanel(context),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// Desktop Left Hero Panel
  Widget _buildBrandingPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(44),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryNavy,
            AppConstants.primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App Church Emblem
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppConstants.sacredGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppConstants.sacredGold.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.church_rounded,
              color: AppConstants.sacredGold,
              size: 36,
            ),
          ),
          const SizedBox(height: 24),

          // App Name
          const Text(
            AppConstants.appName,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Theological Verse
          Text(
            AppConstants.appTagline,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppConstants.sacredGold,
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'منظومة المتابعة والافتقاد الذكية لخدمة التربية الكنسية، تتيح للخدام والأمناء رعاية المخدومين وإدارة الحضور بدقة واحترافية.',
            style: TextStyle(
              fontSize: 14,
              height: 1.7,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),

          const SizedBox(height: 36),

          // Highlights
          _buildFeatureBullet(
            icon: Icons.people_outline_rounded,
            title: 'رعاية وافتقاد المخدومين ومتابعة حالات الغياب',
          ),
          const SizedBox(height: 14),
          _buildFeatureBullet(
            icon: Icons.how_to_reg_outlined,
            title: 'تسجيل الحضور السريع والذكي في القداسات والخدمة',
          ),
          const SizedBox(height: 14),
          _buildFeatureBullet(
            icon: Icons.insights_outlined,
            title: 'إحصائيات وتقارير متقدمة وتصدير واستيراد ملفات الإكسل',
          ),

          const Spacer(),

          // Version badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'إصدار الويب ${AppConstants.appVersion}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Compact header for mobile browsers
  Widget _buildMobileHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryNavy,
            AppConstants.primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.sacredGold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.church_rounded,
              color: AppConstants.sacredGold,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            AppConstants.appName,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppConstants.appTagline,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppConstants.sacredGold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBullet({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppConstants.sacredGold, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Form Panel (Universal for Desktop & Mobile)
  Widget _buildFormPanel(BuildContext context) {
    final theme = Theme.of(context);
    final tr = context.tr;
    final isDesktop = context.isDesktopScreen;

    return Padding(
      padding: EdgeInsets.all(isDesktop ? 48.0 : 24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'تسجيل الدخول',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'سجل الدخول للمتابعة إلى حسابك في منصة افتقاد',
              style: TextStyle(
                fontSize: 13,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),

            const SizedBox(height: 28),

            // Google Sign-In Button
            SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: (_isGoogleLoading || _isAdminLoading) ? null : _handleGoogleSignIn,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: theme.dividerColor,
                    width: 1.2,
                  ),
                ),
                child: _isGoogleLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.google,
                            color: Color(0xFFEA4335),
                            size: 19,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            tr.continueWithGoogle,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Divider "أو"
            Row(
              children: [
                Expanded(child: Divider(color: theme.dividerColor)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    'أو بحساب المسؤول',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: theme.dividerColor)),
              ],
            ),

            const SizedBox(height: 22),

            // Email Input
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: tr.adminEmailLabel,
                hintText: 'admin@efteqad.com',
                prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                filled: true,
                fillColor: theme.brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.grey.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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

            const SizedBox(height: 14),

            // Password Input
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              onFieldSubmitted: (_) => _handleAdminSignIn(),
              decoration: InputDecoration(
                labelText: tr.passwordLabel,
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                filled: true,
                fillColor: theme.brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.grey.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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

            const SizedBox(height: 24),

            // Submit Admin Button
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: (_isGoogleLoading || _isAdminLoading) ? null : _handleAdminSignIn,
                style: FilledButton.styleFrom(
                  backgroundColor: AppConstants.primaryLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isAdminLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.login_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            tr.adminSignInButton,
                            style: const TextStyle(
                              fontSize: 15,
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
