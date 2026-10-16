import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/utils/color_generator.dart';

class AppointHeadDialog extends StatefulWidget {
  final String gradeKey;
  final String gradeTitle;
  final List<KhademModel> gradeKhodam;
  final List<KhademModel> currentHeads;
  final FirestoreService firestoreService;
  final String? serviceId;

  const AppointHeadDialog({
    super.key,
    required this.gradeKey,
    required this.gradeTitle,
    required this.gradeKhodam,
    this.currentHeads = const [],
    required this.firestoreService,
    this.serviceId,
  });

  static void show(
    BuildContext context, {
    required String gradeKey,
    required String gradeTitle,
    required List<KhademModel> gradeKhodam,
    List<KhademModel> currentHeads = const [],
    KhademModel? currentHead,
    required FirestoreService firestoreService,
    String? serviceId,
  }) {
    final heads = currentHeads.isNotEmpty
        ? currentHeads
        : (currentHead != null ? [currentHead] : gradeKhodam.where((k) => k.isGradeAdmin).toList());
    showDialog(
      context: context,
      builder: (ctx) => AppointHeadDialog(
        gradeKey: gradeKey,
        gradeTitle: gradeTitle,
        gradeKhodam: gradeKhodam,
        currentHeads: heads,
        firestoreService: firestoreService,
        serviceId: serviceId,
      ),
    );
  }

  @override
  State<AppointHeadDialog> createState() => _AppointHeadDialogState();
}

class _AppointHeadDialogState extends State<AppointHeadDialog> {
  late Set<String> _adminIds;

  @override
  void initState() {
    super.initState();
    _adminIds = widget.gradeKhodam.where((k) => k.isGradeAdmin).map((k) => k.id).toSet();
    if (_adminIds.isEmpty && widget.currentHeads.isNotEmpty) {
      _adminIds.addAll(widget.currentHeads.map((k) => k.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Row(
        children: [
          Icon(Icons.workspace_premium_rounded, color: AppColors.primaryLight, size: 22.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'أمناء السنة - ${widget.gradeTitle}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: widget.gradeKhodam.isEmpty
            ? Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Text(
                  context.tr.messageNoServantsAssignedToYetAssignServants(
                    widget.gradeTitle,
                  ),
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: widget.gradeKhodam.length,
                itemBuilder: (ctx, index) {
                  final k = widget.gradeKhodam[index];
                  final isCurrentAdmin = _adminIds.contains(k.id);
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: ColorGenerator.getColorForId(
                        k.id,
                      ).withValues(alpha: 0.2),
                      child: Text(
                        k.name.isNotEmpty ? k.name[0] : context.tr.messageS,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: ColorGenerator.getColorForId(k.id),
                        ),
                      ),
                    ),
                    title: Text(
                      k.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                    subtitle: Text(
                      k.phone.isNotEmpty ? k.phone : k.email,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textMuted,
                      ),
                    ),
                    trailing: isCurrentAdmin
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(
                                label: const Text(
                                  'أمين سنة ✓',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: AppColors.accentGold,
                                visualDensity: VisualDensity.compact,
                              ),
                              SizedBox(width: 4.w),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppColors.errorColor),
                                tooltip: 'إلغاء صفة الأمين',
                                onPressed: () async {
                                  setState(() => _adminIds.remove(k.id));
                                  await widget.firestoreService.removeGradeAdmin(k.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('تم إلغاء صفة أمين السنة للخادم ${k.name}'),
                                        backgroundColor: AppColors.warningColor,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          )
                        : OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            ),
                            icon: const Icon(Icons.add_moderator_rounded, size: 16),
                            label: const Text('تعيين كأمين', style: TextStyle(fontSize: 11)),
                            onPressed: () async {
                              setState(() => _adminIds.add(k.id));
                              await widget.firestoreService.setGradeAdmin(
                                widget.gradeKey,
                                k.id,
                                serviceId: widget.serviceId,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('تم تعيين ${k.name} كأمين للسنة بنجاح'),
                                    backgroundColor: AppColors.successColor,
                                  ),
                                );
                              }
                            },
                          ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }
}
