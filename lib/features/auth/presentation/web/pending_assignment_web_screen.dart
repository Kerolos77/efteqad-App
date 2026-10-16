import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/responsive/responsive_breakpoints.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/session/session_cubit.dart';
import '../widgets/auth_widgets.dart';

/// A modern responsive screen for newly registered servants waiting for grade assignment/approval.
class PendingAssignmentWebScreen extends StatefulWidget {
  const PendingAssignmentWebScreen({super.key});

  @override
  State<PendingAssignmentWebScreen> createState() =>
      _PendingAssignmentWebScreenState();
}

class _PendingAssignmentWebScreenState
    extends State<PendingAssignmentWebScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final session = context.read<SessionCubit>();
    _nameController = TextEditingController(
      text: session.state.profile?.name ??
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
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.dataUnavailable),
            backgroundColor: AppColors.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = context.isDesktopScreen;
    final isDark = theme.brightness == Brightness.dark;
    final sessionState = context.watch<SessionCubit>().state;
    final userEmail = sessionState.profile?.email ?? '';

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF09121D) : const Color(0xFFF1F5F9),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 24 : 16.r),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Container(
              padding: EdgeInsets.all(isDesktop ? 36 : 20.r),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(isDesktop ? 24 : 20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Emblem & Status Badge
                  const WebPendingStatusHeader(),
                  SizedBox(height: isDesktop ? 28 : 20.h),

                  // User Info / Edit Details Form
                  WebPendingProfileForm(
                    formKey: _formKey,
                    nameController: _nameController,
                    phoneController: _phoneController,
                    userEmail: userEmail,
                    isSaving: _isSaving,
                    onSave: _handleSaveProfile,
                  ),
                  SizedBox(height: isDesktop ? 28 : 20.h),

                  // Actions: Refresh & Sign Out
                  const WebPendingActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
