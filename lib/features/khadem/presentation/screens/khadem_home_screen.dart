import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/attendance_session_model.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/utils/color_generator.dart';
import '../../../common/widgets/app_drawer.dart';
import '../../../common/widgets/notifications_sheet.dart';
import '../../../tasks/presentation/widgets/tasks_tab.dart';
import '../widgets/my_analytics_tab.dart';
import '../widgets/my_makhdomeen_tab.dart';

class KhademHomeScreen extends StatefulWidget {
  final String? grade;
  final String? serviceId;

  const KhademHomeScreen({super.key, this.grade, this.serviceId});

  @override
  State<KhademHomeScreen> createState() => _KhademHomeScreenState();
}

class _KhademHomeScreenState extends State<KhademHomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  late final String _serviceId = widget.serviceId ?? 'thanawy';
  late final Stream<List<MakhdomModel>> _makhdomeenStream;
  late final Stream<List<TaskModel>> _tasksStream;
  late final Stream<List<AttendanceSessionModel>> _attendanceStream;

  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;
    _makhdomeenStream = _firestoreService.getMakhdomeenForKhademStream(
      user?.uid ?? '',
      serviceId: _serviceId,
    );
    _tasksStream = _firestoreService.getTasksForKhademStream(
      user?.uid ?? '',
      serviceId: _serviceId,
    );
    if (widget.grade != null) {
      _attendanceStream = _firestoreService.getAttendanceSessionsForGradeStream(
        widget.grade!,
        serviceId: _serviceId,
      );
    } else {
      _attendanceStream = _firestoreService.getAllAttendanceSessionsStream(
        serviceId: _serviceId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final khademColor = ColorGenerator.getColorForId(user?.uid ?? user?.email);

    return Scaffold(
      drawer: const AppDrawer(isAdmin: false),
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
              _selectedTabIndex == 0
                  ? context.tr.myGroupAndVisits
                  : (_selectedTabIndex == 1
                        ? context.tr.myTasksTitle
                        : context.tr.servantMyAnalytics),
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16.sp),
            ),
            if (widget.grade != null)
              Text(
                widget.grade == AppConstants.grade1st
                    ? context.tr.grade1stName
                    : (widget.grade == AppConstants.grade2nd
                          ? context.tr.grade2ndName
                          : context.tr.grade3rdName),
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        actions: const [NotificationBellButton()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTabIndex,
        onDestinationSelected: (idx) => setState(() => _selectedTabIndex = idx),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people),
            label: context.tr.myGroupAndVisits,
          ),
          NavigationDestination(
            icon: const Icon(Icons.task_alt_outlined),
            selectedIcon: const Icon(Icons.task_alt),
            label: context.tr.myTasksTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.analytics_outlined),
            selectedIcon: const Icon(Icons.analytics),
            label: context.tr.servantMyAnalytics,
          ),
        ],
      ),
      body: StreamBuilder<List<MakhdomModel>>(
        stream: _makhdomeenStream,
        builder: (context, makhdomeenSnap) {
          return StreamBuilder<List<AttendanceSessionModel>>(
            stream: _attendanceStream,
            builder: (context, attendanceSnap) {
              if (makhdomeenSnap.connectionState == ConnectionState.waiting &&
                  !makhdomeenSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allMyMakhdomeen = makhdomeenSnap.data ?? [];
              final attendanceSessions = attendanceSnap.data ?? [];

              return IndexedStack(
                index: _selectedTabIndex,
                children: [
                  // Tab 0: قائمة المخدومين والافتقاد مع تنبيه الغياب المبكر
                  MyMakhdomeenTab(
                    myMakhdomeen: allMyMakhdomeen,
                    sessions: attendanceSessions,
                    servantName: user?.displayName,
                    khademColor: khademColor,
                    onSwitchToAnalytics: () => setState(() => _selectedTabIndex = 2),
                  ),

                  // Tab 1: مهامي المكلف بها
                  TasksTab(
                    tasksStream: _tasksStream,
                    availableKhodam: const [],
                    grade: widget.grade ?? 'all',
                    canCreateTasks: false,
                  ),

                  // Tab 2: إحصائياتي الشخصية عن أولادي
                  MyAnalyticsTab(
                    myMakhdomeen: allMyMakhdomeen,
                    sessions: attendanceSessions,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
