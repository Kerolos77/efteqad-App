import 'package:efteqad/core/localization/app_formatters.dart';
import 'package:efteqad/core/localization/domain_labels.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/utils/color_generator.dart';
import '../../../common/widgets/app_drawer.dart';
import '../../../common/widgets/notifications_sheet.dart';
import '../../../tasks/presentation/widgets/tasks_tab.dart';
import '../widgets/service_setup_dialog.dart';
import 'analytics_tab.dart';

typedef StageAdminScreen = AdminMainScreen;

class AdminMainScreen extends StatefulWidget {
  final FirestoreService? firestoreService;
  final String? serviceId;
  const AdminMainScreen({super.key, this.firestoreService, this.serviceId});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  late final FirestoreService _firestoreService =
      widget.firestoreService ?? FirestoreService();

  late final String _serviceId = widget.serviceId ?? 'thanawy';
  late final Stream<List<MakhdomModel>> _makhdomeenStream;
  late final Stream<List<KhademModel>> _khodamStream;
  late final Stream<List<TaskModel>> _tasksStream;
  late final Stream<ServiceModel?> _serviceStream;

  int _selectedTabIndex = 0;
  String _selectedGradeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _makhdomeenStream = _firestoreService.getMakhdomeenStream(serviceId: _serviceId);
    _khodamStream = _firestoreService.getKhodamStream(serviceId: _serviceId);
    _tasksStream = _firestoreService.getAllTasksStream(serviceId: _serviceId);
    _serviceStream = _firestoreService.watchService(_serviceId);
  }

  Color _getGradeColor(int order) {
    switch ((order - 1) % 6) {
      case 0:
        return const Color(0xFF3B82F6);
      case 1:
        return const Color(0xFF8B5CF6);
      case 2:
        return const Color(0xFFEC4899);
      case 3:
        return const Color(0xFF10B981);
      case 4:
        return const Color(0xFFF59E0B);
      case 5:
      default:
        return const Color(0xFF06B6D4);
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

  void _openAssignGradeDialog(KhademModel khadem, [List<ServiceGrade>? serviceGrades]) {
    final grades = serviceGrades ?? [
      ServiceGrade(id: AppConstants.grade1st, name: context.tr.grade1stName, order: 1),
      ServiceGrade(id: AppConstants.grade2nd, name: context.tr.grade2ndName, order: 2),
      ServiceGrade(id: AppConstants.grade3rd, name: context.tr.grade3rdName, order: 3),
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          ctx.tr.assignServantToGradePrompt,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${khadem.name} (${khadem.email})',
              style: const TextStyle(
                fontSize: 13,
                color: AppConstants.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              ctx.tr.selectGradePrompt,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ...grades.map((g) => _buildGradeChoiceTile(
                  ctx,
                  khadem,
                  g.id,
                  g.name,
                  _getGradeColor(g.order),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeChoiceTile(
    BuildContext ctx,
    KhademModel khadem,
    String gradeKey,
    String gradeTitle,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          Navigator.pop(ctx);
          await _firestoreService.assignKhademToGrade(khadem.id, gradeKey);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.tr.servantAssignedSuccess),
                backgroundColor: AppConstants.successColor,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.school_rounded, size: 20, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  gradeTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 14,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppConstants.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAppointGradeHeadDialog(
    String gradeKey,
    String gradeTitle,
    List<KhademModel> gradeKhodam,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '${ctx.tr.appointGradeHeadBtn} - $gradeTitle',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: gradeKhodam.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    context.tr.messageNoServantsAssignedToYetAssignServants(
                      (gradeTitle).toString(),
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppConstants.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: gradeKhodam.length,
                  itemBuilder: (context, index) {
                    final k = gradeKhodam[index];
                    final isCurrentAdmin = k.isGradeAdmin;
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        k.phone.isNotEmpty ? k.phone : k.email,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: isCurrentAdmin
                          ? Chip(
                              label: Text(
                                context.tr.messageCurrentHead,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: AppConstants.accentGold,
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
                              await _firestoreService.setGradeAdmin(
                                gradeKey,
                                k.id,
                              );
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(successMsg),
                                  backgroundColor: AppConstants.successColor,
                                ),
                              );
                            },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.tr.cancel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ServiceModel?>(
      stream: _serviceStream,
      builder: (context, serviceSnap) {
        final service = serviceSnap.data;
        return StreamBuilder<List<MakhdomModel>>(
          stream: _makhdomeenStream,
          builder: (context, makhdomeenSnap) {
            return StreamBuilder<List<KhademModel>>(
              stream: _khodamStream,
              builder: (context, khodamSnap) {
                final allMakhdomeen = makhdomeenSnap.data ?? [];
                final allKhodam = khodamSnap.data ?? [];

                final pendingKhodam = allKhodam.where((k) => k.isPending).toList();
                final activeKhodam = allKhodam.where((k) => k.isActive).toList();

                return Scaffold(
                  drawer: const AppDrawer(isAdmin: true),
                  appBar: AppBar(
                    leading: Builder(
                      builder: (ctx) => IconButton(
                        icon: const Icon(Icons.menu_rounded),
                        tooltip: context.tr.messageMainMenu,
                        onPressed: () => Scaffold.of(ctx).openDrawer(),
                      ),
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          service?.name.isNotEmpty == true
                              ? service!.name
                              : context.tr.stageDashboardTitle,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          context.tr.makhdomeenAndKhodamSummary(
                            allMakhdomeen.length,
                            allKhodam.length,
                          ),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppConstants.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      if (service != null)
                        IconButton(
                          icon: const Icon(Icons.tune_rounded),
                          tooltip: 'تخصيص الخدمة والصفوف',
                          onPressed: () => ServiceSetupDialog.show(
                            context,
                            service: service,
                            firestoreService: _firestoreService,
                          ),
                        ),
                      const NotificationBellButton(),
                    ],
                  ),
                  bottomNavigationBar: NavigationBar(
                    selectedIndex: _selectedTabIndex,
                    onDestinationSelected: (idx) =>
                        setState(() => _selectedTabIndex = idx),
                    destinations: [
                      NavigationDestination(
                        icon: const Icon(Icons.manage_accounts_outlined),
                        selectedIcon: const Icon(Icons.manage_accounts),
                        label: context.tr.tabGradesAndServants,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.insights_outlined),
                        selectedIcon: const Icon(Icons.insights),
                        label: context.tr.tabStageAnalytics,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.assignment_outlined),
                        selectedIcon: const Icon(Icons.assignment),
                        label: context.tr.tabStageTasks,
                      ),
                    ],
                  ),
                  body: IndexedStack(
                    index: _selectedTabIndex,
                    children: [
                      // Tab 0: الخدام والتسكين وأمناء السنين
                      _buildGradesAndServantsTab(
                        pendingKhodam: pendingKhodam,
                        allKhodam: allKhodam,
                        allMakhdomeen: allMakhdomeen,
                        service: service,
                      ),

                      // Tab 1: تحليلات المرحلة الشاملة والمقارنة
                      AnalyticsTab(
                        makhdomeen: allMakhdomeen,
                        khodam: activeKhodam,
                        firestoreService: _firestoreService,
                        serviceId: _serviceId,
                      ),

                      // Tab 2: مهام المرحلة العامة
                      TasksTab(
                        tasksStream: _tasksStream,
                        availableKhodam: activeKhodam,
                        grade: 'all',
                        canCreateTasks: true,
                        serviceId: _serviceId,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildGradesAndServantsTab({
    required List<KhademModel> pendingKhodam,
    required List<KhademModel> allKhodam,
    required List<MakhdomModel> allMakhdomeen,
    ServiceModel? service,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final grades = (service != null && service.grades.isNotEmpty)
        ? service.grades
        : [
            ServiceGrade(id: AppConstants.grade1st, name: context.tr.grade1stName, order: 1),
            ServiceGrade(id: AppConstants.grade2nd, name: context.tr.grade2ndName, order: 2),
            ServiceGrade(id: AppConstants.grade3rd, name: context.tr.grade3rdName, order: 3),
          ];

    List<KhademModel> displayedKhodam;
    if (_selectedGradeFilter == 'all') {
      displayedKhodam = allKhodam.where((k) => k.isActive).toList();
    } else {
      displayedKhodam = allKhodam
          .where((k) => k.grade == _selectedGradeFilter)
          .toList();
    }

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 85),
      physics: const BouncingScrollPhysics(),
      children: [
        // 1. قطاع الخدام الجدد بانتظار التسكين (Pending Queue)
        if (pendingKhodam.isNotEmpty) ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppConstants.warningColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add_rounded,
                  size: 16,
                  color: AppConstants.warningColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.tr.pendingServantsSection,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppConstants.warningColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${pendingKhodam.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...pendingKhodam.map(
            (khadem) => _buildPendingKhademCard(khadem, isDark, grades),
          ),
          const SizedBox(height: 20),
        ],

        // 2. قطاع أمناء السنين الدراسية
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppConstants.primaryLight.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                size: 16,
                color: AppConstants.primaryLight,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              context.tr.gradeHeadsSection,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            const Spacer(),
            if (service != null)
              IconButton(
                icon: const Icon(Icons.tune_rounded, size: 20),
                tooltip: 'تعديل الخدمة والصفوف',
                onPressed: () => ServiceSetupDialog.show(
                  context,
                  service: service,
                  firestoreService: _firestoreService,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (service != null && service.grades.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.primaryLight.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppConstants.primaryLight.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppConstants.primaryLight, size: 36),
                const SizedBox(height: 8),
                const Text(
                  'مرحباً بك! لم يتم إعداد صفوف الخدمة بعد',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                const Text(
                  'حدد عدد سنوات / صفوف الخدمة وتسمية كل صف لبدء تسكين الخدام والمخدومين',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppConstants.textMuted),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => ServiceSetupDialog.show(
                    context,
                    service: service,
                    firestoreService: _firestoreService,
                  ),
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('إعداد صفوف الخدمة الآن'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryLight,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          )
        else
          ...grades.map((g) {
            final gradeKhodam = allKhodam.where((k) => k.grade == g.id).toList();
            KhademModel? head;
            try {
              head = gradeKhodam.firstWhere((k) => k.isGradeAdmin);
            } catch (_) {}
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildGradeHeadCard(
                gradeKey: g.id,
                gradeTitle: g.name,
                headKhadem: head,
                gradeKhodam: gradeKhodam,
                color: _getGradeColor(g.order),
                isDark: isDark,
              ),
            );
          }),
        const SizedBox(height: 24),

        // 3. فريق الخدام وتوزيع السنين
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              service?.name.isNotEmpty == true
                  ? 'خدام ${service!.name}'
                  : context.tr.messageAssignedSecondaryStageServants,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            Text(
              context.tr.messageServants(
                AppFormatters(
                  Localizations.localeOf(context),
                ).formatNumber(displayedKhodam.length),
              ),
              style: const TextStyle(
                fontSize: 12,
                color: AppConstants.textMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // فلاتر السنين
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildGradeFilterChip('all', context.tr.allGrades, isDark),
              ...grades.map((g) {
                final count = allKhodam.where((k) => k.grade == g.id).length;
                return Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8),
                  child: _buildGradeFilterChip(
                    g.id,
                    '${g.name} (${AppFormatters(Localizations.localeOf(context)).formatNumber(count)})',
                    isDark,
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (displayedKhodam.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppConstants.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                context.tr.messageNoServantsAssignedToThisSectionYet,
                style: TextStyle(color: AppConstants.textMuted),
              ),
            ),
          )
        else
          ...displayedKhodam.map((khadem) {
            final color = ColorGenerator.getColorForId(khadem.id);
            final assignedCount = allMakhdomeen
                .where((m) => m.assignedKhademId == khadem.id)
                .length;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppConstants.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? AppConstants.cardBorderDark
                      : AppConstants.cardBorderLight,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Text(
                      khadem.name.isNotEmpty
                          ? khadem.name[0]
                          : context.tr.messageS,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              khadem.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                            if (khadem.isGradeAdmin) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppConstants.accentGold.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  context.tr.messageGradeHead,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.accentGold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.tr.messageAssignedStudents(
                            (DomainLabels(
                              Localizations.localeOf(context),
                            ).gradeName(khadem.grade)).toString(),
                            AppFormatters(
                              Localizations.localeOf(context),
                            ).formatNumber((assignedCount)),
                          ),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppConstants.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (khadem.phone.isNotEmpty)
                    IconButton(
                      icon: const Icon(
                        Icons.call,
                        size: 18,
                        color: AppConstants.successColor,
                      ),
                      onPressed: () => _makeCall(khadem.phone),
                    ),
                  IconButton(
                    icon: const Icon(
                      Icons.swap_horiz_rounded,
                      size: 20,
                      color: AppConstants.primaryLight,
                    ),
                    tooltip: context.tr.messageChangeGrade,
                    onPressed: () => _openAssignGradeDialog(khadem, grades),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildPendingKhademCard(
    KhademModel khadem,
    bool isDark, [
    List<ServiceGrade>? serviceGrades,
  ]) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.warningColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppConstants.warningColor.withValues(alpha: 0.15),
            child: const Icon(
              Icons.person_outline,
              color: AppConstants.warningColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  khadem.name.isNotEmpty
                      ? khadem.name
                      : context.tr.messageNewServant,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  khadem.phone.isNotEmpty ? khadem.phone : khadem.email,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppConstants.textMuted,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _openAssignGradeDialog(khadem, serviceGrades),
            icon: const Icon(Icons.school_outlined, size: 14),
            label: Text(
              context.tr.messageAssign,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.warningColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeHeadCard({
    required String gradeKey,
    required String gradeTitle,
    required KhademModel? headKhadem,
    required List<KhademModel> gradeKhodam,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.shield_outlined, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gradeTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  headKhadem != null
                      ? headKhadem.name
                      : context.tr.noGradeHeadAssigned,
                  style: TextStyle(
                    fontWeight: headKhadem != null
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14,
                    color: headKhadem != null
                        ? (isDark ? Colors.white : AppConstants.textDark)
                        : AppConstants.textMuted,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () =>
                _openAppointGradeHeadDialog(gradeKey, gradeTitle, gradeKhodam),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              headKhadem != null
                  ? context.tr.changeGradeHeadBtn
                  : context.tr.appointGradeHeadBtn,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeFilterChip(String filterKey, String label, bool isDark) {
    final isSelected = _selectedGradeFilter == filterKey;
    return InkWell(
      onTap: () => setState(() => _selectedGradeFilter = filterKey),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryNavy
              : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : AppConstants.textDark),
          ),
        ),
      ),
    );
  }
}
