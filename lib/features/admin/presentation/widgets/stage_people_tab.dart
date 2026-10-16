import 'package:efteqad/core/localization/app_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/services/firestore_service.dart';
import 'appoint_head_dialog.dart';
import 'pending_khadem_card.dart';
import 'service_setup_dialog.dart';
import 'stage_grade_head_card.dart';
import 'stage_servant_tile.dart';

class StagePeopleTab extends StatefulWidget {
  final List<KhademModel> pendingKhodam;
  final List<KhademModel> allKhodam;
  final List<MakhdomModel> allMakhdomeen;
  final ServiceModel? service;

  const StagePeopleTab({
    super.key,
    required this.pendingKhodam,
    required this.allKhodam,
    required this.allMakhdomeen,
    this.service,
  });

  @override
  State<StagePeopleTab> createState() => _StagePeopleTabState();
}

class _StagePeopleTabState extends State<StagePeopleTab> {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedGradeFilter = 'all';

  List<ServiceGrade> _getServiceGrades() {
    if (widget.service != null && widget.service!.grades.isNotEmpty) {
      return widget.service!.grades;
    }
    return [
      ServiceGrade(
        id: AppConstants.grade1st,
        name: context.tr.grade1stName,
        order: 1,
      ),
      ServiceGrade(
        id: AppConstants.grade2nd,
        name: context.tr.grade2ndName,
        order: 2,
      ),
      ServiceGrade(
        id: AppConstants.grade3rd,
        name: context.tr.grade3rdName,
        order: 3,
      ),
    ];
  }

  Color _getGradeColor(int order) {
    switch ((order - 1) % 6) {
      case 0:
        return const Color(0xFF3B82F6); // Blue
      case 1:
        return const Color(0xFF8B5CF6); // Purple
      case 2:
        return const Color(0xFFEC4899); // Pink
      case 3:
        return const Color(0xFF10B981); // Emerald
      case 4:
        return const Color(0xFFF59E0B); // Amber
      case 5:
      default:
        return const Color(0xFF06B6D4); // Cyan
    }
  }

