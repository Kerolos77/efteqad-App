import 'package:efteqad/core/localization/app_formatters.dart';
import 'package:efteqad/core/errors/app_failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/trusted_mutations.dart';
import '../../../../core/utils/color_generator.dart';
import 'assign_conflict_warning_dialog.dart';
import 'assign_makhdom_list_item.dart';

class AssignMakhdomeenModal extends StatefulWidget {
  final FirestoreService? firestoreService;
  final KhademModel targetKhadem;
  final List<MakhdomModel> allMakhdomeen;

  const AssignMakhdomeenModal({
    super.key,
    this.firestoreService,
    required this.targetKhadem,
    required this.allMakhdomeen,
  });

  @override
  State<AssignMakhdomeenModal> createState() => _AssignMakhdomeenModalState();
}

class _AssignMakhdomeenModalState extends State<AssignMakhdomeenModal> {
  late final FirestoreService _firestoreService;
  late Set<String> _selectedIds;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedClassFilter;
  bool _isSaving = false;
  Set<String>? _submittedSelection;
  Set<String>? _submittedRemovals;
  Map<String, String?>? _submittedExpectations;
  String? _submittedTargetId;
  String? _submittedUid;
  final Map<String, String> _removalOperations = {};
  final Set<String> _confirmedRemovals = {};
  final String _assignmentOperation = newOperationId('assignment');

