import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';

class SplashVersePill extends StatelessWidget {
  final bool isWeb;

  const SplashVersePill({super.key, this.isWeb = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: isWeb ? const BoxConstraints(maxWidth: 520) : null,
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 20 : 16.w,
        vertical: isWeb ? 8 : 6.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.sacredGold.withValues(alpha: isWeb ? 0.12 : 0.15),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(
          color: AppColors.sacredGold.withValues(alpha: isWeb ? 0.35 : 0.4),
          width: 1,
        ),
      ),
      child: Text(
        context.tr.shepherdVerseGoodShepherd,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isWeb ? 13.5 : 12.5.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.sacredGold,
        ),
      ),
    );
  }
}
