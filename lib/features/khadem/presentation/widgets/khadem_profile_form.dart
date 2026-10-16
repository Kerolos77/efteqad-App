import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';

class KhademProfileForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final bool isDark;

  const KhademProfileForm({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr.personalInfoSection,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 14.h),

          // 1. الاسم بالخدمة
          TextFormField(
            controller: nameController,
            style: TextStyle(fontSize: 14.sp),
            decoration: InputDecoration(
              labelText: context.tr.servantFullNameLabel,
              labelStyle: TextStyle(fontSize: 13.sp),
              prefixIcon: Icon(
                Icons.person_rounded,
                size: 20.sp,
              ),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? context.tr.servantNameRequired
                : null,
          ),
          SizedBox(height: 14.h),

          // 2. رقم التليفون
          TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            style: TextStyle(fontSize: 14.sp),
            decoration: InputDecoration(
              labelText: context.tr.servantPhoneLabel,
              labelStyle: TextStyle(fontSize: 13.sp),
              prefixIcon: Icon(
                Icons.phone_rounded,
                size: 20.sp,
              ),
            ),
          ),
          SizedBox(height: 14.h),

          // 3. البريد الإلكتروني (للقراءة فقط)
          TextFormField(
            controller: emailController,
            textDirection: TextDirection.ltr,
            readOnly: true,
            style: TextStyle(fontSize: 14.sp),
            decoration: InputDecoration(
              labelText: context.tr.googleEmailLabel,
              labelStyle: TextStyle(fontSize: 13.sp),
              prefixIcon: Icon(
                Icons.alternate_email_rounded,
                size: 20.sp,
              ),
              suffixIcon: Tooltip(
                message: context.tr.emailReadOnlyNote,
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 18.sp,
                ),
              ),
              filled: true,
              fillColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
            ),
          ),
        ],
      ),
    );
  }
}
