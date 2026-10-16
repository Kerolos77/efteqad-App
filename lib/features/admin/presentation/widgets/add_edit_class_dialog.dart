import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/class_model.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/services/firestore_service.dart';

class AddEditClassDialog extends StatefulWidget {
  final ClassModel? existing;
  final String gradeTitle;
  final String serviceId;
  final String gradeId;
  final List<KhademModel> khodamList;
  final FirestoreService firestoreService;

  const AddEditClassDialog({
    super.key,
    this.existing,
    required this.gradeTitle,
    required this.serviceId,
    required this.gradeId,
    required this.khodamList,
    required this.firestoreService,
  });

  static Future<void> show(
    BuildContext context, {
    ClassModel? existing,
    required String gradeTitle,
    required String serviceId,
    required String gradeId,
    required List<KhademModel> khodamList,
    required FirestoreService firestoreService,
  }) {
    return showDialog(
      context: context,
      builder: (_) => AddEditClassDialog(
        existing: existing,
        gradeTitle: gradeTitle,
        serviceId: serviceId,
        gradeId: gradeId,
        khodamList: khodamList,
        firestoreService: firestoreService,
      ),
    );
  }

  @override
  State<AddEditClassDialog> createState() => _AddEditClassDialogState();
}

class _AddEditClassDialogState extends State<AddEditClassDialog> {
  late final TextEditingController _nameCtrl;
  String? _selectedServantId;
  String? _selectedServantName;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _selectedServantId = widget.existing?.servantId;
    _selectedServantName = widget.existing?.servantName;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    Navigator.pop(context);
    if (widget.existing == null) {
      await widget.firestoreService.createClass(
        name: name,
        serviceId: widget.serviceId,
        gradeId: widget.gradeId,
        servantId: _selectedServantId,
        servantName: _selectedServantName,
      );
    } else {
      await widget.firestoreService.updateClass(
        classId: widget.existing!.id,
        name: name,
        servantId: _selectedServantId,
        servantName: _selectedServantName,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      title: Text(
        widget.existing == null ? 'إضافة فصل جديد' : 'تعديل بيانات الفصل',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'السنة: ${widget.gradeTitle}',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 14.h),
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'اسم الفصل (مثال: فصل القديس أبانوب / 1-أ)',
                prefixIcon: Icon(Icons.class_outlined, size: 20.sp),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 12.h,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'الخادم المسؤول عن الفصل (اختياري):',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            DropdownButtonFormField<String?>(
              initialValue: _selectedServantId,
              isExpanded: true,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.person_outline, size: 20.sp),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 10.h,
                ),
              ),
              hint: const Text('بدون تحديد خادم مسؤول'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    'بدون خادم مسؤول محدد',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
                ...widget.khodamList.map((k) {
                  return DropdownMenuItem<String?>(
                    value: k.id,
                    child: Text(k.name, overflow: TextOverflow.ellipsis),
                  );
                }),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedServantId = val;
                  if (val != null) {
                    try {
                      _selectedServantName = widget.khodamList
                          .firstWhere((k) => k.id == val)
                          .name;
                    } catch (_) {
                      _selectedServantName = null;
                    }
                  } else {
                    _selectedServantName = null;
                  }
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr.cancel),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child: Text(widget.existing == null ? 'إضافة' : 'حفظ التعديل'),
        ),
      ],
    );
  }
}
