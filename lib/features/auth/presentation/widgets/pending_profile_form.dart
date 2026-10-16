import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';

/// Form widget allowing new servants to update/confirm their profile details (Name & Phone).
class PendingProfileForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final bool isSaving;
  final VoidCallback onSave;

  const PendingProfileForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
        ),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr.completeProfilePrompt,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.sp,
              ),
            ),
            SizedBox(height: 14.h),

            // Servant Full Name Field
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: context.tr.servantFullNameLabel,
                prefixIcon: Icon(
                  Icons.person_outline,
                  size: 20.r,
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return context.tr.servantNameRequired;
                }
                return null;
              },
            ),
            SizedBox(height: 14.h),

            // Servant Phone Field
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: context.tr.servantPhoneLabel,
                prefixIcon: Icon(
                  Icons.phone_outlined,
                  size: 20.r,
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return context.tr.servantPhoneRequired;
                }
                return null;
              },
            ),
            SizedBox(height: 18.h),

            // Save / Update Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : onSave,
                icon: isSaving
                    ? SizedBox(
                        width: 16.r,
                        height: 16.r,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        Icons.check_circle_outline,
                        size: 18.r,
                      ),
                label: Text(
                  context.tr.updateAndSave,
                  style: TextStyle(fontSize: 14.sp),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
