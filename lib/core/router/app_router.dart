import 'package:flutter/foundation.dart' show kIsWeb;
import '../widgets/web/web_widgets.dart';
import '../utils/calendar_dates.dart';
import '../widgets/query_content.dart';
import '../models/visit_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/constants.dart';
import '../localization/app_localizations.dart';
import '../localization/domain_labels.dart';
import '../models/attendance_session_model.dart';
import '../models/khadem_model.dart';
import '../models/makhdom_model.dart';
import '../models/task_model.dart';
import 'route_resource_loader.dart';
import '../errors/app_failure.dart';
import '../repositories/attendance_repository.dart';
import '../services/attendance_roster_repository.dart';
import 'router_services.dart';
import '../services/firestore_service.dart';
import '../session/session_cubit.dart';
import '../session/session_state.dart';
import 'app_routes.dart';
import 'notification_intent_coordinator.dart';
import 'route_access_service.dart';
import 'router_refresh_notifier.dart';
import 'widgets/protected_resource_page.dart';

// Screen imports
import '../../features/admin/presentation/screens/analytics_tab.dart';
import '../../features/admin/presentation/screens/khodam_tab.dart';
import '../../features/admin/presentation/screens/makhdom_history_screen.dart';
import '../../features/admin/presentation/widgets/add_edit_makhdom_dialog.dart';
import '../../features/admin/presentation/widgets/excel_actions_sheet.dart';
import '../../features/admin/presentation/widgets/grade_makhdomeen_tab.dart';
import '../models/service_model.dart';
import '../../features/admin/presentation/widgets/stage_people_tab.dart';
import '../../features/admin/presentation/widgets/service_setup_dialog.dart';
import '../../features/admin/presentation/widgets/manage_classes_dialog.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/pending_assignment_screen.dart';
import '../../features/auth/presentation/web/login_web_screen.dart';
import '../../features/auth/presentation/web/pending_assignment_web_screen.dart';
import '../../features/attendance/presentation/screens/attendance_hub_tab.dart';
import '../../features/attendance/presentation/screens/attendance_screen.dart';
import '../../features/common/presentation/screens/notifications_screen.dart';
import '../../features/common/presentation/screens/route_error_screen.dart';
import '../../features/common/presentation/screens/splash_screen.dart';
import '../../features/common/widgets/app_drawer.dart';
import '../../features/common/widgets/app_update_dialog.dart';
import '../../features/common/widgets/notifications_sheet.dart';
import '../../features/khadem/presentation/screens/khadem_profile_screen.dart';
import '../../features/khadem/presentation/widgets/my_analytics_tab.dart';
import '../../features/khadem/presentation/widgets/my_makhdomeen_tab.dart';
import '../../features/khadem/presentation/web/my_makhdomeen_web_screen.dart';
import '../../features/khadem/presentation/web/my_analytics_web_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/tasks/presentation/screens/task_details_screen.dart';
import '../../features/tasks/presentation/widgets/tasks_tab.dart';
import '../../features/tasks/presentation/web/my_tasks_web_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';

/// Intent ownership belongs to this router, never to another login/router.
class RouterIntentState {
  String? intendedRoute;
  String? _owner;
  String? _lastScope;
  bool _hadActiveSession = false;

  bool observe(SessionState session) {
    var cleared = false;
    final scope = session.scopeKey;
    if ((_owner != null && session.status == SessionStatus.signedOut) ||
        (_hadActiveSession &&
            (session.status == SessionStatus.signedOut ||
                (session.isActive && _lastScope != scope)))) {
      intendedRoute = null;
      _owner = null;
      cleared = true;
    }
    if (_owner != null && session.userId != null && _owner != session.userId) {
      intendedRoute = null;
    }
    if (session.userId != null) _owner = session.userId;
    if (session.status == SessionStatus.signedOut) {
      _hadActiveSession = false;
      _lastScope = null;
    }
    if (session.isActive) {
      _hadActiveSession = true;
      _lastScope = scope;
    }
    return cleared;
  }

  void remember(Uri uri) {
    if (RouteAccessService.isSafeInternalUri(uri) &&
        !{
          AppRoutes.bootstrapPath,
          AppRoutes.loginPath,
          AppRoutes.pendingPath,
          AppRoutes.deletingPath,
          AppRoutes.sessionFailurePath,
          '/',
        }.contains(uri.path)) {
      intendedRoute ??= uri.toString();
    }
  }
}

String? evaluateAppRouterRedirect({
  required SessionState session,
  required String matchedLocation,
  required Uri uri,
  RouteAccessService routeAccessService = const RouteAccessService(),
  NotificationIntentCoordinator? notificationIntentCoordinator,
  RouterIntentState? intentState,
}) {
  final intents = intentState ?? RouterIntentState();
  final discardedOldScope = intents.observe(session);
  notificationIntentCoordinator?.observe(session);
  final path = matchedLocation;
  if (session.status == SessionStatus.booting ||
      session.status == SessionStatus.profileLoading) {
    intents.remember(uri);
    if (session.status == SessionStatus.profileLoading &&
        path == AppRoutes.loginPath) {
      return null;
    }
    return path == AppRoutes.bootstrapPath ? null : AppRoutes.bootstrapPath;
  }
  if (session.status == SessionStatus.failure) {
    intents.remember(uri);
    return path == AppRoutes.sessionFailurePath ||
            path == AppRoutes.settingsPath
        ? null
        : AppRoutes.sessionFailurePath;
  }
  if (session.isDeleting) {
    intents.intendedRoute = null;
    return path == AppRoutes.deletingPath ? null : AppRoutes.deletingPath;
  }
  if (session.status == SessionStatus.signedOut || !session.isAuthenticated) {
    if (path == AppRoutes.settingsPath || path == AppRoutes.loginPath) {
      return null;
    }
    if (!discardedOldScope) intents.remember(uri);
    return AppRoutes.loginPath;
  }
  if (session.isPending) {
    if ({
      AppRoutes.pendingPath,
      AppRoutes.settingsPath,
      AppRoutes.profilePath,
    }.contains(path)) {
      return null;
    }
    intents.remember(uri);
    return AppRoutes.pendingPath;
  }
  if (session.isActive) {
    final intentPath = notificationIntentCoordinator?.consumeFor(session);
    if (intentPath != null && intentPath != uri.toString()) return intentPath;
    if ({
          AppRoutes.loginPath,
          AppRoutes.bootstrapPath,
          AppRoutes.pendingPath,
          AppRoutes.sessionFailurePath,
        }.contains(path) &&
        intents.intendedRoute != null) {
      final target = intents.intendedRoute!;
      intents.intendedRoute = null;
      final access = routeAccessService.check(Uri.parse(target), session);
      if (access == RouteAccessResult.allowed) return target;
      return access == RouteAccessResult.denied
          ? AppRoutes.forbiddenPath
          : AppRoutes.notFoundPath;
    }
    if ({
      AppRoutes.bootstrapPath,
      AppRoutes.loginPath,
      AppRoutes.pendingPath,
      AppRoutes.deletingPath,
      AppRoutes.sessionFailurePath,
      '/',
      '',
    }.contains(path)) {
      return AppRoutes.landing(session);
    }
    final access = routeAccessService.check(uri, session);
    if (access == RouteAccessResult.denied) return AppRoutes.forbiddenPath;
    if (access == RouteAccessResult.notFound) {
      return path == AppRoutes.notFoundPath ? null : AppRoutes.notFoundPath;
    }
  }
  return null;
}

