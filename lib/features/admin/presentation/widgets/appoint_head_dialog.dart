import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/utils/color_generator.dart';

class AppointHeadDialog extends StatelessWidget {
  final String gradeKey;
  final String gradeTitle;
  final List<KhademModel> gradeKhodam;
  final KhademModel? currentHead;
  final FirestoreService firestoreService;
  final String? serviceId;

  const AppointHeadDialog({
    super.key,
    required this.gradeKey,
    required this.gradeTitle,
    required this.gradeKhodam,
    required this.currentHead,
    required this.firestoreService,
    this.serviceId,
  });

  static void show(
    BuildContext context, {
    required String gradeKey,
    required String gradeTitle,
    required List<KhademModel> gradeKhodam,
    required KhademModel? currentHead,
    required FirestoreService firestoreService,
    String? serviceId,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AppointHeadDialog(
        gradeKey: gradeKey,
        gradeTitle: gradeTitle,
        gradeKhodam: gradeKhodam,
        currentHead: currentHead,
        firestoreService: firestoreService,
        serviceId: serviceId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text(
        '${context.tr.appointGradeHeadBtn} - $gradeTitle',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: gradeKhodam.isEmpty
            ? Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Text(
                  context.tr.messageNoServantsAssignedToYetAssignServants(
                    gradeTitle,
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
                itemCount: gradeKhodam.length,
                itemBuilder: (ctx, index) {
                  final k = gradeKhodam[index];
                  final isCurrentAdmin =
                      k.id == currentHead?.id || k.isGradeAdmin;
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
                        ? Chip(
                            label: Text(
                              context.tr.messageCurrentHead,
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: AppColors.accentGold,
                            visualDensity: VisualDensity.compact,
                          )
                        : const Icon(Icons.check_circle_outline, size: 20),
                    onTap: isCurrentAdmin
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            final messenger = ScaffoldMessenger.of(context);
                            final successMsg =
                                context.tr.gradeHeadUpdatedSuccess;
                            await firestoreService.setGradeAdmin(
                              gradeKey,
                              k.id,
                              serviceId: serviceId,
                            );
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(successMsg),
                                backgroundColor: AppColors.successColor,
                              ),
                            );
                          },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr.cancel),
        ),
      ],
    );
  }
}
