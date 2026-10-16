import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/repositories/account_repository.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/services/app_version_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/shorebird_updater_service.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../core/settings/settings_cubit.dart';
import '../../../../main.dart';
import '../../../common/widgets/app_update_dialog.dart';
import '../widgets/settings_widgets.dart';

abstract class AccountDeletionActions {
  String? get currentUserId;
  bool get requiresPassword;
  Future<void> deleteAccount({String? password});
}

class AuthAccountDeletionActions implements AccountDeletionActions {
  final AuthService? authService;
  final AccountRepository? accountRepository;

  AuthAccountDeletionActions({this.authService, this.accountRepository});

  AuthService get _auth => authService ?? AuthService();

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  bool get requiresPassword =>
      _auth.currentUser?.providerData.any((p) => p.providerId == 'password') ??
      false;

  @override
  Future<void> deleteAccount({String? password}) => _auth.deleteAccount(
        password: password,
        accountRepository: accountRepository,
      );
}

class SettingsScreen extends StatefulWidget {
  final AccountDeletionActions? accountActions;
  const SettingsScreen({super.key, this.accountActions});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AccountDeletionActions get _accountActions =>
      widget.accountActions ?? AuthAccountDeletionActions();
  bool _isDeleting = false;
  bool _isCheckingVersion = false;
  late final Stream<AppVersionInfo> _versionStream =
      AppVersionService.shared.watchVersion();
  final _deletePasswordController = TextEditingController();

  @override
  void dispose() {
    _deletePasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckForUpdates() async {
    if (_isCheckingVersion) return;
    setState(() => _isCheckingVersion = true);
    try {
      final info = await AppVersionService.shared.checkVersion();
      if (!mounted) return;
      setState(() => _isCheckingVersion = false);
      if (info.isUpdateAvailable()) {
        await AppUpdateDialog.show(context, versionInfo: info);
      } else {
        final shorebirdService = ShorebirdUpdaterService();
        String extraPatchText = '';
        if (shorebirdService.isAvailable) {
          final downloaded = await shorebirdService.checkAndDownloadPatch();
          if (!mounted) return;
          if (downloaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'تم تنزيل تحديث لحظي جديد بنجاح! سيتم تطبيقه تلقائياً عند إعادة فتح التطبيق.',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                backgroundColor: AppColors.primaryNavy,
                duration: Duration(seconds: 5),
              ),
            );
            return;
          }
          final patchNum = await shorebirdService.getCurrentPatchNumber();
          if (patchNum != null) {
            extraPatchText = ' (تحديث لحظي #$patchNum)';
          }
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'أنت تستخدم أحدث إصدار من التطبيق (v${AppConstants.appVersion}$extraPatchText) ✓',
            ),
            backgroundColor: AppColors.successColor,
            action: SnackBarAction(
              label: 'صفحة التحميل',
              textColor: Colors.white,
              onPressed: () =>
                  AppVersionService.shared.openDownloadPage(info.downloadUrl),
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCheckingVersion = false);
    }
  }

  Future<void> _selectLocale(Locale locale) async {
    try {
      await context.read<SettingsCubit>().setLocale(locale);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppFailure.fromException(error).localizedMessage(
                lookupGeneratedAppLocalizations(
                  context.read<SettingsCubit>().state.locale,
                ),
              ),
            ),
            action: SnackBarAction(
              label: context.tr.retryAction,
              onPressed: () => _selectLocale(locale),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await SignOutDialog.show(context);
    if (confirm == true && mounted) {
      try {
        await context.read<SessionCubit>().signOut();
        if (mounted) context.go(AppRoutes.loginPath);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr.dataUnavailable)),
          );
        }
      }
    }
  }

  bool _ownsDeletion(String uid) {
    final session = context.read<SessionCubit>().state;
    return session.userId == uid &&
        session.isAuthenticated &&
        !session.isDeleting &&
        _accountActions.currentUserId == uid;
  }

  Future<void> _handleDeleteAccount() async {
    final sessionState = context.read<SessionCubit>().state;
    final owner = sessionState.userId;
    if (owner == null) return;

    final confirm = await DeleteAccountWarningDialog.show(
      context,
      isStageAdmin: sessionState.isStageAdmin,
    );

    if (confirm == true && mounted) {
      if (!_ownsDeletion(owner)) return;
      final isPasswordProvider = _accountActions.requiresPassword;

      String? password;
      if (isPasswordProvider) {
        final passController = _deletePasswordController;
        passController.clear();
        final passConfirm = await ConfirmDeletePasswordDialog.show(
          context,
          controller: passController,
        );

        final enteredPassword = passController.text.trim();
        passController.clear();
        if (passConfirm != true || enteredPassword.isEmpty) return;
        password = enteredPassword;
      }

      if (!mounted || !_ownsDeletion(owner)) return;
      setState(() => _isDeleting = true);
      try {
        await _accountActions.deleteAccount(password: password);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr.messageYourDeletionRequestIsSavedYouCan),
              backgroundColor: AppColors.successColor,
            ),
          );
          context.go(AppRoutes.loginPath);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
          if (context.read<SessionCubit>().state.userId != owner) return;
          final failure = AppFailure.fromException(e);
          final errorMsg = context.read<SessionCubit>().state.isStageAdmin &&
                  failure.code == 'failed-precondition'
              ? context.tr.stageSuccessorRequired
              : failure.localizedMessage(context.tr);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: AppColors.errorColor,
            ),
          );
          try {
            await context.read<SettingsCubit>().refreshDeviceLocale();
          } catch (error) {
            debugPrint(
              'Device restoration after rejected deletion failed: $error',
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCubit>().state;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentMode, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: isDark
              ? AppColors.backgroundDark
              : AppColors.backgroundLight,
          appBar: AppBar(
            backgroundColor: isDark
                ? AppColors.backgroundDark
                : AppColors.backgroundLight,
            title: Text(
              context.tr.settingsTitle,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18.sp),
            ),
            centerTitle: true,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            physics: const BouncingScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 720.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SettingsAppearanceSection(isDark: isDark),
                    SizedBox(height: 20.h),
                    SettingsLanguageSection(
                      isDark: isDark,
                      onSelectLocale: _selectLocale,
                    ),
                    SizedBox(height: 20.h),
                    SettingsAboutSection(
                      isDark: isDark,
                      isCheckingVersion: _isCheckingVersion,
                      versionStream: _versionStream,
                      onCheckForUpdates: _handleCheckForUpdates,
                    ),
                    SizedBox(height: 20.h),
                    SettingsAccountSection(
                      isDark: isDark,
                      session: session,
                      isDeleting: _isDeleting,
                      onSignOut: _handleLogout,
                      onDeleteAccount: _handleDeleteAccount,
                    ),
                    SizedBox(height: 30.h),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