GoRouter createAppRouter({
  required SessionCubit sessionCubit,
  RouteAccessService routeAccessService = const RouteAccessService(),
  NotificationIntentCoordinator? notificationIntentCoordinator,
  String? initialLocation,
  RouteResourceLoader? resourceLoader,
  FirestoreService? firestoreService,
  AttendanceRepository? attendanceRepository,
  Future<List<AttendanceRosterRow>> Function(String)? attendanceRosterLoader,
}) {
  final intents = RouterIntentState();
  final resources = resourceLoader ?? FirestoreRouteResourceLoader();
  final firestore = firestoreService ?? FirestoreService();
  List<RouteBase> routes() => [
    // Top-level Public & Auth Routes
    GoRoute(
      path: AppRoutes.bootstrapPath,
      name: AppRoutes.bootstrapName,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.loginPath,
      name: AppRoutes.loginName,
      builder: (context, state) =>
          kIsWeb ? const LoginWebScreen() : const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.pendingPath,
      name: AppRoutes.pendingName,
      builder: (context, state) => BlocProvider.value(
        value: sessionCubit,
        child: kIsWeb
            ? const PendingAssignmentWebScreen()
            : const PendingAssignmentScreen(),
      ),
    ),

    GoRoute(
      path: AppRoutes.deletingPath,
      builder: (context, state) =>
          _SessionExitScreen(sessionCubit: sessionCubit, deleting: true),
    ),
    GoRoute(
      path: AppRoutes.sessionFailurePath,
      builder: (context, state) =>
          _SessionExitScreen(sessionCubit: sessionCubit),
    ),
    // Top-level Utilities & Settings Routes
    GoRoute(
      path: AppRoutes.profilePath,
      name: AppRoutes.profileName,
      pageBuilder: (context, state) => NoTransitionPage(
        key: ValueKey('profile/${sessionCubit.state.scopeKey}'),
        child: BlocProvider.value(
          value: sessionCubit,
          child: const KhademProfileScreen(),
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.settingsPath,
      name: AppRoutes.settingsName,
      pageBuilder: (context, state) => NoTransitionPage(
        key: ValueKey('settings/${sessionCubit.state.scopeKey}'),
        child: BlocProvider.value(
          value: sessionCubit,
          child: const SettingsScreen(),
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.reportsPath,
      name: AppRoutes.reportsName,
      pageBuilder: (context, state) => NoTransitionPage(
        key: ValueKey('reports/${sessionCubit.state.scopeKey}'),
        child: RouterServices(
          firestore: firestore,
          session: sessionCubit,
          child: const ReportsScreen(),
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.notificationsPath,
      name: AppRoutes.notificationsName,
      pageBuilder: (context, state) => NoTransitionPage(
        key: ValueKey('notifications/${sessionCubit.state.scopeKey}'),
        child: RouterServices(
          firestore: firestore,
          session: sessionCubit,
          child: const NotificationsScreen(),
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.forbiddenPath,
      name: AppRoutes.forbiddenName,
      builder: (context, state) =>
          const RouteErrorScreen(type: RouteErrorType.forbidden),
    ),
    GoRoute(
      path: AppRoutes.notFoundPath,
      name: AppRoutes.notFoundName,
      builder: (context, state) =>
          const RouteErrorScreen(type: RouteErrorType.notFound),
    ),

    // Resource Detail Stack Routes (IDs in URL, extra is optional cache)
    GoRoute(
      path: AppRoutes.makhdomHistoryPattern,
      name: AppRoutes.makhdomHistoryName,
      builder: (context, state) {
        final makhdomId = state.pathParameters['makhdomId'] ?? '';
        return BlocBuilder<SessionCubit, SessionState>(
          bloc: sessionCubit,
          builder: (context, session) => ProtectedResourcePage<MakhdomModel>(
            key: ValueKey('$makhdomId/${session.scopeKey}'),
            loadResource: () => _loadAuthorized(
              routeAccessService.loadChild(
                resources,
                makhdomId,
                () => sessionCubit.state,
              ),
              (child) =>
                  routeAccessService.authorizeChild(child, sessionCubit.state),
              AppRoutes.makhdomHistory(makhdomId),
              session,
              notificationIntentCoordinator,
            ),
            watchResource: () => resources.watchChild(makhdomId),
            authorize: (child) =>
                routeAccessService.authorizeChild(child, sessionCubit.state),
            builder: (context, child) => MakhdomHistoryScreen(
              makhdom: child,
              firestoreService: firestore,
            ),
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.taskDetailsPattern,
      name: AppRoutes.taskDetailsName,
      builder: (context, state) {
        final taskId = state.pathParameters['taskId'] ?? '';
        return BlocBuilder<SessionCubit, SessionState>(
          bloc: sessionCubit,
          builder: (context, session) => ProtectedResourcePage<TaskModel>(
            key: ValueKey('$taskId/${session.scopeKey}'),
            loadResource: () => _loadAuthorized(
              routeAccessService.loadTask(
                resources,
                taskId,
                () => sessionCubit.state,
              ),
              (task) =>
                  routeAccessService.authorizeTask(task, sessionCubit.state),
              AppRoutes.taskDetails(taskId),
              session,
              notificationIntentCoordinator,
            ),
            watchResource: () => resources.watchTask(taskId),
            authorize: (task) =>
                routeAccessService.authorizeTask(task, sessionCubit.state),
            builder: (context, task) =>
                TaskDetailsScreen(taskId: taskId, task: task),
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.taskAttendancePattern,
      name: AppRoutes.taskAttendanceName,
      builder: (context, state) {
        final taskId = state.pathParameters['taskId'] ?? '';
        return BlocBuilder<SessionCubit, SessionState>(
          bloc: sessionCubit,
          builder: (context, session) => ProtectedResourcePage<TaskModel>(
            key: ValueKey('attendance/$taskId/${session.scopeKey}'),
            loadResource: () => _loadAuthorized(
              routeAccessService.loadTask(
                resources,
                taskId,
                () => sessionCubit.state,
                attendance: true,
              ),
              (task) => routeAccessService.authorizeTask(
                task,
                sessionCubit.state,
                attendance: true,
              ),
              AppRoutes.taskAttendance(taskId),
              session,
              notificationIntentCoordinator,
            ),
            watchResource: () => resources.watchTask(taskId),
            authorize: (task) => routeAccessService.authorizeTask(
              task,
              sessionCubit.state,
              attendance: true,
            ),
            builder: (context, task) => BlocProvider.value(
              value: sessionCubit,
              child: AttendanceScreen(
                key: ValueKey(
                  '${task.id}/${task.grade}/${task.type}/${task.attendanceDay}',
                ),
                task: task,
                repository: attendanceRepository,
                loadRoster: attendanceRosterLoader,
              ),
            ),
          ),
        );
      },
    ),

    // 1. Stage Shell Route (/stage/*)
    StatefulShellRoute.indexedStack(
      pageBuilder: (context, state, navigationShell) => NoTransitionPage(
        key: ValueKey('stage/${sessionCubit.state.scopeKey}'),
        child: RouterServices(
          firestore: firestore,
          session: sessionCubit,
          child: _StageShellScaffold(navigationShell: navigationShell),
        ),
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.stagePeoplePath,
              name: AppRoutes.stagePeopleName,
              builder: (context, state) => const _StagePeopleWrapper(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.stageAnalyticsPath,
              name: AppRoutes.stageAnalyticsName,
              builder: (context, state) => const _StageAnalyticsWrapper(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.stageTasksPath,
              name: AppRoutes.stageTasksName,
              builder: (context, state) => const _StageTasksWrapper(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.stageAttendancePath,
              name: AppRoutes.stageAttendanceName,
              builder: (context, state) => BlocProvider.value(
                value: sessionCubit,
                child: AttendanceHubTab(repository: attendanceRepository),
              ),
            ),
          ],
        ),
      ],
    ),

    // 2. Grade Shell Route (/grades/:grade/*)
    StatefulShellRoute.indexedStack(
      pageBuilder: (context, state, navigationShell) => NoTransitionPage(
        key: ValueKey(
          'grade/${state.pathParameters['grade']}/${sessionCubit.state.scopeKey}',
        ),
        child: RouterServices(
          firestore: firestore,
          session: sessionCubit,
          child: _GradeShellScaffold(
            grade: state.pathParameters['grade']!,
            navigationShell: navigationShell,
          ),
        ),
      ),
      branches: [
        StatefulShellBranch(
          initialLocation: '/grades/1st/makhdomeen',
          routes: [
            GoRoute(
              path: AppRoutes.gradeMakhdomeenPattern,
              name: AppRoutes.gradeMakhdomeenName,
              builder: (context, state) {
                final grade =
                    state.pathParameters['grade'] ?? AppConstants.grade1st;
                return _GradeMakhdomeenWrapper(grade: grade);
              },
            ),
          ],
        ),
        StatefulShellBranch(
          initialLocation: '/grades/1st/analytics',
          routes: [
            GoRoute(
              path: AppRoutes.gradeAnalyticsPattern,
              name: AppRoutes.gradeAnalyticsName,
              builder: (context, state) {
                final grade =
                    state.pathParameters['grade'] ?? AppConstants.grade1st;
                return _GradeAnalyticsWrapper(grade: grade);
              },
            ),
          ],
        ),
        StatefulShellBranch(
          initialLocation: '/grades/1st/khodam',
          routes: [
            GoRoute(
              path: AppRoutes.gradeKhodamPattern,
              name: AppRoutes.gradeKhodamName,
              builder: (context, state) {
                final grade =
                    state.pathParameters['grade'] ?? AppConstants.grade1st;
                return _GradeKhodamWrapper(grade: grade);
              },
            ),
          ],
        ),
        StatefulShellBranch(
          initialLocation: '/grades/1st/tasks',
          routes: [
            GoRoute(
              path: AppRoutes.gradeTasksPattern,
              name: AppRoutes.gradeTasksName,
              builder: (context, state) {
                final grade =
                    state.pathParameters['grade'] ?? AppConstants.grade1st;
                return _GradeTasksWrapper(grade: grade);
              },
            ),
          ],
        ),
        StatefulShellBranch(
          initialLocation: '/grades/1st/attendance',
          routes: [
            GoRoute(
              path: AppRoutes.gradeAttendancePattern,
              name: AppRoutes.gradeAttendanceName,
              builder: (context, state) {
                final grade =
                    state.pathParameters['grade'] ?? AppConstants.grade1st;
                return BlocProvider.value(
                  value: sessionCubit,
                  child: AttendanceHubTab(
                    fixedGrade: grade,
                    repository: attendanceRepository,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    ),

    // 3. Servant (Me) Shell Route (/me/*)
    StatefulShellRoute.indexedStack(
      pageBuilder: (context, state, navigationShell) => NoTransitionPage(
        key: ValueKey('me/${sessionCubit.state.scopeKey}'),
        child: RouterServices(
          firestore: firestore,
          session: sessionCubit,
          child: _ServantShellScaffold(navigationShell: navigationShell),
        ),
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.myMakhdomeenPath,
              name: AppRoutes.myMakhdomeenName,
              builder: (context, state) => const _MyMakhdomeenWrapper(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.myTasksPath,
              name: AppRoutes.myTasksName,
              builder: (context, state) => const _MyTasksWrapper(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.myAnalyticsPath,
              name: AppRoutes.myAnalyticsName,
              builder: (context, state) => const _MyAnalyticsWrapper(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.myAttendancePath,
              name: AppRoutes.myAttendanceName,
              builder: (context, state) {
                final grade = sessionCubit.state.grade ?? AppConstants.grade1st;
                return BlocProvider.value(
                  value: sessionCubit,
                  child: AttendanceHubTab(
                    fixedGrade: grade,
                    repository: attendanceRepository,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    ),
  ];
  String? redirect(BuildContext context, GoRouterState state) =>
      evaluateAppRouterRedirect(
        intentState: intents,
        session: sessionCubit.state,
        matchedLocation: state.matchedLocation,
        uri: state.uri,
        routeAccessService: routeAccessService,
        notificationIntentCoordinator: notificationIntentCoordinator,
      );
  final configuration = ValueNotifier(
    RoutingConfig(routes: routes(), redirect: redirect),
  );
  final refresh = RouterRefreshNotifier(
    sessionCubit,
    coordinator: notificationIntentCoordinator,
    onScopeChange: () => configuration.value = RoutingConfig(
      routes: routes(),
      redirect: redirect,
    ),
    onDispose: configuration.dispose,
  );
  return GoRouter.routingConfig(
    routingConfig: configuration,
    initialLocation: initialLocation ?? AppRoutes.bootstrapPath,
    refreshListenable: refresh,
    errorBuilder: (context, state) =>
        const RouteErrorScreen(type: RouteErrorType.notFound),
  );
}

// =============================================================================
// Shell Scaffolds
// =============================================================================

class _StageShellScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _StageShellScaffold({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final firestore = RouterServices.of(context).firestore;
    final session = RouterServices.of(context).session.state;
    final serviceId = session.profile?.serviceId ?? 'thanawy';

    if (kIsWeb) {
      return StreamBuilder<ServiceModel?>(
        stream: firestore.watchService(serviceId),
        builder: (context, snapshot) {
          final service = snapshot.data;
          final serviceName = service?.name;
          final title = (serviceName != null && serviceName.isNotEmpty)
              ? serviceName
              : context.tr.stageDashboardTitle;

          return WebScaffold(
            title: title,
            subtitle: 'لوحة تحكم أمين المرحلة',
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (idx) =>
                navigationShell.goBranch(idx, initialLocation: false),
            destinations: [
              WebNavDestination(
                icon: Icons.manage_accounts_outlined,
                selectedIcon: Icons.manage_accounts,
                label: context.tr.tabGradesAndServants,
              ),
              WebNavDestination(
                icon: Icons.insights_outlined,
                selectedIcon: Icons.insights,
                label: context.tr.tabStageAnalytics,
              ),
              WebNavDestination(
                icon: Icons.assignment_outlined,
                selectedIcon: Icons.assignment,
                label: context.tr.tabStageTasks,
              ),
              const WebNavDestination(
                icon: Icons.how_to_reg_outlined,
                selectedIcon: Icons.how_to_reg,
                label: 'الحضور والغياب',
              ),
            ],
            actions: [
              if (service != null)
                IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  tooltip: 'تخصيص الخدمة والصفوف',
                  onPressed: () => ServiceSetupDialog.show(
                    context,
                    service: service,
                    firestoreService: firestore,
                  ),
                ),
            ],
            body: navigationShell,
          );
        },
      );
    }

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
        title: StreamBuilder<ServiceModel?>(
          stream: firestore.watchService(serviceId),
          builder: (context, snapshot) {
            final name = snapshot.data?.name;
            return Text(
              name != null && name.isNotEmpty ? name : context.tr.stageDashboardTitle,
              style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900),
            );
          },
        ),
        actions: [
          StreamBuilder<ServiceModel?>(
            stream: firestore.watchService(serviceId),
            builder: (context, snapshot) {
              final service = snapshot.data;
              if (service == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.tune_rounded),
                tooltip: 'تخصيص الخدمة والصفوف',
                onPressed: () => ServiceSetupDialog.show(
                  context,
                  service: service,
                  firestoreService: firestore,
                ),
              );
            },
          ),
          const NotificationBellButton(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (idx) =>
            navigationShell.goBranch(idx, initialLocation: false),
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
          const NavigationDestination(
            icon: Icon(Icons.how_to_reg_outlined),
            selectedIcon: Icon(Icons.how_to_reg),
            label: 'الحضور والغياب',
          ),
        ],
      ),
      body: AppVersionUpdateGuard(child: navigationShell),
    );
  }
}

class _GradeShellScaffold extends StatefulWidget {
  final String grade;
  final StatefulNavigationShell navigationShell;

  const _GradeShellScaffold({
    required this.grade,
    required this.navigationShell,
  });

  @override
  State<_GradeShellScaffold> createState() => _GradeShellScaffoldState();
}

class _GradeShellScaffoldState extends State<_GradeShellScaffold> {
  late final Set<int> _visited = {widget.navigationShell.currentIndex};
  String get grade => widget.grade;
  StatefulNavigationShell get navigationShell => widget.navigationShell;
  void _select(BuildContext context, int index) {
    if (_visited.add(index)) {
      context.go(
        [
          AppRoutes.gradeMakhdomeen(grade),
          AppRoutes.gradeAnalytics(grade),
          AppRoutes.gradeKhodam(grade),
          AppRoutes.gradeTasks(grade),
          AppRoutes.gradeAttendance(grade),
        ][index],
      );
    } else {
      navigationShell.goBranch(index);
    }
  }

  String _getGradeLabel(BuildContext context, [ServiceModel? service]) {
    if (service != null && service.grades.isNotEmpty) {
      final match = service.grades.where((g) => g.id == grade).firstOrNull;
      if (match != null && match.name.isNotEmpty) return match.name;
    }
    switch (grade) {
      case AppConstants.grade1st:
        return context.tr.grade1stName;
      case AppConstants.grade2nd:
        return context.tr.grade2ndName;
      case AppConstants.grade3rd:
        return context.tr.grade3rdName;
      default:
        return DomainLabels(Localizations.localeOf(context)).gradeName(grade);
    }
  }

  void _openAddMakhdomDialog(
    BuildContext context,
    List<KhademModel> khodamList,
  ) {
    final serviceId =
        RouterServices.of(context).session.state.profile?.serviceId ?? 'thanawy';
    showDialog(
      context: context,
      builder: (ctx) => AddEditMakhdomDialog(
        khodamList: khodamList,
        initialMakhdom: MakhdomModel(
          id: '',
          fullName: '',
          phone: '',
          grade: grade,
          serviceId: serviceId,
          createdAt: DateTime.now(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = RouterServices.of(context).firestore;
    final session = RouterServices.of(context).session.state;
    final serviceId = session.profile?.serviceId ?? 'thanawy';

    return StreamBuilder<ServiceModel?>(
      stream: firestoreService.watchService(serviceId),
      builder: (context, serviceSnap) {
        final gradeLabel = _getGradeLabel(context, serviceSnap.data);
        return QueryContent<List<KhademModel>>(
          queryKey: '${session.scopeKey}/shell',
          query: () => firestoreService.getKhodamByGradeStream(grade, serviceId: serviceId),
          builder: (context, khodamList) {
            if (kIsWeb) {
              return WebScaffold(
                title: context.tr.gradeDashboardTitle(gradeLabel),
                subtitle: 'لوحة تحكم $gradeLabel',
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (idx) => _select(context, idx),
            floatingActionButton: navigationShell.currentIndex == 0
                ? FloatingActionButton.extended(
                    onPressed: () => _openAddMakhdomDialog(context, khodamList),
                    backgroundColor: AppConstants.primaryLight,
                    icon: const Icon(
                      Icons.person_add_rounded,
                      color: Colors.white,
                    ),
                    label: Text(
                      context.tr.addMakhdomBtn,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  )
                : null,
            destinations: [
              WebNavDestination(
                icon: Icons.groups_outlined,
                selectedIcon: Icons.groups,
                label: context.tr.messageMakhdomeen,
              ),
              WebNavDestination(
                icon: Icons.insights_outlined,
                selectedIcon: Icons.insights,
                label: context.tr.tabAnalytics,
              ),
              WebNavDestination(
                icon: Icons.badge_outlined,
                selectedIcon: Icons.badge,
                label: context.tr.tabKhodam(khodamList.length),
              ),
              WebNavDestination(
                icon: Icons.task_alt_outlined,
                selectedIcon: Icons.task_alt,
                label: context.tr.tabGradeTasks,
              ),
              const WebNavDestination(
                icon: Icons.how_to_reg_outlined,
                selectedIcon: Icons.how_to_reg,
                label: 'الحضور والغياب',
              ),
            ],
            actions: [
              if (session.isStageAdmin)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 4),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppConstants.sacredGold,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                    icon: const Icon(Icons.dashboard_outlined, size: 18),
                    label: const Text(
                      'لوحة المرحلة',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () => context.go(AppRoutes.stagePeoplePath),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.table_chart_outlined, size: 20),
                tooltip: 'عمليات Excel (استيراد وتصدير)',
                onPressed: () async {
                  final makhdomeen = await firestoreService.getMakhdomeenByGrade(
                    grade,
                    serviceId: serviceId,
                  );
                  if (context.mounted) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => ExcelActionsSheet(
                        currentMakhdomeen: makhdomeen,
                        grade: grade,
                      ),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.diversity_3_outlined, size: 20),
                tooltip: 'إدارة فصول السنة',
                onPressed: () {
                  final serviceId =
                      RouterServices.of(context).session.state.profile?.serviceId ??
                      'thanawy';
                  ManageClassesDialog.show(
                    context,
                    serviceId: serviceId,
                    gradeId: grade,
                    gradeTitle: gradeLabel,
                    khodamList: khodamList,
                    firestoreService: firestoreService,
                  );
                },
              ),
            ],
            body: navigationShell,
          );
        }

        return Scaffold(
          drawer: AppDrawer(
            isAdmin: true,
            onOpenExcel: () async {
              final makhdomeen = await firestoreService.getMakhdomeenByGrade(
                grade,
                serviceId: serviceId,
              );
              if (context.mounted) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ExcelActionsSheet(
                    currentMakhdomeen: makhdomeen,
                    grade: grade,
                  ),
                );
              }
            },
          ),
          appBar: AppBar(
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                tooltip: context.tr.messageMainMenu,
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            title: Text(
              context.tr.gradeDashboardTitle(gradeLabel),
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.diversity_3_outlined, size: 22),
                tooltip: 'إدارة فصول السنة',
                onPressed: () {
                  final serviceId =
                      RouterServices.of(context).session.state.profile?.serviceId ??
                      'thanawy';
                  ManageClassesDialog.show(
                    context,
                    serviceId: serviceId,
                    gradeId: grade,
                    gradeTitle: gradeLabel,
                    khodamList: khodamList,
                    firestoreService: firestoreService,
                  );
                },
              ),
              const NotificationBellButton(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (idx) => _select(context, idx),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.groups_outlined),
                selectedIcon: const Icon(Icons.groups),
                label: context.tr.messageMakhdomeen,
              ),
              NavigationDestination(
                icon: const Icon(Icons.insights_outlined),
                selectedIcon: const Icon(Icons.insights),
                label: context.tr.tabAnalytics,
              ),
              NavigationDestination(
                icon: const Icon(Icons.badge_outlined),
                selectedIcon: const Icon(Icons.badge),
                label: context.tr.tabKhodam(khodamList.length),
              ),
              NavigationDestination(
                icon: const Icon(Icons.task_alt_outlined),
                selectedIcon: const Icon(Icons.task_alt),
                label: context.tr.tabGradeTasks,
              ),
              const NavigationDestination(
                icon: Icon(Icons.how_to_reg_outlined),
                selectedIcon: Icon(Icons.how_to_reg),
                label: 'الحضور والغياب',
              ),
            ],
          ),
          floatingActionButton: navigationShell.currentIndex == 0
              ? FloatingActionButton.extended(
                  onPressed: () => _openAddMakhdomDialog(context, khodamList),
                  backgroundColor: AppConstants.primaryLight,
                  icon: const Icon(
                    Icons.person_add_rounded,
                    color: Colors.white,
                  ),
                  label: Text(
                    context.tr.addMakhdomBtn,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                )
              : null,
          body: AppVersionUpdateGuard(child: navigationShell),
        );
      },
    );
      },
    );
  }
}

class _ServantShellScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _ServantShellScaffold({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return WebScaffold(
        title: context.tr.appName,
        subtitle: 'لوحة الخادم',
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (idx) =>
            navigationShell.goBranch(idx, initialLocation: false),
        destinations: [
          WebNavDestination(
            icon: Icons.people_alt_outlined,
            selectedIcon: Icons.people_alt,
            label: context.tr.messageMyStudents,
          ),
          WebNavDestination(
            icon: Icons.task_alt_outlined,
            selectedIcon: Icons.task_alt,
            label: context.tr.messageMyTasks,
          ),
          WebNavDestination(
            icon: Icons.insights_outlined,
            selectedIcon: Icons.insights,
            label: context.tr.tabAnalytics,
          ),
          const WebNavDestination(
            icon: Icons.how_to_reg_outlined,
            selectedIcon: Icons.how_to_reg,
            label: 'الحضور والغياب',
          ),
        ],
        body: navigationShell,
      );
    }

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
        title: Text(
          context.tr.appName,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        actions: const [NotificationBellButton()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (idx) =>
            navigationShell.goBranch(idx, initialLocation: false),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.people_alt_outlined),
            selectedIcon: const Icon(Icons.people_alt),
            label: context.tr.messageMyStudents,
          ),
          NavigationDestination(
            icon: const Icon(Icons.task_alt_outlined),
            selectedIcon: const Icon(Icons.task_alt),
            label: context.tr.messageMyTasks,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights),
            label: context.tr.tabAnalytics,
          ),
          const NavigationDestination(
            icon: Icon(Icons.how_to_reg_outlined),
            selectedIcon: Icon(Icons.how_to_reg),
            label: 'الحضور والغياب',
          ),
        ],
      ),
      body: AppVersionUpdateGuard(child: navigationShell),
    );
  }
}

// =============================================================================
// Shell Branch Wrappers
// =============================================================================

class _StagePeopleWrapper extends StatelessWidget {
  const _StagePeopleWrapper();

  @override
  Widget build(BuildContext context) {
    final firestore = RouterServices.of(context).firestore;
    final session = RouterServices.of(context).session.state;
    final serviceId = session.profile?.serviceId ?? 'thanawy';

    return QueryContent<ServiceModel?>(
      queryKey: '${session.scopeKey}/service',
      query: () => firestore.watchService(serviceId),
      builder: (context, service) {
        return QueryContent<List<MakhdomModel>>(
          queryKey: '${session.scopeKey}/makhdomeenSnap',
          query: () => firestore.getMakhdomeenStream(serviceId: serviceId),
          builder: (context, makhdomeenSnap) {
            return QueryContent<List<KhademModel>>(
              queryKey: '${session.scopeKey}/khodamSnap',
              query: () => firestore.getKhodamStream(serviceId: serviceId),
              builder: (context, khodamSnap) {
                final allKhodam = khodamSnap;
                final pendingKhodam = allKhodam
                    .where((k) => k.isPending || !k.isActive)
                    .toList();
                final allMakhdomeen = makhdomeenSnap;

                return StagePeopleTab(
                  pendingKhodam: pendingKhodam,
                  allKhodam: allKhodam,
                  allMakhdomeen: allMakhdomeen,
                  service: service,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _StageAnalyticsWrapper extends StatelessWidget {
  const _StageAnalyticsWrapper();

  @override
  Widget build(BuildContext context) {
    final firestore = RouterServices.of(context).firestore;
    final session = RouterServices.of(context).session.state;
    final serviceId = session.profile?.serviceId ?? 'thanawy';

    return QueryContent<List<MakhdomModel>>(
      queryKey: '${session.scopeKey}/makhdomeenSnap',
      query: () => firestore.getMakhdomeenStream(serviceId: serviceId),
      builder: (context, makhdomeenSnap) {
        return QueryContent<List<KhademModel>>(
          queryKey: '${session.scopeKey}/khodamSnap',
          query: () => firestore.getKhodamStream(serviceId: serviceId),
          builder: (context, khodamSnap) {
            final allKhodam = khodamSnap;
            final activeKhodam = allKhodam.where((k) => k.isActive).toList();
            final allMakhdomeen = makhdomeenSnap;

            return AnalyticsTab(
              firestoreService: firestore,
              makhdomeen: allMakhdomeen,
              khodam: activeKhodam,
              serviceId: serviceId,
            );
          },
        );
      },
    );
  }
}

class _StageTasksWrapper extends StatelessWidget {
  const _StageTasksWrapper();

  @override
  Widget build(BuildContext context) {
    final firestore = RouterServices.of(context).firestore;
    final session = RouterServices.of(context).session.state;
    final serviceId = session.profile?.serviceId ?? 'thanawy';

    return QueryContent<List<KhademModel>>(
      queryKey: '${session.scopeKey}/khodamSnap',
      query: () => firestore.getKhodamStream(serviceId: serviceId),
      builder: (context, khodamSnap) {
        final allKhodam = khodamSnap;
        final activeKhodam = allKhodam.where((k) => k.isActive).toList();

        return TasksTab(
          tasksStream: firestore.getAllTasksStream(serviceId: serviceId),
          tasksQuery: () => firestore.getAllTasksStream(serviceId: serviceId),
          availableKhodam: activeKhodam,
          grade: 'all',
          canCreateTasks: true,
          serviceId: serviceId,
        );
      },
    );
  }
}

class _GradeMakhdomeenWrapper extends StatelessWidget {
  final String grade;

  const _GradeMakhdomeenWrapper({required this.grade});

  @override
  Widget build(BuildContext context) {
    final firestore = RouterServices.of(context).firestore;
    final session = RouterServices.of(context).session.state;
    final serviceId = session.profile?.serviceId ?? 'thanawy';

    return QueryContent<List<MakhdomModel>>(
      queryKey:
          '${session.scopeKey}/makhdomeenSnap',
      query: () => firestore.getMakhdomeenByGradeStream(grade, serviceId: serviceId),
      builder: (context, makhdomeenSnap) {
        return QueryContent<List<KhademModel>>(
          queryKey:
              '${session.scopeKey}/khodamSnap',
          query: () => firestore.getKhodamByGradeStream(grade, serviceId: serviceId),
          builder: (context, khodamSnap) {
            final allMakhdomeen = makhdomeenSnap;
            final khodamList = khodamSnap;

            return GradeMakhdomeenTab(
              grade: grade,
              allMakhdomeen: allMakhdomeen,
              khodamList: khodamList,
            );
          },
        );
      },
    );
  }
}

class _GradeAnalyticsWrapper extends StatelessWidget {
  final String grade;

  const _GradeAnalyticsWrapper({required this.grade});

  @override
  Widget build(BuildContext context) {
    final firestore = RouterServices.of(context).firestore;
    final session = RouterServices.of(context).session.state;
    final serviceId = session.profile?.serviceId ?? 'thanawy';

    return QueryContent<List<MakhdomModel>>(
      queryKey:
          '${session.scopeKey}/makhdomeenSnap',
      query: () => firestore.getMakhdomeenByGradeStream(grade, serviceId: serviceId),
      builder: (context, makhdomeenSnap) {
        return QueryContent<List<KhademModel>>(
          queryKey:
              '${session.scopeKey}/khodamSnap',
          query: () => firestore.getKhodamByGradeStream(grade, serviceId: serviceId),
          builder: (context, khodamSnap) {
            final allMakhdomeen = makhdomeenSnap;
            final khodamList = khodamSnap;

            return AnalyticsTab(
              firestoreService: firestore,
              makhdomeen: allMakhdomeen,
              khodam: khodamList,
              grade: grade,
              serviceId: serviceId,
            );
          },
        );
      },
    );
  }
}

class _GradeKhodamWrapper extends StatelessWidget {
  final String grade;

  const _GradeKhodamWrapper({required this.grade});

  @override
  Widget build(BuildContext context) {
    final firestore = RouterServices.of(context).firestore;
    final session = RouterServices.of(context).session.state;
    final serviceId = session.profile?.serviceId ?? 'thanawy';

    return QueryContent<List<MakhdomModel>>(
      queryKey:
          '${session.scopeKey}/makhdomeenSnap',
      query: () => firestore.getMakhdomeenByGradeStream(grade, serviceId: serviceId),
      builder: (context, makhdomeenSnap) {
        return QueryContent<List<KhademModel>>(
          queryKey:
              '${session.scopeKey}/khodamSnap',
          query: () => firestore.getKhodamByGradeStream(grade, serviceId: serviceId),
          builder: (context, khodamSnap) {
            final allMakhdomeen = makhdomeenSnap;
            final khodamList = khodamSnap;

            return KhodamTab(khodam: khodamList, allMakhdomeen: allMakhdomeen);
          },
        );
      },
    );
  }
}

class _GradeTasksWrapper extends StatelessWidget {
  final String grade;

  const _GradeTasksWrapper({required this.grade});

  @override
  Widget build(BuildContext context) {
    final firestore = RouterServices.of(context).firestore;
    final session = RouterServices.of(context).session.state;
    final serviceId = session.profile?.serviceId ?? 'thanawy';

    return QueryContent<List<KhademModel>>(
      queryKey:
          '${session.scopeKey}/khodamSnap',
      query: () => firestore.getKhodamByGradeStream(grade, serviceId: serviceId),
      builder: (context, khodamSnap) {
        final khodamList = khodamSnap;

        return TasksTab(
          tasksStream: firestore.getTasksForGradeStream(grade, serviceId: serviceId),
          tasksQuery: () => firestore.getTasksForGradeStream(grade, serviceId: serviceId),
          availableKhodam: khodamList,
          grade: grade,
          canCreateTasks: true,
          serviceId: serviceId,
        );
      },
    );
  }
}

class _MyMakhdomeenWrapper extends StatelessWidget {
  const _MyMakhdomeenWrapper();

  @override
  Widget build(BuildContext context) {
    final firestore = RouterServices.of(context).firestore;
    final state = RouterServices.of(context).session.state;
    final uid = state.userId ?? '', grade = state.grade;
    final serviceId = state.profile?.serviceId ?? 'thanawy';
    if (state.status != SessionStatus.active || grade == null) {
      return const SizedBox.shrink();
    }

    return QueryContent<List<MakhdomModel>>(
      queryKey:
          '${state.scopeKey}/makhdomeenSnap',
      query: () => firestore.getMakhdomeenForKhademStream(uid, serviceId: serviceId),
      builder: (context, makhdomeenSnap) {
        final makhdomeen = makhdomeenSnap;

        return QueryContent<List<AttendanceSessionModel>>(
          queryKey:
              '${state.scopeKey}/sessionsSnap',
          query: () => firestore.getAttendanceSessionsForGradeStream(
            grade,
            from: calendarDay(DateTime.now(), -89),
            to: DateTime.now(),
            serviceId: serviceId,
          ),
          builder: (context, sessionsSnap) {
            final sessions = sessionsSnap;
            if (kIsWeb) {
              return MyMakhdomeenWebScreen(
                myMakhdomeen: makhdomeen,
                sessions: sessions,
                onSwitchToAnalytics: () =>
                    context.go(AppRoutes.myAnalyticsPath),
              );
            }
            return MyMakhdomeenTab(
              myMakhdomeen: makhdomeen,
              sessions: sessions,
            );
          },
        );
      },
    );
  }
}

class _MyTasksWrapper extends StatelessWidget {
  const _MyTasksWrapper();

  @override
  Widget build(BuildContext context) {
    final firestore = RouterServices.of(context).firestore;
    final session = RouterServices.of(context).session.state;
    final uid = session.userId ?? '';
    final serviceId = session.profile?.serviceId ?? 'thanawy';

    if (kIsWeb) {
      return QueryContent<List<TaskModel>>(
        queryKey: '${session.scopeKey}/tasks',
        query: () => firestore.getTasksForKhademStream(uid, serviceId: serviceId),
        builder: (context, tasks) => MyTasksWebScreen(tasks: tasks),
      );
    }

    return TasksTab(
      tasksStream: firestore.getTasksForKhademStream(uid, serviceId: serviceId),
      tasksQuery: () => firestore.getTasksForKhademStream(uid, serviceId: serviceId),
      availableKhodam: const [],
      grade: 'all',
      canCreateTasks: false,
      serviceId: serviceId,
    );
  }
}

class _MyAnalyticsWrapper extends StatefulWidget {
  const _MyAnalyticsWrapper();
  @override
  State<_MyAnalyticsWrapper> createState() => _MyAnalyticsWrapperState();
}

class _MyAnalyticsWrapperState extends State<_MyAnalyticsWrapper> {
  int _revision = 0;
  @override
  Widget build(BuildContext context) {
    final services = RouterServices.of(context), firestore = services.firestore;
    final session = services.session.state;
    final uid = session.userId ?? '',
        grade = session.grade;
    final serviceId = session.profile?.serviceId ?? 'thanawy';
    if (session.status != SessionStatus.active ||
        grade == null) {
      return const SizedBox.shrink();
    }
    final now = DateTime.now(),
        asOf = DateTime(now.year, now.month, now.day),
        from = calendarDay(now, -89);
    return QueryContent<List<MakhdomModel>>(
      queryKey: session.scopeKey,
      query: () => firestore.getMakhdomeenForKhademStream(uid, serviceId: serviceId),
      builder: (context, children) {
        final ids = children.map((m) => m.id).toList()..sort();
        return QueryContent<List<VisitModel>>(
          queryKey:
              '${session.scopeKey}/${ids.join(',')}/$from/$_revision',
          query: () =>
              firestore.watchVisitsForChildrenWindow(ids, from: from, to: asOf),
          builder: (context, visits) =>
              QueryContent<List<AttendanceSessionModel>>(
                queryKey: '${session.scopeKey}/$grade/$from',
                query: () => firestore.getAttendanceSessionsForGradeStream(
                  grade,
                  from: from,
                  to: asOf,
                  serviceId: serviceId,
                ),
                builder: (context, sessions) {
                  if (kIsWeb) {
                    return MyAnalyticsWebScreen(
                      myMakhdomeen: children,
                      sessions: sessions,
                      visits: visits,
                      from: from,
                      asOf: asOf,
                      onVisitRecorded: () => setState(() => _revision++),
                    );
                  }
                  return Column(
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: IconButton(
                          tooltip: context.tr.retryAction,
                          onPressed: () => setState(() => _revision++),
                          icon: const Icon(Icons.refresh),
                        ),
                      ),
                      Expanded(
                        child: MyAnalyticsTab(
                          myMakhdomeen: children,
                          sessions: sessions,
                          visits: visits,
                          from: from,
                          asOf: asOf,
                          onVisitRecorded: () => setState(() => _revision++),
                        ),
                      ),
                    ],
                  );
                },
              ),
        );
      },
    );
  }
}

class _SessionExitScreen extends StatelessWidget {
  final SessionCubit sessionCubit;
  final bool deleting;
  const _SessionExitScreen({required this.sessionCubit, this.deleting = false});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          deleting
              ? (context.tr.messageAccountDeletionInProgress)
              : (context.tr.messageUnableToLoadProfile),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (deleting) const CircularProgressIndicator(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                deleting
                    ? (context.tr.messageYourDeletionRequestIsSavedYouCan)
                    : context.tr.dataUnavailable,
              ),
            ),
            OutlinedButton(
              onPressed: sessionCubit.retry,
              child: Text(context.tr.messageRetry),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await sessionCubit.signOut();
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tr.dataUnavailable)),
                    );
                  }
                }
              },
              child: Text(context.tr.signOut),
            ),
          ],
        ),
      ),
    );
  }
}

Future<T?> _loadAuthorized<T>(
  Future<T?> lookup,
  void Function(T) authorize,
  String target,
  SessionState session,
  NotificationIntentCoordinator? coordinator,
) async {
  try {
    final value = await lookup;
    if (value != null) authorize(value);
    coordinator?.completeVerified(target, session);
    return value;
  } catch (error) {
    final failure = AppFailure.fromException(error);
    if (failure.code == 'permission-denied' || failure.code == 'not-found') {
      coordinator?.completeVerified(target, session);
    }
    rethrow;
  }
}
