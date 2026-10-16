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
  final Set<String> _selectedServantIds = {};

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    if (widget.existing != null) {
      if (widget.existing!.servantIds.isNotEmpty) {
        _selectedServantIds.addAll(widget.existing!.servantIds);
      } else if (widget.existing!.servantId != null &&
          widget.existing!.servantId!.isNotEmpty) {
        _selectedServantIds.add(widget.existing!.servantId!);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final selectedIds = _selectedServantIds.toList();
    final selectedNames = widget.khodamList
        .where((k) => _selectedServantIds.contains(k.id))
        .map((k) => k.name)
        .toList();

    Navigator.pop(context);
    if (widget.existing == null) {
      await widget.firestoreService.createClass(
        name: name,
        serviceId: widget.serviceId,
        gradeId: widget.gradeId,
        servantIds: selectedIds,
        servantNames: selectedNames,
      );
    } else {
      await widget.firestoreService.updateClass(
        classId: widget.existing!.id,
        name: name,
        servantIds: selectedIds,
        servantNames: selectedNames,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      title: Text(
        widget.existing == null ? 'إضافة فصل / صف جديد' : 'تعديل بيانات الفصل / الصف',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 420.w, maxHeight: 480.h),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'السنة الدراسية: ${widget.gradeTitle}',
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
                  labelText: 'اسم الفصل أو الصف (مثال: فصل القديس أبانوب / 1-أ)',
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
              SizedBox(height: 18.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'خدام الفصل (يمكن اختيار أكثر من خادم):',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                  ),
                  if (_selectedServantIds.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        '${_selectedServantIds.length} خدام',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8.h),
              if (widget.khodamList.isEmpty)
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    'لا يوجد خدام مسجلين في هذه السنة بعد. يمكنك إنشاء الفصل وتعيين الخدام لاحقاً.',
                    style: TextStyle(fontSize: 11.5.sp, color: AppColors.textMuted),
                  ),
                )
              else
                Container(
                  constraints: BoxConstraints(maxHeight: 200.h),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: widget.khodamList.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final k = widget.khodamList[idx];
                      final isSelected = _selectedServantIds.contains(k.id);
                      return CheckboxListTile(
                        dense: true,
                        value: isSelected,
                        title: Text(
                          k.name,
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: k.phone.isNotEmpty
                            ? Text(k.phone, style: TextStyle(fontSize: 10.5.sp))
                            : null,
                        secondary: CircleAvatar(
                          radius: 14.r,
                          backgroundColor: AppColors.primaryLight.withValues(alpha: 0.15),
                          child: Text(
                            k.name.isNotEmpty ? k.name[0] : 'خ',
                            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
                          ),
                        ),
                        activeColor: AppColors.primaryLight,
                        onChanged: (bool? checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedServantIds.add(k.id);
                            } else {
                              _selectedServantIds.remove(k.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
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
