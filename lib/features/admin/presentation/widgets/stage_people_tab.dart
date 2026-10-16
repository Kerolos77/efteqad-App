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
import 'rejected_khadem_card.dart';
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
  int _selectedStatusTab = 0; // 0: النشطين, 1: قيد الانتظار, 2: المرفوضين
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
                  try {
                    await _firestoreService.assignKhademToGrade(
                      khadem.id,
                      g.id,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم تسكين الخادم ${khadem.name} في ${g.name} بنجاح'),
                          backgroundColor: AppColors.successColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.tr.dataUnavailable),
                          backgroundColor: AppColors.errorColor,
                        ),
                      );
                    }
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _openRejectDialog(KhademModel khadem) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Icon(Icons.highlight_off_rounded, color: AppColors.errorColor, size: 24.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'رفض طلب الانضمام',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الخادم: ${khadem.name}', style: const TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 12.h),
            Text(
              'يرجى كتابة سبب الرفض أو الملاحظات لتظهر للخادم في حسابه حتى يتمكن من تعديل بياناته:',
              style: TextStyle(fontSize: 12.5.sp, color: AppColors.textMuted),
            ),
            SizedBox(height: 10.h),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'مثال: يرجى اختيار الخدمة الصحيحة، أو كتابة الاسم ثلاثياً للتأكد...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                contentPadding: EdgeInsets.all(12.r),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.tr.cancel),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            onPressed: () async {
              final reason = reasonController.text.trim();
              Navigator.pop(ctx);
              try {
                await _firestoreService.rejectKhademApplication(
                  khademId: khadem.id,
                  reason: reason.isNotEmpty ? reason : 'تم رفض الطلب من قِبل إدارة الخدمة.',
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم رفض الطلب وإرسال الملاحظات بنجاح.'),
                      backgroundColor: AppColors.errorColor,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.tr.dataUnavailable),
                      backgroundColor: AppColors.errorColor,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('تأكيد الرفض'),
          ),
        ],
      ),
    );
  }

  Future<void> _reopenApplication(KhademModel khadem) async {
    try {
      await _firestoreService.reopenKhademApplication(khademId: khadem.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت استعادة الطلب إلى قائمة الانتظار بنجاح.'),
            backgroundColor: AppColors.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.dataUnavailable),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
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

    // تقسيم الخدام إلى المجموعات الثلاث
    final activeKhodam = widget.allKhodam.where((k) => k.isActive).toList();
    final pendingKhodam = widget.allKhodam.where((k) => k.isPending).isNotEmpty
        ? widget.allKhodam.where((k) => k.isPending).toList()
        : widget.pendingKhodam.where((k) => !k.isRejected).toList();
    final rejectedKhodam = widget.allKhodam.where((k) => k.isRejected).toList();

    // فلترة الخدام النشطين المعروضين حسب السنة المختارة
    List<KhademModel> displayedActiveKhodam;
    if (_selectedGradeFilter == 'all') {
      displayedActiveKhodam = activeKhodam;
    } else {
      displayedActiveKhodam = activeKhodam
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
          SizedBox(height: 16.h),
        ],

        // 1. شريط التابات الثلاث (الموافق عليهم، قيد الانتظار، المرفوضين)
        _buildStatusTabBar(
          activeCount: activeKhodam.length,
          pendingCount: pendingKhodam.length,
          rejectedCount: rejectedKhodam.length,
          isDark: isDark,
        ),

        // 2. محتوى التبويب المختار
        if (_selectedStatusTab == 0) ...[
          // ==================== تبويب الخدام النشطين ====================
          _buildActiveKhodamSection(
            isDark: isDark,
            grades: grades,
            activeKhodam: activeKhodam,
            displayedKhodam: displayedActiveKhodam,
          ),
        ] else if (_selectedStatusTab == 1) ...[
          // ==================== تبويب قيد الانتظار ====================
          _buildPendingKhodamSection(
            isDark: isDark,
            pendingKhodam: pendingKhodam,
          ),
        ] else ...[
          // ==================== تبويب المرفوضين ====================
          _buildRejectedKhodamSection(
            isDark: isDark,
            rejectedKhodam: rejectedKhodam,
          ),
        ],
      ],
    );
  }

  Widget _buildStatusTabBar({
    required int activeCount,
    required int pendingCount,
    required int rejectedCount,
    required bool isDark,
  }) {
    final formatters = AppFormatters(Localizations.localeOf(context));

    return Container(
      margin: EdgeInsets.only(bottom: 18.h),
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          _buildStatusTabItem(
            index: 0,
            title: 'الموافق عليهم',
            count: activeCount,
            isSelected: _selectedStatusTab == 0,
            isDark: isDark,
            activeColor: AppColors.primaryLight,
            formatters: formatters,
          ),
          _buildStatusTabItem(
            index: 1,
            title: 'قيد الانتظار',
            count: pendingCount,
            isSelected: _selectedStatusTab == 1,
            isDark: isDark,
            activeColor: AppColors.warningColor,
            highlightBadge: pendingCount > 0,
            formatters: formatters,
          ),
          _buildStatusTabItem(
            index: 2,
            title: 'المرفوضين',
            count: rejectedCount,
            isSelected: _selectedStatusTab == 2,
            isDark: isDark,
            activeColor: AppColors.errorColor,
            highlightBadge: rejectedCount > 0,
            formatters: formatters,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTabItem({
    required int index,
    required String title,
    required int count,
    required bool isSelected,
    required bool isDark,
    required Color activeColor,
    bool highlightBadge = false,
    required AppFormatters formatters,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedStatusTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 9.h),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.surfaceDark : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                      blurRadius: 6.r,
                      offset: Offset(0, 2.h),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected
                        ? (isDark ? Colors.white : AppColors.primaryNavy)
                        : (isDark ? Colors.white54 : AppColors.textMuted),
                  ),
                ),
              ),
              SizedBox(width: 5.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
                decoration: BoxDecoration(
                  color: highlightBadge
                      ? activeColor
                      : (isSelected
                          ? activeColor.withValues(alpha: 0.15)
                          : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06))),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  formatters.formatNumber(count),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: highlightBadge
                        ? Colors.white
                        : (isSelected
                            ? activeColor
                            : (isDark ? Colors.white54 : AppColors.textMuted)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== بناء التبويب الأول: الخدام الحاليين ====================
  Widget _buildActiveKhodamSection({
    required bool isDark,
    required List<ServiceGrade> grades,
    required List<KhademModel> activeKhodam,
    required List<KhademModel> displayedKhodam,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // قطاع أمناء السنين الدراسية (ديناميكي لجميع صفوف الخدمة)
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
          final gradeKhodam = activeKhodam
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

        // فريق الخدام وتوزيع السنين
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
                final count = activeKhodam
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

  // ==================== بناء التبويب الثاني: قيد الانتظار ====================
  Widget _buildPendingKhodamSection({
    required bool isDark,
    required List<KhademModel> pendingKhodam,
  }) {
    if (pendingKhodam.isEmpty) {
      return Container(
        margin: EdgeInsets.only(top: 20.h),
        padding: EdgeInsets.all(32.r),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          children: [
            Icon(
              Icons.how_to_reg_rounded,
              size: 48.sp,
              color: AppColors.primaryLight.withValues(alpha: 0.6),
            ),
            SizedBox(height: 12.h),
            Text(
              'لا توجد طلبات انتظار جديدة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
            ),
            SizedBox(height: 6.h),
            Text(
              'أي خادم جديد يقوم بالتسجيل واختيار هذه الخدمة ستظهر بياناته هنا لتسكينه أو رفضه.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5.sp, color: AppColors.textMuted, height: 1.4),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
            Expanded(
              child: Text(
                'طلبات انضمام جديدة بانتظار التسكين (${pendingKhodam.length})',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Text(
          'يرجى مراجعة بيانات الخدام وتسكينهم في الصف المناسب، أو رفض الطلب مع ذكر السبب ليظهر للخادم:',
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.textMuted,
            height: 1.35,
          ),
        ),
        SizedBox(height: 12.h),

        ...pendingKhodam.map(
          (khadem) => PendingKhademCard(
            khadem: khadem,
            isDark: isDark,
            onAssign: () => _openAssignGradeDialog(khadem),
            onReject: () => _openRejectDialog(khadem),
            onMakeCall: khadem.phone.isNotEmpty ? () => _makeCall(khadem.phone) : null,
          ),
        ),
      ],
    );
  }

  // ==================== بناء التبويب الثالث: المرفوضين ====================
  Widget _buildRejectedKhodamSection({
    required bool isDark,
    required List<KhademModel> rejectedKhodam,
  }) {
    if (rejectedKhodam.isEmpty) {
      return Container(
        margin: EdgeInsets.only(top: 20.h),
        padding: EdgeInsets.all(32.r),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 48.sp,
              color: AppColors.successColor.withValues(alpha: 0.6),
            ),
            SizedBox(height: 12.h),
            Text(
              'لا توجد طلبات مرفوضة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
            ),
            SizedBox(height: 6.h),
            Text(
              'الطلبات التي يتم رفضها ستظهر هنا مع سبب الرفض لتتمكن من مراجعتها أو التراجع وقبولها في أي وقت.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5.sp, color: AppColors.textMuted, height: 1.4),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: AppColors.errorColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_off_rounded,
                size: 16.sp,
                color: AppColors.errorColor,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'الطلبات المرفوضة (${rejectedKhodam.length})',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Text(
          'يمكنك مراجعة أسباب الرفض المسجلة، أو التراجع وإعادة فتح الطلب للانتظار، أو تسكينه مباشرة:',
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.textMuted,
            height: 1.35,
          ),
        ),
        SizedBox(height: 12.h),

        ...rejectedKhodam.map(
          (khadem) => RejectedKhademCard(
            khadem: khadem,
            isDark: isDark,
            onReopen: () => _reopenApplication(khadem),
            onAssign: () => _openAssignGradeDialog(khadem),
            onMakeCall: khadem.phone.isNotEmpty ? () => _makeCall(khadem.phone) : null,
          ),
        ),
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
