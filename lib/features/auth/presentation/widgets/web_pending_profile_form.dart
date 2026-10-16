import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/responsive/responsive_breakpoints.dart';

/// Web profile completion form for newly registered servants.
class WebPendingProfileForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final String? selectedServiceId;
  final List<ServiceModel> services;
  final ValueChanged<String?> onServiceChanged;
  final String userEmail;
  final bool isSaving;
  final bool isRejected;
  final VoidCallback onSave;

  const WebPendingProfileForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.selectedServiceId,
    required this.services,
    required this.onServiceChanged,
    required this.userEmail,
    required this.isSaving,
    this.isRejected = false,
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
                  isRejected ? 'تعديل البيانات وإعادة التقديم' : 'استكمال بيانات الخادم الإلزامية',
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
                labelText: 'الاسم بالكامل (ثلاثي) *',
                hintText: 'مثال: مينا مجدي فوزي',
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
              validator: (v) {
                if (v == null || v.trim().isEmpty) return tr.servantNameRequired;
                final parts = v.trim().split(RegExp(r'\s+'));
                if (parts.length < 2) return 'يرجى كتابة الاسم ثنائياً أو ثلاثياً على الأقل';
                return null;
              },
            ),
            SizedBox(height: isDesktop ? 14 : 12.h),

            // Phone Field
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف للتواصل *',
                hintText: '01xxxxxxxxx',
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
              validator: (v) {
                if (v == null || v.trim().isEmpty) return tr.servantPhoneRequired;
                final clean = v.replaceAll(RegExp(r'[^0-9]'), '');
                if (clean.length < 10) return 'يرجى إدخال رقم هاتف صحيح (11 رقم)';
                return null;
              },
            ),
            SizedBox(height: isDesktop ? 14 : 12.h),

            // Service Selector Dropdown
            DropdownButtonFormField<String?>(
              initialValue: (selectedServiceId != null &&
                      services.any((s) => s.id == selectedServiceId))
                  ? selectedServiceId
                  : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'الخدمة التابع لها *',
                hintText: 'اختر الخدمة (ابتدائي، إعدادي، ثانوي...)',
                prefixIcon: Icon(
                  Icons.church_outlined,
                  size: isDesktop ? 20 : 20.r,
                ),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isDesktop ? 12 : 12.r),
                ),
              ),
              items: services.map((s) {
                return DropdownMenuItem<String?>(
                  value: s.id,
                  child: Text(
                    s.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                );
              }).toList(),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'يرجى اختيار الخدمة التي تخدم بها';
                }
                return null;
              },
              onChanged: onServiceChanged,
            ),
            SizedBox(height: isDesktop ? 18 : 16.h),

            // Save / Resubmit Button
            ElevatedButton.icon(
              onPressed: isSaving ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: isRejected ? AppColors.warningColor : AppColors.primaryLight,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: isDesktop ? 14 : 14.h,
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
                  : Icon(isRejected ? Icons.replay_rounded : Icons.save_outlined, size: isDesktop ? 18 : 18.r),
              label: Text(
                isSaving
                    ? 'جاري حفظ البيانات...'
                    : (isRejected ? 'تعديل وإعادة تقديم الطلب' : 'حفظ وإرسال الطلب'),
                style: TextStyle(
                  fontSize: isDesktop ? 14 : 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
