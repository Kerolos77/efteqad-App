import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/services/firestore_service.dart';
import 'service_grade_input_row.dart';

class ServiceSetupDialog extends StatefulWidget {
  final ServiceModel service;
  final FirestoreService firestoreService;

  const ServiceSetupDialog({
    super.key,
    required this.service,
    required this.firestoreService,
  });

  static Future<void> show(
    BuildContext context, {
    required ServiceModel service,
    required FirestoreService firestoreService,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ServiceSetupDialog(
        service: service,
        firestoreService: firestoreService,
      ),
    );
  }

  @override
  State<ServiceSetupDialog> createState() => _ServiceSetupDialogState();
}

class _GradeInputItem {
  final String id;
  final TextEditingController nameController;
  final int order;

  _GradeInputItem({
    required this.id,
    required String name,
    required this.order,
  }) : nameController = TextEditingController(text: name);

  void dispose() {
    nameController.dispose();
  }
}

class _ServiceSetupDialogState extends State<ServiceSetupDialog> {
  late final TextEditingController _nameController;
  final List<_GradeInputItem> _grades = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service.name);

    if (widget.service.grades.isNotEmpty) {
      for (final g in widget.service.grades) {
        _grades.add(
          _GradeInputItem(
            id: g.id,
            name: g.name,
            order: g.order,
          ),
        );
      }
    } else {
      final count = widget.service.gradesCount > 0 ? widget.service.gradesCount : 3;
      for (var i = 1; i <= count; i++) {
        _grades.add(
          _GradeInputItem(
            id: 'grade_$i',
            name: 'سنة $i',
            order: i,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final g in _grades) {
      g.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال اسم الخدمة'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    for (var i = 0; i < _grades.length; i++) {
      if (_grades[i].nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('يرجى تحديد اسم للسنة رقم ${i + 1}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final serviceGrades = <ServiceGrade>[];
      for (var i = 0; i < _grades.length; i++) {
        serviceGrades.add(
          ServiceGrade(
            id: _grades[i].id.isNotEmpty ? _grades[i].id : 'grade_${i + 1}',
            name: _grades[i].nameController.text.trim(),
            order: i + 1,
          ),
        );
      }

      await widget.firestoreService.updateServiceName(
        serviceId: widget.service.id,
        newName: name,
      );

      await widget.firestoreService.updateServiceGrades(
        serviceId: widget.service.id,
        gradesCount: serviceGrades.length,
        grades: serviceGrades,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ وتحديث إعدادات الخدمة بنجاح'),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء الحفظ: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 580.w, maxHeight: 720.h),
        child: Padding(
          padding: EdgeInsets.all(18.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Icon(
                      Icons.settings_suggest_rounded,
                      color: AppColors.primaryLight,
                      size: 26.sp,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تخصيص مسميات الخدمة والسنوات',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'تعديل اسم الخدمة وتسمية كل سنة دراسية',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDark ? Colors.white60 : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // Scrollable Body
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Lock Notice Banner
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.primaryLight.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            color: AppColors.primaryLight,
                            size: 20.sp,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              'عدد السنوات الدراسية (${_grades.length} سنوات) معتمد من إدارة المنظومة. يمكنك تعديل اسم الخدمة وإعادة تسمية كل سنة دراسية بما يناسب خدمتك.',
                              style: TextStyle(fontSize: 12.sp, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // 1. Service Name Field
                    Text(
                      'اسم الخدمة',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.sp),
                    ),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: _nameController,
                      enabled: !_isSaving,
                      decoration: InputDecoration(
                        hintText: 'مثال: المرحلة الابتدائية، المرحلة الإعدادية...',
                        prefixIcon: Icon(Icons.church_rounded, size: 20.sp),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                      ),
                    ),
                    SizedBox(height: 18.h),

                    // 2. Grades List Header
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8.w,
                            runSpacing: 4.h,
                            children: [
                              Text(
                                'السنوات الدراسية',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.sp),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Text(
                                  '${_grades.length} سنوات',
                                  style: TextStyle(
                                    color: AppColors.primaryLight,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),

                    // 3. Grades Items
                    ..._grades.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final grade = entry.value;
                      return ServiceGradeInputRow(
                        index: idx,
                        controller: grade.nameController,
                        isSaving: _isSaving,
                        isDark: isDark,
                        canDelete: false,
                        onDelete: () {},
                      );
                    }),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 13.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 13.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      icon: _isSaving
                          ? SizedBox(
                              width: 18.w,
                              height: 18.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(Icons.save_rounded, size: 18.sp),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _isSaving ? 'جاري الحفظ...' : 'حفظ إعدادات الخدمة',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
