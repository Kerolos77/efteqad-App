import '../../../core/models/khadem_model.dart';
import '../../../core/models/makhdom_model.dart';

class ServantPerformanceData {
  final KhademModel khadem;
  final int assignedMakhdomeenCount;
  final int totalSessions;
  final double averageAttendanceRate;
  final int homeVisitsCount;
  final int phoneCallsCount;
  final int churchMeetingsCount;
  final int totalVisits;
  final int coveredMakhdomeenCount;
  final double coverageRate;
  final List<MakhdomModel> atRiskMakhdomeen;
  final List<MakhdomModel> unvisitedMakhdomeen;

  const ServantPerformanceData({
    required this.khadem,
    required this.assignedMakhdomeenCount,
    required this.totalSessions,
    required this.averageAttendanceRate,
    required this.homeVisitsCount,
    required this.phoneCallsCount,
    required this.churchMeetingsCount,
    required this.totalVisits,
    required this.coveredMakhdomeenCount,
    required this.coverageRate,
    this.atRiskMakhdomeen = const [],
    this.unvisitedMakhdomeen = const [],
  });
}
