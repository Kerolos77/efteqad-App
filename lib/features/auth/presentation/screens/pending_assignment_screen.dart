import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/repositories/auth_repository.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../core/session/session_state.dart';
import '../../../../core/utils/color_generator.dart';
import '../widgets/auth_widgets.dart';

class PendingAssignmentScreen extends StatefulWidget {
  const PendingAssignmentScreen({super.key});

  @override
  State<PendingAssignmentScreen> createState() =>
      _PendingAssignmentScreenState();
}

class _PendingAssignmentScreenState extends State<PendingAssignmentScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  bool _isSaving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    final session = context.read<SessionCubit>();
    _nameController = TextEditingController(
      text:
          session.state.profile?.name ??
          session.authIdentity?.displayName ??
          '',
    );
    _phoneController = TextEditingController(
      text: session.state.profile?.phone ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = context.read<SessionCubit>().state.userId;
    if (userId == null) return;

    setState(() => _isSaving = true);
    try {
      await _firestoreService.updateKhademProfile(
        id: userId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.profileUpdatedSuccess),
            backgroundColor: AppColors.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppFailure.fromException(e).localizedMessage(context.tr),
            ),
            backgroundColor: AppColors.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await context.read<SessionCubit>().signOut();
      if (mounted) context.go(AppRoutes.loginPath);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.dataUnavailable),
            backgroundColor: AppColors.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCubit>();
    if (session.state.userId == null) return const SizedBox.shrink();
    final user =
        session.authIdentity ??
        AuthIdentity(
          uid: session.state.userId!,
          email: session.state.profile?.email,
          displayName: session.state.profile?.name,
        );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userColor = ColorGenerator.getColorForId(user.email ?? user.uid);

    return BlocBuilder<SessionCubit, SessionState>(
      builder: (context, sessionState) {
        final khadem = sessionState.profile;

        // مزامنة الحقول عند أول جلب من فايرستور
        if (!_initialized && khadem != null) {
          _initialized = true;
          if (khadem.name.isNotEmpty) _nameController.text = khadem.name;
          if (khadem.phone.isNotEmpty) _phoneController.text = khadem.phone;
        }

        final displayName = (khadem?.name.isNotEmpty ?? false)
            ? khadem!.name
            : (user.displayName ?? '');

        return Scaffold(
          backgroundColor: isDark
              ? AppColors.backgroundDark
              : AppColors.backgroundLight,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(
                  Icons.logout_rounded,
                  color: AppColors.errorColor,
                  size: 22.r,
                ),
                tooltip: context.tr.signOut,
                onPressed: _handleSignOut,
              ),
              SizedBox(width: 8.w),
            ],
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 480.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // أيقونة الخادم وعنوان الترحيب
                    PendingServantAvatar(
                      displayName: displayName,
                      email: user.email ?? '',
                      userColor: userColor,
                    ),
                    SizedBox(height: 24.h),

                    // بطاقة حالة الانتظار (Status Hero Card)
                    const PendingStatusCard(),
                    SizedBox(height: 24.h),

                    // استمارة تأكيد الاسم ورقم الهاتف
                    PendingProfileForm(
                      formKey: _formKey,
                      nameController: _nameController,
                      phoneController: _phoneController,
                      isSaving: _isSaving,
                      onSave: _handleSaveProfile,
                    ),
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
