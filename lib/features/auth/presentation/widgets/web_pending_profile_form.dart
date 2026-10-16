import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/responsive/responsive_breakpoints.dart';

/// Web profile completion form for newly registered servants.
class WebPendingProfileForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final String userEmail;
  final bool isSaving;
  final VoidCallback onSave;

  const WebPendingProfileForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.userEmail,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = context.tr;
    final isDesktop = context.isDesktopScreen;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 20.0 : 16.0.r),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 16.r),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.badge_outlined,
                  color: AppColors.sacredGold,
                  size: isDesktop ? 20 : 20.r,
                ),
                SizedBox(width: isDesktop ? 8 : 8.w),
                Text(
                  tr.completeProfilePrompt,
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            if (userEmail.isNotEmpty) ...[
              SizedBox(height: isDesktop ? 8 : 6.h),
              Text(
                userEmail,
                style: TextStyle(
                  fontSize: isDesktop ? 12 : 12.sp,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
            SizedBox(height: isDesktop ? 18 : 16.h),

            // Name Field
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: tr.servantFullNameLabel,
                prefixIcon: Icon(
                  Icons.person_outline_rounded,
                  size: isDesktop ? 20 : 20.r,
                ),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isDesktop ? 12 : 12.r),
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? tr.servantNameRequired : null,
            ),
            SizedBox(height: isDesktop ? 14 : 12.h),

            // Phone Field
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: tr.servantPhoneLabel,
                prefixIcon: Icon(
                  Icons.phone_outlined,
                  size: isDesktop ? 20 : 20.r,
                ),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isDesktop ? 12 : 12.r),
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? tr.servantPhoneRequired : null,
            ),
            SizedBox(height: isDesktop ? 16 : 14.h),

            // Save Button
            ElevatedButton.icon(
              onPressed: isSaving ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: isDesktop ? 13 : 13.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isDesktop ? 12 : 12.r),
                ),
              ),
              icon: isSaving
                  ? SizedBox(
                      width: isDesktop ? 18 : 18.r,
                      height: isDesktop ? 18 : 18.r,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.save_outlined, size: isDesktop ? 18 : 18.r),
              label: Text(
                tr.updateAndSave,
                style: TextStyle(
                  fontSize: isDesktop ? 14 : 14.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
