import 'package:efteqad/core/errors/app_failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../core/utils/color_generator.dart';
import '../widgets/khadem_assigned_count_card.dart';
import '../widgets/khadem_avatar_card.dart';
import '../widgets/khadem_profile_form.dart';

class KhademProfileScreen extends StatefulWidget {
  const KhademProfileScreen({super.key});

  @override
  State<KhademProfileScreen> createState() => _KhademProfileScreenState();
}

class _KhademProfileScreenState extends State<KhademProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  AuthService get _authService => AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  bool _isLoading = true;
  bool _isSaving = false;
  KhademModel? _currentKhadem;

  @override
  void initState() {
    super.initState();
    final session = context.read<SessionCubit>();
    _currentKhadem = session.state.profile;
    _nameController = TextEditingController(
      text: _currentKhadem?.name ?? session.authIdentity?.displayName ?? '',
    );
    _phoneController = TextEditingController(text: _currentKhadem?.phone ?? '');
    _emailController = TextEditingController(
      text: _currentKhadem?.email ?? session.authIdentity?.email ?? '',
    );
    _isLoading = false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    final newName = _nameController.text.trim();
    final newPhone = _phoneController.text.trim();

    try {
      // 1. تحديث الاسم في Firebase Auth
      await user.updateDisplayName(newName);

      // 2. تحديث الاسم والتليفون في Firestore
      await _firestoreService.updateKhademProfile(
        id: user.uid,
        name: newName,
        phone: newPhone,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.profileUpdatedSuccess),
            backgroundColor: AppColors.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.bootstrapPath);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppFailure.fromException(e).localizedMessage(context.tr),
            ),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = context.watch<SessionCubit>().state;
    final khademColor = ColorGenerator.getColorForId(
      session.profile?.email ?? session.userId,
    );

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          context.tr.profileTitle,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18.sp),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // بطاقة الأفاتار
                        KhademAvatarCard(
                          name: _nameController.text,
                          khademColor: khademColor,
                          isDark: isDark,
                        ),
                        SizedBox(height: 24.h),

                        // كارت إحصائية المخدومين التابعين له
                        if (_currentKhadem != null) ...[
                          KhademAssignedCountCard(
                            count: _currentKhadem!.assignedCount,
                            isDark: isDark,
                          ),
                          SizedBox(height: 20.h),
                        ],

                        // حقول التعديل
                        KhademProfileForm(
                          nameController: _nameController,
                          phoneController: _phoneController,
                          emailController: _emailController,
                          isDark: isDark,
                        ),
                        SizedBox(height: 28.h),

                        // زر حفظ التعديلات
                        SizedBox(
                          width: double.infinity,
                          height: 52.h,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _handleSave,
                            icon: _isSaving
                                ? SizedBox(
                                    width: 20.r,
                                    height: 20.r,
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(Icons.check_circle_rounded, size: 20.sp),
                            label: Text(
                              _isSaving ? '...' : context.tr.saveChanges,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15.sp,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: khademColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              elevation: 0,
                            ),
                          ),
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
