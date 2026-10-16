import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../common/widgets/app_drawer.dart';
import '../../../common/widgets/notifications_sheet.dart';
import '../../../tasks/presentation/widgets/tasks_tab.dart';
import '../widgets/add_edit_makhdom_dialog.dart';
import '../widgets/excel_actions_sheet.dart';
import '../widgets/grade_makhdomeen_tab.dart';
import 'analytics_tab.dart';
import 'khodam_tab.dart';

class GradeAdminScreen extends StatefulWidget {
  final String grade; // '1st', '2nd', '3rd'
  final String? serviceId;

  const GradeAdminScreen({super.key, required this.grade, this.serviceId});

  @override
  State<GradeAdminScreen> createState() => _GradeAdminScreenState();
}

class _GradeAdminScreenState extends State<GradeAdminScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  late final String _serviceId = widget.serviceId ?? 'thanawy';
  late final Stream<List<MakhdomModel>> _makhdomeenStream;
  late final Stream<List<KhademModel>> _khodamStream;
  late final Stream<List<TaskModel>> _tasksStream;

  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _makhdomeenStream = _firestoreService.getMakhdomeenByGradeStream(
      widget.grade,
      serviceId: _serviceId,
    );
    _khodamStream = _firestoreService.getKhodamByGradeStream(
      widget.grade,
      serviceId: _serviceId,
    );
    _tasksStream = _firestoreService.getTasksForGradeStream(
      widget.grade,
      serviceId: _serviceId,
    );
  }

  String _getGradeLabel(BuildContext context) {
    switch (widget.grade) {
      case AppConstants.grade1st:
        return context.tr.grade1stName;
      case AppConstants.grade2nd:
        return context.tr.grade2ndName;
      case AppConstants.grade3rd:
        return context.tr.grade3rdName;
      default:
        return widget.grade;
    }
  }

  void _openAddMakhdomDialog(List<KhademModel> khodamList) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddEditMakhdomDialog(
        khodamList: khodamList,
        initialMakhdom: MakhdomModel(
          id: '',
          fullName: '',
          phone: '',
          grade: widget.grade,
          serviceId: _serviceId,
          createdAt: DateTime.now(),
        ),
      ),
    );
  }

  void _openExcelActionsSheet(List<MakhdomModel> currentList) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExcelActionsSheet(
        currentMakhdomeen: currentList,
        grade: widget.grade,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradeLabel = _getGradeLabel(context);

    return StreamBuilder<List<MakhdomModel>>(
      stream: _makhdomeenStream,
      builder: (context, makhdomeenSnap) {
        return StreamBuilder<List<KhademModel>>(
          stream: _khodamStream,
          builder: (context, khodamSnap) {
            final allMakhdomeen = makhdomeenSnap.data ?? [];
            final khodamList = khodamSnap.data ?? [];

            return Scaffold(
              drawer: AppDrawer(
                isAdmin: true,
                onOpenExcel: () => _openExcelActionsSheet(allMakhdomeen),
              ),
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
                      context.tr.gradeDashboardTitle(gradeLabel),
                      style: TextStyle(
                        fontSize: 16.5.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      context.tr.makhdomeenAndKhodamSummary(
                        allMakhdomeen.length,
                        khodamList.length,
                      ),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                actions: const [NotificationBellButton()],
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _selectedTabIndex,
                onDestinationSelected: (idx) =>
                    setState(() => _selectedTabIndex = idx),
                destinations: [
                  NavigationDestination(
                    icon: Icon(Icons.groups_outlined, size: 22.sp),
                    selectedIcon: Icon(Icons.groups, size: 22.sp),
                    label: context.tr.tabMakhdomeen(allMakhdomeen.length),
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.insights_outlined, size: 22.sp),
                    selectedIcon: Icon(Icons.insights, size: 22.sp),
                    label: context.tr.tabAnalytics,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.badge_outlined, size: 22.sp),
                    selectedIcon: Icon(Icons.badge, size: 22.sp),
                    label: context.tr.tabKhodam(khodamList.length),
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.task_alt_outlined, size: 22.sp),
                    selectedIcon: Icon(Icons.task_alt, size: 22.sp),
                    label: context.tr.tabGradeTasks,
                  ),
                ],
              ),
              body:
                  makhdomeenSnap.connectionState == ConnectionState.waiting &&
                      allMakhdomeen.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : IndexedStack(
                      index: _selectedTabIndex,
                      children: [
                        // Tab 0: قائمة المخدومين والفلترة والإسناد
                        GradeMakhdomeenTab(
                          grade: widget.grade,
                          allMakhdomeen: allMakhdomeen,
                          khodamList: khodamList,
                        ),

                        // Tab 1: لوحة التحليلات
                        AnalyticsTab(
                          makhdomeen: allMakhdomeen,
                          khodam: khodamList,
                          grade: widget.grade,
                          serviceId: _serviceId,
                        ),

                        // Tab 2: قائمة الخدام
                        KhodamTab(
                          khodam: khodamList,
                          allMakhdomeen: allMakhdomeen,
                        ),

                        // Tab 3: مهام السنة الدراسية
                        TasksTab(
                          tasksStream: _tasksStream,
                          availableKhodam: khodamList,
                          grade: widget.grade,
                          canCreateTasks: true,
                          serviceId: _serviceId,
                        ),
                      ],
                    ),
              floatingActionButton: _selectedTabIndex == 0
                  ? FloatingActionButton.extended(
                      onPressed: () => _openAddMakhdomDialog(khodamList),
                      backgroundColor: AppColors.primaryLight,
                      icon: Icon(
                        Icons.person_add_rounded,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                      label: Text(
                        context.tr.addMakhdomBtn,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}
