import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/class_model.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/services/firestore_service.dart';

class ManageClassesDialog extends StatefulWidget {
  final String serviceId;
  final String gradeId;
  final String gradeTitle;
  final List<KhademModel> khodamList;
  final FirestoreService? firestoreService;

  const ManageClassesDialog({
    super.key,
    required this.serviceId,
    required this.gradeId,
    required this.gradeTitle,
    required this.khodamList,
    this.firestoreService,
  });

  static Future<void> show(
    BuildContext context, {
    required String serviceId,
    required String gradeId,
    required String gradeTitle,
    required List<KhademModel> khodamList,
    FirestoreService? firestoreService,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ManageClassesDialog(
        serviceId: serviceId,
        gradeId: gradeId,
        gradeTitle: gradeTitle,
        khodamList: khodamList,
        firestoreService: firestoreService,
      ),
    );
  }

  @override
  State<ManageClassesDialog> createState() => _ManageClassesDialogState();
}

class _ManageClassesDialogState extends State<ManageClassesDialog> {
  late final FirestoreService _firestore =
      widget.firestoreService ?? FirestoreService();

  void _openAddEditClassDialog([ClassModel? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    String? selectedServantId = existing?.servantId;
    String? selectedServantName = existing?.servantName;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              existing == null ? 'إضافة فصل جديد' : 'تعديل بيانات الفصل',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'السنة: ${widget.gradeTitle}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppConstants.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'اسم الفصل (مثال: فصل القديس أبانوب / 1-أ)',
                      prefixIcon: const Icon(Icons.class_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'الخادم المسؤول عن الفصل (اختياري):',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedServantId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    hint: const Text('بدون تحديد خادم مسؤول'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'بدون خادم مسؤول محدد',
                          style: TextStyle(color: AppConstants.textMuted),
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
                      setDialogState(() {
                        selectedServantId = val;
                        if (val != null) {
                          try {
                            selectedServantName = widget.khodamList
                                .firstWhere((k) => k.id == val)
                                .name;
                          } catch (_) {
                            selectedServantName = null;
                          }
                        } else {
                          selectedServantName = null;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(ctx.tr.cancel),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;

                  Navigator.pop(ctx);
                  if (existing == null) {
                    await _firestore.createClass(
                      name: name,
                      serviceId: widget.serviceId,
                      gradeId: widget.gradeId,
                      servantId: selectedServantId,
                      servantName: selectedServantName,
                    );
                  } else {
                    await _firestore.updateClass(
                      classId: existing.id,
                      name: name,
                      servantId: selectedServantId,
                      servantName: selectedServantName,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryLight,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(existing == null ? 'إضافة' : 'حفظ التعديل'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteClass(ClassModel c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الفصل'),
        content: Text(
          'هل أنت متأكد من حذف فصل "${c.name}"؟\nلن يتم حذف المخدومين ولكن سيتم إزالة تبعيتهم لهذا الفصل.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.tr.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _firestore.deleteClass(c.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.diversity_3_rounded,
                      color: AppConstants.primaryLight,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'إدارة فصول السنة',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          widget.gradeTitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppConstants.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Classes Stream List
              Expanded(
                child: StreamBuilder<List<ClassModel>>(
                  stream: _firestore.watchClasses(
                    serviceId: widget.serviceId,
                    gradeId: widget.gradeId,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final classes = snapshot.data ?? [];

                    if (classes.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 48,
                                color: isDark ? Colors.white30 : Colors.black26,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'لا توجد فصول بعد',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'يمكنك إضافة فصول إذا كنت ترغب في تقسيم مخدومي هذه السنة (مثلاً فصول بالأرقام أو بأسماء القديسين)، أو الإبقاء عليها كقائمة موحدة.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppConstants.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: classes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final c = classes[idx];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppConstants.surfaceDark
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? AppConstants.cardBorderDark
                                  : AppConstants.cardBorderLight,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppConstants.primaryLight
                                    .withValues(alpha: 0.12),
                                child: Text(
                                  c.name.isNotEmpty ? c.name[0] : 'ف',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.primaryLight,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    if (c.servantName != null &&
                                        c.servantName!.isNotEmpty)
                                      Text(
                                        'الخادم: ${c.servantName}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppConstants.textMuted,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: 'تعديل',
                                onPressed: () => _openAddEditClassDialog(c),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: AppConstants.errorColor,
                                ),
                                tooltip: 'حذف',
                                onPressed: () => _confirmDeleteClass(c),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),
              // Add Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openAddEditClassDialog(),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text(
                    'إضافة فصل جديد',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryLight,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
