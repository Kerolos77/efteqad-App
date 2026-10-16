import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/responsive/responsive_breakpoints.dart';

import '../../../../core/models/khadem_model.dart';

/// Status emblem and title header for Web Pending Assignment screen.
class WebPendingStatusHeader extends StatelessWidget {
  final KhademModel? khadem;
  final String? serviceName;

  const WebPendingStatusHeader({
    super.key,
    this.khadem,
    this.serviceName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = context.tr;
    final isDesktop = context.isDesktopScreen;
    final isRejected = khadem?.isRejected ?? false;
    final hasService = khadem?.serviceId != null && khadem!.serviceId!.isNotEmpty;

    final gradientColors = isRejected
        ? [AppColors.errorColor, const Color(0xFFD32F2F)]
        : const [AppColors.primaryNavy, AppColors.primaryLight];

    final iconBadgeColor = isRejected ? AppColors.errorColor : AppColors.sacredGold;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // App Emblem & Status Badge
        Center(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: isDesktop ? 84 : 84.r,
                height: isDesktop ? 84 : 84.r,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isRejected ? AppColors.errorColor : AppColors.primaryLight).withValues(alpha: 0.3),
                      blurRadius: isDesktop ? 16 : 16.r,
                      offset: Offset(0, isDesktop ? 6 : 6.h),
                    ),
                  ],
                ),
                child: Icon(
                  isRejected ? Icons.highlight_off_rounded : Icons.hourglass_top_rounded,
                  color: isRejected ? Colors.white : AppColors.sacredGold,
                  size: isDesktop ? 40 : 40.r,
                ),
              ),
              Container(
                padding: EdgeInsets.all(isDesktop ? 6 : 6.r),
                decoration: BoxDecoration(
                  color: iconBadgeColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRejected ? Icons.close_rounded : Icons.check_rounded,
                  color: isRejected ? Colors.white : AppColors.primaryNavy,
                  size: isDesktop ? 16 : 16.r,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isDesktop ? 24 : 20.h),

        // Title & Description
        Text(
          isRejected ? 'طلب الانضمام مرفوض مؤقتاً' : tr.pendingStatusTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            fontSize: isDesktop ? null : 20.sp,
            color: isRejected ? AppColors.errorColor : null,
          ),
        ),
        SizedBox(height: isDesktop ? 10 : 8.h),

        if (isRejected) ...[
          Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: EdgeInsets.all(isDesktop ? 14 : 12.r),
            decoration: BoxDecoration(
              color: AppColors.errorColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(isDesktop ? 12 : 12.r),
              border: Border.all(
                color: AppColors.errorColor.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.errorColor,
                      size: isDesktop ? 18 : 18.r,
                    ),
                    SizedBox(width: isDesktop ? 8 : 6.w),
                    Text(
                      'ملاحظات وسبب الرفض من الإدارة:',
                      style: TextStyle(
                        fontSize: isDesktop ? 13 : 12.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.errorColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isDesktop ? 6 : 4.h),
                Text(
                  (khadem?.rejectionReason != null && khadem!.rejectionReason!.trim().isNotEmpty)
                      ? khadem!.rejectionReason!
                      : 'لم يتم ذكر سبب محدد للرفض.',
                  style: TextStyle(
                    fontSize: isDesktop ? 13 : 12.sp,
                    color: theme.textTheme.bodyMedium?.color,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isDesktop ? 10 : 8.h),
          Text(
            'يرجى مراجعة وتعديل بياناتك أو الخدمة المختارة بالأسفل ثم الضغط على "تعديل وإعادة تقديم الطلب".',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isDesktop ? 13 : 12.sp,
              height: 1.5,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ] else if (hasService) ...[
          Text(
            'طلبك قيد المراجعة حالياً لدى أمين "$serviceName". يمكنك مراجعة وتحديث بياناتك أو اختيار خدمة أخرى بالأسفل في أي وقت.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isDesktop ? 14 : 13.sp,
              height: 1.6,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
            ),
          ),
        ] else ...[
          Text(
            'حسابك جديد وغير مسكن في أي خدمة بعد. يرجى ملء الحقول الإلزامية واختيار خدمتك بالأسفل ليتم إرسال طلبك إلى أمين الخدمة.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isDesktop ? 14 : 13.sp,
              height: 1.6,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
            ),
          ),
        ],
      ],
    );
  }
}
