import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/utils/color_generator.dart';

class ServantAssignmentBanner extends StatelessWidget {
  final KhademModel khadem;
  final VoidCallback onAssignPressed;

  const ServantAssignmentBanner({
    super.key,
    required this.khadem,
    required this.onAssignPressed,
  });

  @override
  Widget build(BuildContext context) {
    final khademColor = ColorGenerator.getColorForId(khadem.id);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      margin: EdgeInsetsDirectional.fromSTEB(16.w, 0, 16.w, 8.h),
      decoration: BoxDecoration(
        color: khademColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Icon(
            Icons.assignment_ind_rounded,
            size: 18.sp,
            color: khademColor,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              context.tr.servantGroupHeader(khadem.name),
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.bold,
                color: khademColor,
              ),
            ),
          ),
          TextButton(
            onPressed: onAssignPressed,
            child: Text(
              context.tr.assignChildrenBtn,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