  Future<void> _makeCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) return;
    final url = Uri.parse('tel:$clean');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _openAssignGradeDialog(KhademModel khadem) {
    final grades = _getServiceGrades();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          ctx.tr.assignServantToGradePrompt,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${ctx.tr.messageServant580}: ${khadem.name}'),
            SizedBox(height: 16.h),
            ...grades.map((g) {
              final color = _getGradeColor(g.order);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.school, color: color, size: 20.sp),
                title: Text(g.name, style: TextStyle(fontSize: 14.sp)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _firestoreService.assignKhademToGrade(
                    khadem.id,
                    g.id,
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _openAppointHeadDialog({
    required String gradeKey,
    required String gradeTitle,
    required List<KhademModel> gradeKhodam,
    required List<KhademModel> currentHeads,
  }) {
    AppointHeadDialog.show(
      context,
      gradeKey: gradeKey,
      gradeTitle: gradeTitle,
      gradeKhodam: gradeKhodam,
      currentHeads: currentHeads,
      firestoreService: _firestoreService,
      serviceId: widget.service?.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grades = _getServiceGrades();

    // Filter displayed servants
    List<KhademModel> displayedKhodam;
    if (_selectedGradeFilter == 'all') {
      displayedKhodam = widget.allKhodam.where((k) => k.isActive).toList();
    } else {
      displayedKhodam = widget.allKhodam
          .where((k) => k.grade == _selectedGradeFilter)
          .toList();
    }

    return ListView(
      padding: EdgeInsetsDirectional.fromSTEB(16.w, 12.h, 16.w, 85.h),
      physics: const BouncingScrollPhysics(),
      children: [
        // 0. تنبيه إعداد الخدمة لأول مرة (إن كانت الخدمة جديدة وغير مهيأة)
        if (widget.service != null && widget.service!.grades.isEmpty) ...[
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppColors.primaryLight.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primaryLight,
                  size: 36.sp,
                ),
                SizedBox(height: 8.h),
                Text(
                  'مرحباً بك! لم يتم إعداد صفوف الخدمة بعد',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
                ),
                SizedBox(height: 4.h),
                Text(
                  'تسمية سنوات الخدمة وتخصيص اسمها لبدء تسكين الخدام والمخدومين',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted),
                ),
                SizedBox(height: 12.h),
                ElevatedButton.icon(
                  onPressed: () => ServiceSetupDialog.show(
                    context,
                    service: widget.service!,
                    firestoreService: _firestoreService,
                  ),
                  icon: Icon(Icons.tune_rounded, size: 18.sp),
                  label: Text('تخصيص مسميات السنوات الآن', style: TextStyle(fontSize: 13.sp)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
        ],

        // 1. قطاع الخدام الجدد بانتظار التسكين
        if (widget.pendingKhodam.isNotEmpty) ...[
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: AppColors.warningColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_add_rounded,
                  size: 16.sp,
                  color: AppColors.warningColor,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                context.tr.pendingServantsSection,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.sp,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.warningColor,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  AppFormatters(
                    Localizations.localeOf(context),
                  ).formatNumber(widget.pendingKhodam.length),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ...widget.pendingKhodam.map(
            (khadem) => PendingKhademCard(
              khadem: khadem,
              isDark: isDark,
              onAssign: () => _openAssignGradeDialog(khadem),
            ),
          ),
          SizedBox(height: 20.h),
        ],

        // 2. قطاع أمناء السنين الدراسية (ديناميكي لجميع صفوف الخدمة)
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                size: 16.sp,
                color: AppColors.primaryLight,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              context.tr.gradeHeadsSection,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.sp),
            ),
            const Spacer(),
            if (widget.service != null)
              IconButton(
                icon: Icon(Icons.tune_rounded, size: 20.sp),
                tooltip: 'تخصيص مسميات الخدمة والسنوات',
                onPressed: () => ServiceSetupDialog.show(
                  context,
                  service: widget.service!,
                  firestoreService: _firestoreService,
                ),
              ),
          ],
        ),
        SizedBox(height: 12.h),

        // بطاقات أمناء السنوات الدراسية ديناميكياً
        ...grades.map((g) {
          final gradeKhodam = widget.allKhodam
              .where((k) => k.grade == g.id)
              .toList();
          final headKhodam = gradeKhodam.where((k) => k.isGradeAdmin).toList();

          return Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: StageGradeHeadCard(
              gradeKey: g.id,
              gradeTitle: g.name,
              headKhodam: headKhodam,
              gradeKhodam: gradeKhodam,
              color: _getGradeColor(g.order),
              isDark: isDark,
              onTapGrade: () => context.go(AppRoutes.gradeMakhdomeen(g.id)),
              onAppointHead: () => _openAppointHeadDialog(
                gradeKey: g.id,
                gradeTitle: g.name,
                gradeKhodam: gradeKhodam,
                currentHeads: headKhodam,
              ),
            ),
          );
        }),
        SizedBox(height: 20.h),

        // 3. فريق الخدام وتوزيع السنين
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.service?.name.isNotEmpty == true
                    ? 'خدام ${widget.service!.name}'
                    : context.tr.messageAssignedSecondaryStageServants,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.sp,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              context.tr.messageServants(
                AppFormatters(
                  Localizations.localeOf(context),
                ).formatNumber(displayedKhodam.length),
              ),
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),

        // فلاتر السنين ديناميكياً
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildGradeFilterChip('all', context.tr.allGrades, isDark),
              ...grades.map((g) {
                final count = widget.allKhodam
                    .where((k) => k.grade == g.id)
                    .length;
                final formattedCount = AppFormatters(
                  Localizations.localeOf(context),
                ).formatNumber(count);
                return Padding(
                  padding: EdgeInsetsDirectional.only(start: 8.w),
                  child: _buildGradeFilterChip(
                    g.id,
                    '${g.name} ($formattedCount)',
                    isDark,
                  ),
                );
              }),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        if (displayedKhodam.isEmpty)
          Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Center(
              child: Text(
                context.tr.messageNoServantsAssignedToThisSectionYet,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13.sp),
              ),
            ),
          )
        else
          ...displayedKhodam.map((khadem) {
            final assignedCount = widget.allMakhdomeen
                .where((m) => m.assignedKhademId == khadem.id)
                .length;
            return StageServantTile(
              khadem: khadem,
              assignedCount: assignedCount,
              gradeLabel: _getGradeLabel(khadem.grade),
              isDark: isDark,
              onMakeCall: () => _makeCall(khadem.phone),
              onChangeGrade: () => _openAssignGradeDialog(khadem),
            );
          }),
      ],
    );
  }

  Widget _buildGradeFilterChip(String key, String label, bool isDark) {
    final isSelected = _selectedGradeFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedGradeFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryLight
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryLight
                : (isDark
                      ? AppColors.cardBorderDark
                      : AppColors.cardBorderLight),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : AppColors.textDark),
          ),
        ),
      ),
    );
  }

  String _getGradeLabel(String? grade) {
    if (grade == null || grade.isEmpty) return context.tr.messageUnspecified;
    if (widget.service != null && widget.service!.grades.isNotEmpty) {
      final match = widget.service!.grades.where((g) => g.id == grade).toList();
      if (match.isNotEmpty) return match.first.name;
    }
    switch (grade) {
      case AppConstants.grade1st:
        return context.tr.grade1stName;
      case AppConstants.grade2nd:
        return context.tr.grade2ndName;
      case AppConstants.grade3rd:
        return context.tr.grade3rdName;
      default:
        return grade;
    }
  }
}
