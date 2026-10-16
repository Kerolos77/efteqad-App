import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';

class AddTaskHeader extends StatelessWidget {
  final VoidCallback onClose;

  const AddTaskHeader({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(
            Icons.assignment_add,
            color: AppColors.primaryLight,
            size: 24.sp,
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Text(
            context.tr.addTaskTitle,
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, size: 20.sp),
          onPressed: onClose,
        ),
      ],
    );
  }
}
