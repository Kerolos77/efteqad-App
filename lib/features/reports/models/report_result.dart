import '../../../core/models/makhdom_model.dart';
import 'report_type.dart';
import 'servant_performance_data.dart';

class ReportResult {
  final ReportType type;
  final String title;
  final String subtitle;
  final String dateRangeText;
  final String generatedBy;
  final DateTime generatedAt;
  final Map<String, String> summaryKpis;
  final List<String> headers;
  final List<List<String>> rows;
  final List<MakhdomModel>? makhdomeen;
  final ServantPerformanceData? servantPerformance;

  ReportResult({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.dateRangeText,
    required this.generatedBy,
    required this.generatedAt,
    required this.summaryKpis,
    required this.headers,
    required this.rows,
    this.makhdomeen,
    this.servantPerformance,
  });

  bool get isEmpty => rows.isEmpty && servantPerformance == null;
  int get rowCount => rows.length;
}
