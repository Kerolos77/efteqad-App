import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';

class KhademAvatarCard extends StatelessWidget {
  final String name;
  final Color khademColor;
  final bool isDark;

  const KhademAvatarCard({
    super.key,
    required this.name,
    required this.khademColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim().isNotEmpty ? name.trim() : context.tr.messageStageServant;
    final initialChar = name.trim().isNotEmpty ? name.trim()[0] : context.tr.messageS;

    return Column(
      children: [
        Center(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 90.r,
                height: 90.r,
                decoration: BoxDecoration(
                  color: khademColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(28.r),
                  border: Border.all(
                    color: khademColor,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: khademColor.withValues(alpha: 0.25),
                      blurRadius: 20.r,
                      offset: Offset(0, 8.h),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initialChar,
                    style: TextStyle(
                      color: khademColor,
                      fontSize: 36.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: khademColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.backgroundDark : Colors.white,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.check,
                  size: 14.sp,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),
        Text(
          displayName,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 19.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 10.w,
            vertical: 3.h,
          ),
          decoration: BoxDecoration(
            color: khademColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Text(
            context.tr.verifiedServantBadge,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: khademColor,
            ),
          ),
        ),
      ],
    );
  }
}
