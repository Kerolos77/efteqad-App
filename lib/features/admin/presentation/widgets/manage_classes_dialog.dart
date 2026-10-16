import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/class_model.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/services/firestore_service.dart';
import 'add_edit_class_dialog.dart';
import 'class_makhdomeen_dialog.dart';

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
    AddEditClassDialog.show(
      context,
      existing: existing,
      gradeTitle: widget.gradeTitle,
      serviceId: widget.serviceId,
      gradeId: widget.gradeId,
      khodamList: widget.khodamList,
      firestoreService: _firestore,
    );
  }

  void _openClassMakhdomeenDialog(ClassModel c) {
    ClassMakhdomeenDialog.show(
      context,
      classModel: c,
      gradeTitle: widget.gradeTitle,
      firestoreService: _firestore,
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
              backgroundColor: AppColors.errorColor,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 500.w, maxHeight: 600.h),
        child: Padding(
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                          'إدارة فصول السنة',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16.sp,
                          ),
                        ),
                        Text(
                          widget.gradeTitle,
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
              SizedBox(height: 14.h),
              const Divider(height: 1),
              SizedBox(height: 12.h),

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
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 48.sp,
                                color: isDark ? Colors.white30 : Colors.black26,
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                'لا توجد فصول بعد',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15.sp,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                'يمكنك إضافة فصول إذا كنت ترغب في تقسيم مخدومي هذه السنة (مثلاً فصول بالأرقام أو بأسماء القديسين)، أو الإبقاء عليها كقائمة موحدة.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.textMuted,
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
                      separatorBuilder: (_, __) => SizedBox(height: 8.h),
                      itemBuilder: (context, idx) {
                        final c = classes[idx];
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 10.h,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.cardBorderDark
                                  : AppColors.cardBorderLight,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18.r,
                                backgroundColor: AppColors.primaryLight
                                    .withValues(alpha: 0.12),
                                child: Text(
                                  c.name.isNotEmpty ? c.name[0] : 'ف',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryLight,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5.sp,
                                      ),
                                    ),
                                    if (c.servantNames.isNotEmpty ||
                                        (c.servantName != null &&
                                            c.servantName!.isNotEmpty))
                                      Text(
                                        (c.servantNames.length > 1)
                                            ? 'الخدام (${c.servantNames.length}): ${c.servantNames.join("، ")}'
                                            : 'الخادم: ${c.servantName}',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.people_alt_outlined,
                                  size: 19.sp,
                                  color: AppColors.primaryLight,
                                ),
                                tooltip: 'المخدومين والتسكين',
                                onPressed: () => _openClassMakhdomeenDialog(c),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit_outlined, size: 18.sp),
                                tooltip: 'تعديل',
                                onPressed: () => _openAddEditClassDialog(c),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18.sp,
                                  color: AppColors.errorColor,
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

              SizedBox(height: 12.h),
              // Add Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openAddEditClassDialog(),
                  icon: Icon(Icons.add_rounded, size: 20.sp),
                  label: const Text(
                    'إضافة فصل جديد',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
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
