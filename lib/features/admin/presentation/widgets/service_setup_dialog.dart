import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/services/firestore_service.dart';

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
      // Default to Thanawy if empty
      _applyTemplate('thanawy');
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

  void _applyTemplate(String type) {
    setState(() {
      for (final g in _grades) {
        g.dispose();
      }
      _grades.clear();

      switch (type) {
        case 'ebtedai':
          if (_nameController.text.trim().isEmpty || _nameController.text == 'خدمة جديدة') {
            _nameController.text = 'المرحلة الابتدائية';
          }
          final names = [
            'الصف الأول الابتدائي',
            'الصف الثاني الابتدائي',
            'الصف الثالث الابتدائي',
            'الصف الرابع الابتدائي',
            'الصف الخامس الابتدائي',
            'الصف السادس الابتدائي',
          ];
          for (var i = 0; i < names.length; i++) {
            _grades.add(
              _GradeInputItem(
                id: 'grade_${i + 1}',
                name: names[i],
                order: i + 1,
              ),
            );
          }
          break;

        case 'e3dady':
          if (_nameController.text.trim().isEmpty || _nameController.text == 'خدمة جديدة') {
            _nameController.text = 'المرحلة الإعدادية';
          }
          final names = [
            'الصف الأول الإعدادي',
            'الصف الثاني الإعدادي',
            'الصف الثالث الإعدادي',
          ];
          for (var i = 0; i < names.length; i++) {
            _grades.add(
              _GradeInputItem(
                id: 'grade_${i + 1}',
                name: names[i],
                order: i + 1,
              ),
            );
          }
          break;

        case 'thanawy':
          if (_nameController.text.trim().isEmpty || _nameController.text == 'خدمة جديدة') {
            _nameController.text = 'المرحلة الثانوية';
          }
          _grades.addAll([
            _GradeInputItem(
              id: AppConstants.grade1st,
              name: 'الصف الأول الثانوي',
              order: 1,
            ),
            _GradeInputItem(
              id: AppConstants.grade2nd,
              name: 'الصف الثاني الثانوي',
              order: 2,
            ),
            _GradeInputItem(
              id: AppConstants.grade3rd,
              name: 'الصف الثالث الثانوي',
              order: 3,
            ),
          ]);
          break;

        case 'gam3a':
          if (_nameController.text.trim().isEmpty || _nameController.text == 'خدمة جديدة') {
            _nameController.text = 'مرحلة إعداد خدام وخريجين';
          }
          final names = [
            'الفرقة الأولى',
            'الفرقة الثانية',
            'الفرقة الثالثة',
            'الفرقة الرابعة',
          ];
          for (var i = 0; i < names.length; i++) {
            _grades.add(
              _GradeInputItem(
                id: 'grade_${i + 1}',
                name: names[i],
                order: i + 1,
              ),
            );
          }
          break;
      }
    });
  }

  void _addGrade() {
    setState(() {
      final nextOrder = _grades.length + 1;
      _grades.add(
        _GradeInputItem(
          id: 'grade_$nextOrder',
          name: 'الصف $nextOrder',
          order: nextOrder,
        ),
      );
    });
  }

  void _removeGrade(int index) {
    if (_grades.length <= 1) return;
    setState(() {
      final removed = _grades.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('برجاء كتابة اسم الخدمة'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    if (_grades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('برجاء إضافة سنة دراسية / صف واحد على الأقل'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final serviceGrades = <ServiceGrade>[];
      for (var i = 0; i < _grades.length; i++) {
        final item = _grades[i];
        final gradeName = item.nameController.text.trim().isNotEmpty
            ? item.nameController.text.trim()
            : 'الصف ${i + 1}';
        serviceGrades.add(
          ServiceGrade(
            id: item.id.isNotEmpty ? item.id : 'grade_${i + 1}',
            name: gradeName,
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
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء الحفظ: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.settings_suggest_rounded,
                      color: AppConstants.primaryLight,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تخصيص وإعداد الخدمة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'حدد اسم الخدمة وعدد السنوات وأسماء كل صف',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : AppConstants.textMuted,
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
              const SizedBox(height: 20),

              // Scrollable Body
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // 1. Service Name Field
                    const Text(
                      'اسم الخدمة',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      enabled: !_isSaving,
                      decoration: InputDecoration(
                        hintText: 'مثال: المرحلة الابتدائية، المرحلة الإعدادية...',
                        prefixIcon: const Icon(Icons.church_rounded, size: 20),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 2. Quick Templates
                    const Text(
                      'نماذج سريعة للتعبئة',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTemplateChip(
                          label: 'ابتدائي (6 سنين)',
                          icon: Icons.school_outlined,
                          onTap: () => _applyTemplate('ebtedai'),
                          isDark: isDark,
                        ),
                        _buildTemplateChip(
                          label: 'إعدادي (3 سنين)',
                          icon: Icons.menu_book_outlined,
                          onTap: () => _applyTemplate('e3dady'),
                          isDark: isDark,
                        ),
                        _buildTemplateChip(
                          label: 'ثانوي (3 سنين)',
                          icon: Icons.account_balance_outlined,
                          onTap: () => _applyTemplate('thanawy'),
                          isDark: isDark,
                        ),
                        _buildTemplateChip(
                          label: 'جامعة / خريجين (4)',
                          icon: Icons.military_tech_outlined,
                          onTap: () => _applyTemplate('gam3a'),
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 3. Grades List Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'الصفوف والسنوات الدراسية',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppConstants.primaryLight.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_grades.length} صفوف',
                                style: const TextStyle(
                                  color: AppConstants.primaryLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _isSaving ? null : _addGrade,
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                          label: const Text('إضافة صف', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 4. Grades Items
                    ..._grades.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final grade = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.white10 : Colors.black12,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppConstants.primaryLight.withValues(alpha: 0.15),
                                child: Text(
                                  '${idx + 1}',
                                  style: const TextStyle(
                                    color: AppConstants.primaryLight,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: grade.nameController,
                                  enabled: !_isSaving,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    hintText: 'اسم الصف (مثال: الصف الأول الابتدائي)',
                                    hintStyle: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.white38 : AppConstants.textMuted,
                                    ),
                                  ),
                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (_grades.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                  color: AppConstants.errorColor.withValues(alpha: 0.7),
                                  tooltip: 'حذف هذا الصف',
                                  onPressed: _isSaving ? null : () => _removeGrade(idx),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryLight,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(
                        _isSaving ? 'جاري الحفظ...' : 'حفظ إعدادات الخدمة',
                        style: const TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildTemplateChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: _isSaving ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppConstants.primaryLight),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
