import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';

class SplashProgressIndicator extends StatelessWidget {
  final bool isWeb;

  const SplashProgressIndicator({super.key, this.isWeb = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isWeb ? 48 : 32.w,
      height: isWeb ? 3 : 2.5.h,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4.r),
        child: const LinearProgressIndicator(
          backgroundColor: Colors.white12,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.sacredGold),
        ),
      ),
    );
  }
}
