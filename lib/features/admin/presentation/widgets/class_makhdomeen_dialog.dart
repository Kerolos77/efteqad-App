import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/class_model.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/trusted_mutations.dart';

class ClassMakhdomeenDialog extends StatefulWidget {
  final ClassModel classModel;
  final String gradeTitle;
  final FirestoreService firestoreService;

  const ClassMakhdomeenDialog({
    super.key,
    required this.classModel,
    required this.gradeTitle,
    required this.firestoreService,
  });

  static Future<void> show(
    BuildContext context, {
    required ClassModel classModel,
    required String gradeTitle,
    required FirestoreService firestoreService,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ClassMakhdomeenDialog(
        classModel: classModel,
        gradeTitle: gradeTitle,
        firestoreService: firestoreService,
      ),
    );
  }

  @override
  State<ClassMakhdomeenDialog> createState() => _ClassMakhdomeenDialogState();
}

class _ClassMakhdomeenDialogState extends State<ClassMakhdomeenDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Set<String>? _selectedIds;
  Set<String>? _initialIds;
  bool _isSaving = false;
  bool _assignToClassServant = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSave(List<MakhdomModel> allStudents) async {
    if (_isSaving || _selectedIds == null) return;

    setState(() => _isSaving = true);
    try {
      final currentSelection = _selectedIds!;
      final initialSelection = _initialIds ?? {};

      final addedIds = currentSelection.difference(initialSelection).toList();
      final removedIds = initialSelection.difference(currentSelection).toList();

      if (addedIds.isNotEmpty) {
        await widget.firestoreService.bulkAssignMakhdomeenToClass(
          makhdomIds: addedIds,
          classId: widget.classModel.id,
          className: widget.classModel.name,
        );
      }

      if (removedIds.isNotEmpty) {
        await widget.firestoreService.bulkAssignMakhdomeenToClass(
          makhdomIds: removedIds,
          classId: null,
          className: null,
        );
      }

      // إذا اختار تسكين المخدومين أيضاً على خادم الفصل
      if (_assignToClassServant &&
          widget.classModel.servantIds.isNotEmpty &&
          addedIds.isNotEmpty) {
        final servantId = widget.classModel.servantIds.first;
        final servantName = widget.classModel.servantNames.isNotEmpty
            ? widget.classModel.servantNames.first
            : (widget.classModel.servantName ?? '');

        final expected = <String, String?>{
          for (final id in addedIds)
            id: allStudents.where((m) => m.id == id).firstOrNull?.assignedKhademId,
        };

        try {
          await widget.firestoreService.assignMakhdomeenToKhadem(
            khademId: servantId,
            khademName: servantName,
            makhdomeenIds: addedIds,
            expectedAssignments: expected,
            operationId: newOperationId('class_assign'),
          );
        } catch (_) {}
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحديث مخدومي فصل "${widget.classModel.name}" بنجاح'),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء الحفظ: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = widget.classModel;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 550.w, maxHeight: 680.h),
        child: Padding(
          padding: EdgeInsets.all(20.r),
          child: StreamBuilder<List<MakhdomModel>>(
            stream: widget.firestoreService.getMakhdomeenByGradeStream(
              c.gradeId,
              serviceId: c.serviceId,
            ),
            builder: (context, snapshot) {
              final allStudents = snapshot.data ?? [];

              if (_selectedIds == null && snapshot.hasData) {
                _initialIds = allStudents
                    .where((m) => m.classId == c.id)
                    .map((m) => m.id)
                    .toSet();
                _selectedIds = Set.from(_initialIds!);
              }

              final filteredList = allStudents.where((m) {
                if (_searchQuery.isEmpty) return true;
                final q = _searchQuery.toLowerCase();
                return m.fullName.toLowerCase().contains(q) ||
                    m.area.toLowerCase().contains(q) ||
                    m.phone.contains(q);
              }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الهيدر
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.diversity_3_rounded,
                          color: AppColors.primaryLight,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مخدومي فصل: ${c.name}',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16.sp,
                              ),
                            ),
                            Text(
                              c.servantNames.isNotEmpty
                                  ? 'الخدام: ${c.servantNames.join("، ")}'
                                  : (c.servantName != null && c.servantName!.isNotEmpty
                                      ? 'الخادم: ${c.servantName}'
                                      : widget.gradeTitle),
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.textMuted,
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
                  SizedBox(height: 12.h),
                  const Divider(height: 1),
                  SizedBox(height: 10.h),

                  // حقل البحث
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: 'بحث في مخدومي السنة بالاسم أو المنطقة...',
                      prefixIcon: Icon(Icons.search_rounded, size: 20.sp),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded, size: 18.sp),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 10.h,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.surfaceDark
                          : AppColors.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // شريط تحديد الكل وإلغاء التحديد
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'محدد لهذا الفصل: ${_selectedIds?.length ?? 0} من ${allStudents.length}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedIds ??= {};
                            _selectedIds!.addAll(filteredList.map((m) => m.id));
                          });
                        },
                        child: Text(
                          context.tr.selectAll,
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedIds ??= {};
                            for (final m in filteredList) {
                              _selectedIds!.remove(m.id);
                            }
                          });
                        },
                        child: Text(
                          context.tr.deselectAll,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),

                  // قائمة المخدومين
                  Expanded(
                    child: snapshot.connectionState == ConnectionState.waiting
                        ? const Center(child: CircularProgressIndicator())
                        : filteredList.isEmpty
                            ? Center(
                                child: Text(
                                  'لا يوجد مخدومين يطابقون البحث',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: filteredList.length,
                                separatorBuilder: (_, __) =>
                                    SizedBox(height: 6.h),
                                itemBuilder: (context, idx) {
                                  final m = filteredList[idx];
                                  final isChecked =
                                      _selectedIds?.contains(m.id) ?? false;
                                  final isInOtherClass = m.classId != null &&
                                      m.classId != c.id;

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: isChecked
                                          ? AppColors.primaryLight.withValues(
                                              alpha: isDark ? 0.12 : 0.06,
                                            )
                                          : (isDark
                                              ? AppColors.surfaceDark
                                              : Colors.white),
                                      borderRadius:
                                          BorderRadius.circular(12.r),
                                      border: Border.all(
                                        color: isChecked
                                            ? AppColors.primaryLight.withValues(
                                                alpha: 0.5,
                                              )
                                            : (isDark
                                                ? AppColors.cardBorderDark
                                                : AppColors.cardBorderLight),
                                      ),
                                    ),
                                    child: CheckboxListTile(
                                      value: isChecked,
                                      dense: true,
                                      title: Text(
                                        m.fullName,
                                        style: TextStyle(
                                          fontWeight: isChecked
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          fontSize: 13.5.sp,
                                        ),
                                      ),
                                      subtitle: Row(
                                        children: [
                                          if (m.area.isNotEmpty)
                                            Text(
                                              m.area,
                                              style: TextStyle(
                                                fontSize: 11.sp,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          if (m.area.isNotEmpty &&
                                              isInOtherClass)
                                            const Text(' • '),
                                          if (isInOtherClass)
                                            Text(
                                              'في ${m.className ?? "فصل آخر"}',
                                              style: TextStyle(
                                                fontSize: 10.5.sp,
                                                color: AppColors.warningColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                        ],
                                      ),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedIds ??= {};
                                          if (val == true) {
                                            _selectedIds!.add(m.id);
                                          } else {
                                            _selectedIds!.remove(m.id);
                                          }
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                  ),

                  // خيار إسناد المخدومين أيضاً لخادم الفصل
                  if (c.servantIds.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    CheckboxListTile(
                      value: _assignToClassServant,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        'تسكين مخدومي الفصل أيضاً على ${c.servantNames.isNotEmpty ? c.servantNames.first : (c.servantName ?? "خادم الفصل")}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryLight,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() => _assignToClassServant = val == true);
                      },
                    ),
                  ],

                  SizedBox(height: 10.h),

                  // زر الحفظ
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving
                          ? null
                          : () => _handleSave(allStudents),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: _isSaving
                          ? SizedBox(
                              height: 20.h,
                              width: 20.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'حفظ التسكين',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
