import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/khadem_model.dart';

/// Reusable status card displayed while a servant is waiting for grade/stage assignment or rejected.
class PendingStatusCard extends StatelessWidget {
  final KhademModel? khadem;
  final String? serviceName;

  const PendingStatusCard({
    super.key,
    this.khadem,
    this.serviceName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isRejected = khadem?.isRejected ?? false;
    final hasService = khadem?.serviceId != null && khadem!.serviceId!.isNotEmpty;

    final cardBorderColor = isRejected
        ? AppColors.errorColor.withValues(alpha: 0.45)
        : AppColors.accentGold.withValues(alpha: 0.35);

    final iconColor = isRejected ? AppColors.errorColor : AppColors.accentGold;
    final iconBgColor = (isRejected ? AppColors.errorColor : AppColors.accentGold).withValues(alpha: 0.15);

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: cardBorderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.3 : 0.04,
            ),
            blurRadius: 16.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  isRejected ? Icons.highlight_off_rounded : Icons.hourglass_top_rounded,
                  color: iconColor,
                  size: 24.r,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRejected ? 'طلب الانضمام مرفوض مؤقتاً' : context.tr.pendingStatusTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.sp,
                        color: isRejected ? AppColors.errorColor : null,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        isRejected ? 'تنبيه من أمين الخدمة' : (hasService ? (serviceName ?? 'خدمة محددة') : context.tr.pendingRoleLabel),
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // Rejection reason banner if rejected
          if (isRejected) ...[
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.errorColor.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppColors.errorColor, size: 16.sp),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'سبب الرفض وملاحظات الإدارة:',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.errorColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    (khadem?.rejectionReason != null && khadem!.rejectionReason!.trim().isNotEmpty)
                        ? khadem!.rejectionReason!
                        : 'لم يتم ذكر سبب محدد للرفض.',
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'يرجى مراجعة البيانات أو تصحيح الخدمة التابع لها بالأسفل والضغط على "تعديل وإعادة تقديم الطلب" ليتم فحص حسابك مجدداً.',
              style: TextStyle(
                fontSize: 12.sp,
                height: 1.45,
                color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
              ),
            ),
          ] else if (hasService) ...[
            Text(
              'تم إرسال طلبك بنجاح وهو الآن قيد المراجعة لدى أمين "$serviceName". سيتم تفعيل حسابك وتسكينك في أقرب وقت. يمكنك تعديل بياناتك أو تغيير الخدمة في أي وقت بالأسفل.',
              style: TextStyle(
                fontSize: 12.5.sp,
                height: 1.5,
                color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
              ),
              textAlign: TextAlign.start,
            ),
          ] else ...[
            Text(
              'حسابك جديد وغير مسكن في أي خدمة بعد. يرجى ملء الحقول الإلزامية واختيار الخدمة التابع لها بالأسفل لتصل بياناتك لأمين الخدمة وتتم مراجعتها.',
              style: TextStyle(
                fontSize: 12.5.sp,
                height: 1.5,
                color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
              ),
              textAlign: TextAlign.start,
            ),
          ],
        ],
      ),
    );
  }
}
