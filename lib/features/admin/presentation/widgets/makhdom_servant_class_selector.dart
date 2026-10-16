import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/class_model.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/services/firestore_service.dart';

class MakhdomServantClassSelector extends StatelessWidget {
  final bool isDark;
  final bool disabled;
  final List<KhademModel> khodamList;
  final String? selectedKhademId;
  final String? selectedKhademName;
  final void Function(String? id, String? name) onKhademChanged;
  final FirestoreService firestoreService;
  final String serviceId;
  final String gradeId;
  final String? selectedClassId;
  final void Function(String? id, String? name) onClassChanged;
  final bool isBrethren;
  final ValueChanged<bool> onBrethrenChanged;

  const MakhdomServantClassSelector({
    super.key,
    required this.isDark,
    required this.disabled,
    required this.khodamList,
    required this.selectedKhademId,
    required this.selectedKhademName,
    required this.onKhademChanged,
    required this.firestoreService,
    required this.serviceId,
    required this.gradeId,
    required this.selectedClassId,
    required this.onClassChanged,
    required this.isBrethren,
    required this.onBrethrenChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isKhademInList =
        selectedKhademId == null ||
        khodamList.any((k) => k.id == selectedKhademId);
    final effectiveKhademId = isKhademInList ? selectedKhademId : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: effectiveKhademId,
          decoration: InputDecoration(
            labelText: context.tr.assignedServantSelectLabel,
            prefixIcon: Icon(Icons.person_pin_rounded, size: 20.sp),
          ),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(
                context.tr.unassignedNoServantOption,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ...khodamList.map(
              (k) => DropdownMenuItem(
                value: k.id,
                child: Text(k.name, overflow: TextOverflow.ellipsis),
              ),
            ),
            if (!isKhademInList && selectedKhademId != null)
              DropdownMenuItem(
                value: selectedKhademId,
                child: Text(
                  selectedKhademName ??
                      context.tr.messageServantUnavailableInThisList,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: disabled
              ? null
              : (val) {
                  if (val == null) {
                    onKhademChanged(null, null);
                  } else {
                    final matches = khodamList.where((element) => element.id == val);
                    final name = matches.isNotEmpty ? matches.first.name : selectedKhademName;
                    onKhademChanged(val, name);
                  }
                },
        ),
        SizedBox(height: 12.h),

        // اختيار الفصل الدراسي (إذا كانت السنة مقسمة لفصول)
        StreamBuilder<List<ClassModel>>(
          stream: firestoreService.watchClasses(
            serviceId: serviceId,
            gradeId: gradeId,
          ),
          builder: (context, snap) {
            final classes = snap.data ?? [];
            if (classes.isEmpty) return const SizedBox.shrink();

            final isClassInList = selectedClassId == null ||
                classes.any((c) => c.id == selectedClassId);
            final effectiveClassId = isClassInList ? selectedClassId : null;

            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: DropdownButtonFormField<String?>(
                isExpanded: true,
                initialValue: effectiveClassId,
                decoration: InputDecoration(
                  labelText: 'الفصل الدراسي (اختياري)',
                  prefixIcon: Icon(
                    Icons.diversity_3_outlined,
                    size: 20.sp,
                  ),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'بدون فصل محدد (عام للسنة)',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                  ...classes.map(
                    (c) => DropdownMenuItem<String?>(
                      value: c.id,
                      child: Text(c.name, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: disabled
                    ? null
                    : (val) {
                        if (val == null) {
                          onClassChanged(null, null);
                        } else {
                          final match = classes.where((c) => c.id == val);
                          final name = match.isNotEmpty ? match.first.name : null;
                          onClassChanged(val, name);
                        }
                      },
              ),
            );
          },
        ),
        SizedBox(height: 4.h),

        // Switch أخوة الرب بتصميم أنيق
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: 14.w,
            vertical: 4.h,
          ),
          decoration: BoxDecoration(
            color: isBrethren
                ? AppColors.accentGold.withValues(alpha: 0.1)
                : (isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceLight),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isBrethren
                  ? AppColors.accentGold.withValues(alpha: 0.6)
                  : (isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight),
              width: isBrethren ? 1.5.w : 1.w,
            ),
          ),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Row(
              children: [
                Icon(
                  isBrethren
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: isBrethren
                      ? AppColors.accentGold
                      : (isDark ? Colors.white54 : Colors.black45),
                  size: 22.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    context.tr.brethrenSwitchLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ],
            ),
            activeThumbColor: AppColors.accentGold,
            value: isBrethren,
            onChanged: disabled ? null : onBrethrenChanged,
          ),
        ),
      ],
    );
  }
}
