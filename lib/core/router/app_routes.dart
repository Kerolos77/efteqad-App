import '../session/session_state.dart';

class AppRoutes {
  AppRoutes._();

  static const String bootstrapPath = '/bootstrap';
  static const String bootstrapName = 'bootstrap';

  static const String loginPath = '/login';
  static const String loginName = 'login';

  static const String pendingPath = '/pending';
  static const String pendingName = 'pending';

  static const deletingPath = '/deleting';
  static const sessionFailurePath = '/session-error';
  static String landing(SessionState session) => session.isStageAdmin
      ? stagePeoplePath
      : session.isGradeAdmin
      ? gradeMakhdomeen(session.grade!)
      : myMakhdomeenPath;

  // Stage Shell Routes
  static const String stagePeoplePath = '/stage/people';
  static const String stagePeopleName = 'stagePeople';

  static const String stageAnalyticsPath = '/stage/analytics';
  static const String stageAnalyticsName = 'stageAnalytics';

  static const String stageTasksPath = '/stage/tasks';
  static const String stageTasksName = 'stageTasks';

  static const String stageAttendancePath = '/stage/attendance';
  static const String stageAttendanceName = 'stageAttendance';

  // Grade Shell Routes
  static const String gradeMakhdomeenPattern = '/grades/:grade/makhdomeen';
  static const String gradeMakhdomeenName = 'gradeMakhdomeen';

  static const String gradeAnalyticsPattern = '/grades/:grade/analytics';
  static const String gradeAnalyticsName = 'gradeAnalytics';

  static const String gradeKhodamPattern = '/grades/:grade/khodam';
  static const String gradeKhodamName = 'gradeKhodam';

  static const String gradeTasksPattern = '/grades/:grade/tasks';
  static const String gradeTasksName = 'gradeTasks';

  static const String gradeAttendancePattern = '/grades/:grade/attendance';
  static const String gradeAttendanceName = 'gradeAttendance';

  // Servant (Me) Shell Routes
  static const String myMakhdomeenPath = '/me/makhdomeen';
  static const String myMakhdomeenName = 'myMakhdomeen';

  static const String myTasksPath = '/me/tasks';
  static const String myTasksName = 'myTasks';

  static const String myAnalyticsPath = '/me/analytics';
  static const String myAnalyticsName = 'myAnalytics';

  static const String myAttendancePath = '/me/attendance';
  static const String myAttendanceName = 'myAttendance';

  // Root Stack / Detail Routes
  static const String makhdomHistoryPattern = '/makhdomeen/:makhdomId/history';
  static const String makhdomHistoryName = 'makhdomHistory';

  static const String taskDetailsPattern = '/tasks/:taskId';
  static const String taskDetailsName = 'taskDetails';

  static const String taskAttendancePattern = '/tasks/:taskId/attendance';
  static const String taskAttendanceName = 'taskAttendance';

  static const String profilePath = '/profile';
  static const String profileName = 'profile';

  static const String settingsPath = '/settings';
  static const String settingsName = 'settings';

  static const String reportsPath = '/reports';
  static const String reportsName = 'reports';

  static const String notificationsPath = '/notifications';
  static const String notificationsName = 'notifications';

  static const String forbiddenPath = '/forbidden';
  static const String forbiddenName = 'forbidden';

  static const String notFoundPath = '/not-found';
  static const String notFoundName = 'notFound';

  // Helper builders
  static String gradeMakhdomeen(String grade) => '/grades/$grade/makhdomeen';
  static String gradeAnalytics(String grade) => '/grades/$grade/analytics';
  static String gradeKhodam(String grade) => '/grades/$grade/khodam';
  static String gradeTasks(String grade) => '/grades/$grade/tasks';
  static String gradeAttendance(String grade) => '/grades/$grade/attendance';

  static String attendanceHubFor(SessionState session) => session.isStageAdmin
      ? stageAttendancePath
      : session.isGradeAdmin
      ? gradeAttendance(session.grade!)
      : myAttendancePath;

  static String makhdomHistory(String makhdomId) =>
      '/makhdomeen/$makhdomId/history';
  static String taskDetails(String taskId) => '/tasks/$taskId';
  static String taskAttendance(String taskId) => '/tasks/$taskId/attendance';
}
