import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';

class SplashTitle extends StatelessWidget {
  final bool isWeb;

  const SplashTitle({super.key, this.isWeb = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      context.tr.appName,
      style: TextStyle(
        fontSize: isWeb ? 36 : 34.sp,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        color: Colors.white,
        shadows: [
          Shadow(
            color: AppColors.sacredGold,
            blurRadius: isWeb ? 20 : 18.r,
          ),
        ],
      ),
    );
  }
}
