import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../common/widgets/app_drawer.dart';
import '../../../common/widgets/notifications_sheet.dart';
import '../../../tasks/presentation/widgets/tasks_tab.dart';
import '../widgets/service_setup_dialog.dart';
import '../widgets/stage_people_tab.dart';
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

  @override
  void initState() {
    super.initState();
    _makhdomeenStream = _firestoreService.getMakhdomeenStream(serviceId: _serviceId);
    _khodamStream = _firestoreService.getKhodamStream(serviceId: _serviceId);
    _tasksStream = _firestoreService.getAllTasksStream(serviceId: _serviceId);
    _serviceStream = _firestoreService.watchService(_serviceId);
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
                        icon: Icon(Icons.menu_rounded, size: 24.sp),
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
                          style: TextStyle(
                            fontSize: 16.5.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          context.tr.makhdomeenAndKhodamSummary(
                            allMakhdomeen.length,
                            allKhodam.length,
                          ),
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      if (service != null)
                        IconButton(
                          icon: Icon(Icons.tune_rounded, size: 22.sp),
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
                        icon: Icon(Icons.manage_accounts_outlined, size: 22.sp),
                        selectedIcon: Icon(Icons.manage_accounts, size: 22.sp),
                        label: context.tr.tabGradesAndServants,
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.insights_outlined, size: 22.sp),
                        selectedIcon: Icon(Icons.insights, size: 22.sp),
                        label: context.tr.tabStageAnalytics,
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.assignment_outlined, size: 22.sp),
                        selectedIcon: Icon(Icons.assignment, size: 22.sp),
                        label: context.tr.tabStageTasks,
                      ),
                    ],
                  ),
                  body: IndexedStack(
                    index: _selectedTabIndex,
                    children: [
                      // Tab 0: الخدام والتسكين وأمناء السنين
                      StagePeopleTab(
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
}
