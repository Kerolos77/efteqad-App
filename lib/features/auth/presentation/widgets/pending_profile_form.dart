import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/models/service_model.dart';

/// Form widget allowing new servants to complete their required details (Name, Phone & Service).
class PendingProfileForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final String? selectedServiceId;
  final List<ServiceModel> services;
  final ValueChanged<String?> onServiceChanged;
  final bool isSaving;
  final bool isRejected;
  final VoidCallback onSave;

  const PendingProfileForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.selectedServiceId,
    required this.services,
    required this.onServiceChanged,
    required this.isSaving,
    this.isRejected = false,
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
            Row(
              children: [
                Icon(
                  Icons.edit_note_rounded,
                  color: AppColors.primaryLight,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    isRejected ? 'تعديل البيانات وإعادة التقديم' : 'استكمال بيانات الخادم الإلزامية',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              'يرجى التأكد من صحة بياناتك واختيار الخدمة التابع لها بدقة:',
              style: TextStyle(
                fontSize: 11.5.sp,
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(height: 16.h),

            // Servant Full Name Field
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'الاسم بالكامل (ثلاثي) *',
                hintText: 'مثال: مينا مجدي فوزي',
                prefixIcon: Icon(
                  Icons.person_outline,
                  size: 20.r,
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'يرجى كتابة الاسم بالكامل';
                }
                final parts = val.trim().split(RegExp(r'\s+'));
                if (parts.length < 2) {
                  return 'يرجى كتابة الاسم ثنائياً أو ثلاثياً على الأقل';
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
                labelText: 'رقم الهاتف للتواصل *',
                hintText: '01xxxxxxxxx',
                prefixIcon: Icon(
                  Icons.phone_outlined,
                  size: 20.r,
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'يرجى إدخال رقم الهاتف للتواصل';
                }
                final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
                if (clean.length < 10) {
                  return 'يرجى إدخال رقم هاتف صحيح (11 رقم)';
                }
                return null;
              },
            ),
            SizedBox(height: 14.h),

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
                  size: 20.r,
                ),
              ),
              items: services.map((s) {
                return DropdownMenuItem<String?>(
                  value: s.id,
                  child: Text(
                    s.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
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
            SizedBox(height: 20.h),

            // Save / Resubmit Button
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
                        isRejected ? Icons.replay_rounded : Icons.check_circle_outline,
                        size: 18.r,
                      ),
                label: Text(
                  isSaving
                      ? 'جاري حفظ البيانات...'
                      : (isRejected
                          ? 'تعديل وإعادة تقديم الطلب'
                          : 'حفظ وإرسال الطلب'),
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRejected ? AppColors.warningColor : AppColors.primaryLight,
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