  @override
  void initState() {
    super.initState();
    _firestoreService = widget.firestoreService ?? FirestoreService();
    // تحديد المخدومين المربوطين بهذا الخادم حالياً
    _selectedIds = widget.allMakhdomeen
        .where((m) => m.assignedKhademId == widget.targetKhadem.id)
        .map((m) => m.id)
        .toSet();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // فحص التعارض وإظهار التنبيه الذكي
  Future<void> _handleSave() async {
    if (_isSaving) return;
    try {
      _submittedUid ??= _firestoreService.captureMutationIdentity();
      _firestoreService.checkMutationIdentity(_submittedUid);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppFailure.fromException(e).localizedMessage(context.tr),
            ),
          ),
        );
      }
      return;
    }

    // المخدومين الجدد الذين تم تحديدهم وهم مربوطين بالفعل بخادم آخر
    final conflictingMakhdomeen = widget.allMakhdomeen.where((m) {
      final isSelected = _selectedIds.contains(m.id);
      final isPreviouslyWithAnotherKhadem =
          m.assignedKhademId != null &&
          m.assignedKhademId!.isNotEmpty &&
          m.assignedKhademId != widget.targetKhadem.id;
      return isSelected && isPreviouslyWithAnotherKhadem;
    }).toList();

    if (_submittedSelection == null && conflictingMakhdomeen.isNotEmpty) {
      final bool? confirm = await AssignConflictWarningDialog.show(
        context,
        conflictingMakhdomeen: conflictingMakhdomeen,
        targetKhademName: widget.targetKhadem.name,
      );

      if (confirm != true) return;
    }

    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() {
      if (_submittedSelection == null) {
        _submittedSelection = Set.of(_selectedIds);
        _submittedTargetId = widget.targetKhadem.id;
        _submittedRemovals = widget.allMakhdomeen
            .where((m) => m.assignedKhademId == _submittedTargetId)
            .map((m) => m.id)
            .toSet()
            .difference(_submittedSelection!);
        _submittedExpectations = {
          for (final m in widget.allMakhdomeen)
            if (_submittedSelection!.contains(m.id)) m.id: m.assignedKhademId,
        };
      }
      _isSaving = true;
    });

    try {
      _firestoreService.checkMutationIdentity(_submittedUid);
      for (final unassignedId in _submittedRemovals!) {
        if (_confirmedRemovals.contains(unassignedId)) continue;
        await _firestoreService.unassignMakhdom(
          unassignedId,
          expectedKhademId: _submittedTargetId,
          expectedUid: _submittedUid,
          operationId: _removalOperations.putIfAbsent(
            unassignedId,
            () => newOperationId('unassign'),
          ),
        );
        _firestoreService.checkMutationIdentity(_submittedUid);
        _confirmedRemovals.add(unassignedId);
      }

      if (_submittedSelection!.isNotEmpty) {
        await _firestoreService.assignMakhdomeenToKhadem(
          khademId: _submittedTargetId!,
          khademName: widget.targetKhadem.name,
          makhdomeenIds: _submittedSelection!.toList(),
          expectedAssignments: _submittedExpectations!,
          expectedUid: _submittedUid,
          operationId: _assignmentOperation,
        );
      }

      _firestoreService.checkMutationIdentity(_submittedUid);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.assignmentsSavedSuccess),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppFailure.fromException(e).localizedMessage(context.tr),
            ),
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
    final targetColor = ColorGenerator.getColorForId(widget.targetKhadem.id);

    final availableClasses = <String>{};
    for (final m in widget.allMakhdomeen) {
      if (m.className != null && m.className!.isNotEmpty) {
        availableClasses.add(m.className!);
      }
    }

    final filteredList = widget.allMakhdomeen.where((m) {
      if (_selectedClassFilter != null) {
        if (_selectedClassFilter == '__unassigned__') {
          if (m.className != null && m.className!.isNotEmpty) return false;
        } else {
          if (m.className != _selectedClassFilter && m.classId != _selectedClassFilter) return false;
        }
      }
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return m.fullName.toLowerCase().contains(q) ||
          m.area.toLowerCase().contains(q) ||
          (m.className != null && m.className!.toLowerCase().contains(q));
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: Column(
        children: [
          // شريط السحب العلوي (Apple drag handle)
          Container(
            margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),

          // الهيدر الحديث مع كارت الخادم
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(20.w, 8.h, 20.w, 12.h),
            child: Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: targetColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: targetColor.withValues(alpha: 0.35),
                      width: 1.5.w,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.targetKhadem.name.isNotEmpty
                          ? widget.targetKhadem.name[0]
                          : context.tr.messageS,
                      style: TextStyle(
                        color: targetColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr.messageAssignMakhdomeenToServant,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMuted,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        widget.targetKhadem.name,
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: targetColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: targetColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 15.sp,
                        color: targetColor,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        '${_selectedIds.length} / ${AppFormatters(Localizations.localeOf(context)).formatNumber(widget.allMakhdomeen.length)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                          color: targetColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // حقل البحث الذكي
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: context.tr.searchByNameOrArea,
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
                  horizontal: 16.w,
                  vertical: 12.h,
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
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide(color: targetColor, width: 1.5.w),
                ),
              ),
            ),
          ),

          if (availableClasses.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text(
                      'كل الفصول (${widget.allMakhdomeen.length})',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        fontWeight: _selectedClassFilter == null
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: _selectedClassFilter == null,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedClassFilter = null);
                    },
                  ),
                  SizedBox(width: 6.w),
                  ...availableClasses.map((className) {
                    final count = widget.allMakhdomeen
                        .where((m) => m.className == className)
                        .length;
                    return Padding(
                      padding: EdgeInsets.only(left: 6.w),
                      child: ChoiceChip(
                        label: Text(
                          '$className ($count)',
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: _selectedClassFilter == className
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        selected: _selectedClassFilter == className,
                        onSelected: (selected) {
                          setState(() {
                            _selectedClassFilter = selected ? className : null;
                          });
                        },
                      ),
                    );
                  }),
                  SizedBox(width: 6.w),
                  ChoiceChip(
                    label: Text(
                      'بدون فصل (${widget.allMakhdomeen.where((m) => m.className == null || m.className!.isEmpty).length})',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        fontWeight: _selectedClassFilter == '__unassigned__'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: _selectedClassFilter == '__unassigned__',
                    onSelected: (selected) {
                      setState(() {
                        _selectedClassFilter =
                            selected ? '__unassigned__' : null;
                      });
                    },
                  ),
                ],
              ),
            ),

          if (_submittedSelection != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                context.tr.messageSelectionIsLockedUntilConfirmationRetryTo,
              ),
            ),
          // شريط إجراءات سريعة (تحديد الكل / إلغاء تحديد الكل)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr.resultsCount(filteredList.length),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (_submittedSelection != null) return;
                    setState(() {
                      _selectedIds.addAll(filteredList.map((m) => m.id));
                    });
                  },
                  child: Text(
                    context.tr.selectAll,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: targetColor,
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                GestureDetector(
                  onTap: () {
                    if (_submittedSelection != null) return;
                    setState(() {
                      for (final m in filteredList) {
                        _selectedIds.remove(m.id);
                      }
                    });
                  },
                  child: Text(
                    context.tr.deselectAll,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 4.h),

          // قائمة المخدومين كبطاقات أنيقة تفاعلية
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 40.sp,
                          color: isDark ? Colors.white30 : Colors.grey.shade400,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          context.tr.noSearchResults,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 6.h,
                    ),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final makhdom = filteredList[index];
                      final isSelected = _selectedIds.contains(makhdom.id);

                      return AssignMakhdomListItem(
                        makhdom: makhdom,
                        isSelected: isSelected,
                        isDark: isDark,
                        targetColor: targetColor,
                        targetKhademId: widget.targetKhadem.id,
                        onTap: () {
                          if (_submittedSelection != null) return;
                          setState(() {
                            if (isSelected) {
                              _selectedIds.remove(makhdom.id);
                            } else {
                              _selectedIds.add(makhdom.id);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),

          // شريط الحفظ العائم في الأسفل (Floating bottom dock)
          Container(
            padding: EdgeInsetsDirectional.fromSTEB(20.w, 14.h, 20.w, 24.h),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10.r,
                  offset: Offset(0, -4.h),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _handleSave,
                icon: _isSaving
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Icons.check_circle_rounded, size: 20.sp),
                label: Text(
                  _isSaving
                      ? context.tr.saving
                      : context.tr.saveAssignmentsWithCount(
                          _selectedIds.length,
                        ),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: targetColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
