import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/attendance_session_model.dart';

class AttendanceExcuseDialog extends StatefulWidget {
  final String studentName;
  final AttendanceExcuse? existingExcuse;

  const AttendanceExcuseDialog({
    super.key,
    required this.studentName,
    this.existingExcuse,
  });

  static Future<String?> show(
    BuildContext context, {
    required String studentName,
    AttendanceExcuse? existingExcuse,
  }) {
    return showDialog<String?>(
      context: context,
      builder: (_) => AttendanceExcuseDialog(
        studentName: studentName,
        existingExcuse: existingExcuse,
      ),
    );
  }

  @override
  State<AttendanceExcuseDialog> createState() => _AttendanceExcuseDialogState();
}

class _AttendanceExcuseDialogState extends State<AttendanceExcuseDialog> {
  late final TextEditingController _controller;
  static const _quickReasons = ['مريض', 'مسافر', 'امتحانات', 'ظروف عائلية'];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.existingExcuse?.note ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.r),
      ),
      title: Row(
        children: [
          Icon(
            Icons.assignment_late_outlined,
            color: AppColors.accentGold,
            size: 22.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'تسجيل عذر غياب — ${widget.studentName}',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اختر سبباً سريعاً أو اكتب تفاصيل العذر:',
            style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: _quickReasons.map((reason) {
              final selected = _controller.text.trim() == reason;
              return ActionChip(
                label: Text(
                  reason,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : AppColors.primaryLight,
                  ),
                ),
                backgroundColor: selected
                    ? AppColors.primaryLight
                    : AppColors.primaryLight.withValues(alpha: 0.1),
                onPressed: () {
                  setState(() {
                    _controller.text = reason;
                  });
                },
              );
            }).toList(),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _controller,
            maxLines: 2,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: 'اكتب سبب الاعتذار هنا...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (widget.existingExcuse != null)
          TextButton.icon(
            onPressed: () => Navigator.pop(context, '__CLEAR__'),
            icon: Icon(
              Icons.delete_outline,
              size: 18.sp,
              color: AppColors.errorColor,
            ),
            label: const Text(
              'إلغاء العذر',
              style: TextStyle(color: AppColors.errorColor),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(context.tr.messageCancel),
        ),
        FilledButton(
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isEmpty) return;
            Navigator.pop(context, text);
          },
          child: const Text('حفظ العذر'),
        ),
      ],
    );
  }
}
