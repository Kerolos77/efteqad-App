import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/constants.dart';
import '../../../core/models/attendance_session_model.dart';
import '../../../core/models/khadem_model.dart';
import '../../../core/models/makhdom_model.dart';
import '../../../core/models/visit_model.dart';
import '../../../core/session/session_state.dart';
import '../models/report_filter_data.dart';
import '../models/report_result.dart';
import '../models/report_type.dart';
import '../models/servant_performance_data.dart';

class ReportsDataService {
  final FirebaseFirestore _firestore;

  ReportsDataService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// بناء النتيجة الشاملة لأي تقرير مختار بناءً على الفلاتر وصلاحية الجلسة
  Future<ReportResult> generateReport({
    required ReportType type,
    required ReportFilterData filters,
    required SessionState session,
    List<KhademModel>? availableKhodam,
  }) async {
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd');
    final dateRangeStr =
        'من ${dateFormat.format(filters.dateRange.start)} إلى ${dateFormat.format(filters.dateRange.end)}';
    final generatedBy = session.profile?.name ?? 'المسؤول';

    // 1. جلب المخدومين المؤهلين حسب الدور والفلاتر
    final makhdomeen = await _fetchFilteredMakhdomeen(filters, session);

    // 2. التحقق من الصلاحيات الأمنية لإخوة الرب والحالات الخاصة
    if (type == ReportType.brethrenOfLord) {
      if (!session.isStageAdmin && !session.isGradeAdmin) {
        throw Exception('غير مصرح لك بالوصول لهذا التقرير السري');
      }
    }

    switch (type) {
      case ReportType.visitationLog:
        return _buildVisitationLogReport(
          filters,
          makhdomeen,
          dateRangeStr,
          generatedBy,
          now,
        );

      case ReportType.fieldVisitation:
        return _buildFieldVisitationReport(
          filters,
          makhdomeen,
          dateRangeStr,
          generatedBy,
          now,
        );

      case ReportType.servantsVisitationStats:
        return _buildServantsVisitationStatsReport(
          filters,
          makhdomeen,
          availableKhodam ?? [],
          dateRangeStr,
          generatedBy,
          now,
        );

      case ReportType.attendanceMatrix:
        return _buildAttendanceMatrixReport(
          filters,
          makhdomeen,
          session,
          dateRangeStr,
          generatedBy,
          now,
        );

      case ReportType.attendanceRate:
        return _buildAttendanceRateReport(
          filters,
          makhdomeen,
          session,
          dateRangeStr,
          generatedBy,
          now,
        );

      case ReportType.serviceVsQoddas:
        return _buildServiceVsQoddasReport(
          filters,
          makhdomeen,
          session,
          dateRangeStr,
          generatedBy,
          now,
        );

      case ReportType.repeatedAbsence:
        return _buildRepeatedAbsenceReport(
          filters,
          makhdomeen,
          session,
          dateRangeStr,
          generatedBy,
          now,
        );

      case ReportType.unvisitedMakhdomeen:
        return _buildUnvisitedMakhdomeenReport(
          filters,
          makhdomeen,
          dateRangeStr,
          generatedBy,
          now,
        );

      case ReportType.unassignedMakhdomeen:
        return _buildUnassignedMakhdomeenReport(
          filters,
          makhdomeen,
          dateRangeStr,
          generatedBy,
          now,
        );

      case ReportType.birthdays:
        return _buildBirthdaysReport(
          filters,
          makhdomeen,
          dateRangeStr,
          generatedBy,
          now,
        );

      case ReportType.servantMakhdomeen:
        return _buildServantMakhdomeenReport(
          filters,
          makhdomeen,
          availableKhodam ?? [],
          dateRangeStr,
          generatedBy,
          now,
        );

      case ReportType.servantPerformanceCard:
        return _buildServantPerformanceCardReport(
          filters,
          makhdomeen,
          availableKhodam ?? [],
          session,
          dateRangeStr,
          generatedBy,
          now,
        );

      case ReportType.brethrenOfLord:
        return _buildBrethrenOfLordReport(
          filters,
          makhdomeen,
          dateRangeStr,
          generatedBy,
          now,
        );
    }
  }

  // ==========================================
  // استعلامات وجلب البيانات الأساسية
  // ==========================================

  Future<List<MakhdomModel>> _fetchFilteredMakhdomeen(
    ReportFilterData filters,
    SessionState session,
  ) async {
    Query<Map<String, dynamic>> query = _firestore.collection(
      AppConstants.colMakhdomeen,
    );

    // تطبيق فلترة الخدمة
    final serviceId = filters.serviceId ?? session.serviceId;
    if (serviceId.isNotEmpty) {
      if (serviceId == 'thanawy') {
        // لتوافق البيانات القديمة إن وُجدت
      } else {
        query = query.where('serviceId', isEqualTo: serviceId);
      }
    }

    // فلترة الدور (Permissions Scope)
    if (session.isServant) {
      // الخادم يرى مخدوميه فقط
      query = query.where('assignedKhademId', isEqualTo: session.userId);
    } else if (session.isGradeAdmin) {
      // أمين السنة يرى سنته فقط
      final grade = session.grade;
      if (grade != null && grade.isNotEmpty) {
        query = query.where('grade', isEqualTo: grade);
      }
    } else if (session.isStageAdmin) {
      // أمين الخدمة يرى حسب فلتر الصف المختار
      if (filters.grade != null &&
          filters.grade != 'all' &&
          filters.grade!.isNotEmpty) {
        query = query.where('grade', isEqualTo: filters.grade);
      }
    }

    // فلترة الخادم إن وُجد وكان أميناً
    if (!session.isServant &&
        filters.khademId != null &&
        filters.khademId != 'all') {
      query = query.where('assignedKhademId', isEqualTo: filters.khademId);
    }

    // فلترة الفصل إن وُجد
    if (filters.classId != null && filters.classId != 'all') {
      query = query.where('classId', isEqualTo: filters.classId);
    }

    final snap = await query.get();
    var list =
        snap.docs
            .map((doc) => MakhdomModel.fromMap(doc.data(), doc.id))
            .where((m) {
              if (filters.activeOnly && !m.active) return false;
              return true;
            })
            .toList();

    list.sort((a, b) => a.fullName.compareTo(b.fullName));
    return list;
  }

  Future<List<VisitModel>> _fetchVisitsInPeriod(
    ReportFilterData filters,
    List<String> makhdomIds,
  ) async {
    if (makhdomIds.isEmpty) return [];

    // استعلام الزيارات للفترة
    Query<Map<String, dynamic>> query = _firestore
        .collection(AppConstants.colVisits)
        .where(
          'visitDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(filters.dateRange.start),
        )
        .where(
          'visitDate',
          isLessThanOrEqualTo: Timestamp.fromDate(filters.dateRange.end),
        );

    final snap = await query.get();
    final allVisits =
        snap.docs.map((doc) => VisitModel.fromMap(doc.data(), doc.id)).where((
          v,
        ) {
          if (!makhdomIds.contains(v.makhdomId)) return false;
          if (filters.activityType != 'all' &&
              filters.activityType.isNotEmpty &&
              v.visitType != filters.activityType) {
            return false;
          }
          return true;
        }).toList();

    allVisits.sort((a, b) => b.visitDate.compareTo(a.visitDate));
    return allVisits;
  }

  Future<List<AttendanceSessionModel>> _fetchAttendanceSessionsInPeriod(
    ReportFilterData filters,
    SessionState session,
  ) async {
    final startStr = DateFormat('yyyy-MM-dd').format(filters.dateRange.start);
    final endStr = DateFormat('yyyy-MM-dd').format(filters.dateRange.end);

    Query<Map<String, dynamic>> query = _firestore
        .collection(AppConstants.colAttendance)
        .where('date', isGreaterThanOrEqualTo: startStr)
        .where('date', isLessThanOrEqualTo: endStr);

    final snap = await query.get();
    var list =
        snap.docs
            .map((d) => AttendanceSessionModel.fromMap(d.data(), d.id))
            .where((s) {
              if (filters.activityType != 'all' &&
                  filters.activityType.isNotEmpty &&
                  s.type != filters.activityType) {
                return false;
              }
              if (session.isGradeAdmin) {
                if (s.grade != session.grade && s.grade != 'all') return false;
              } else if (filters.grade != null && filters.grade != 'all') {
                if (s.grade != filters.grade && s.grade != 'all') return false;
              }
              return true;
            })
            .toList();

    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  // ==========================================
  // بناء التقارير الفردية
  // ==========================================

  /// 1. سجل الافتقادات التفصيلي
  Future<ReportResult> _buildVisitationLogReport(
    ReportFilterData filters,
    List<MakhdomModel> makhdomeen,
    String dateRangeStr,
    String generatedBy,
    DateTime now,
  ) async {
    final makhdomMap = {for (var m in makhdomeen) m.id: m};
    final visits = await _fetchVisitsInPeriod(filters, makhdomMap.keys.toList());

    final rows = <List<String>>[];
    final df = DateFormat('yyyy/MM/dd');

    for (var i = 0; i < visits.length; i++) {
      final v = visits[i];
      final m = makhdomMap[v.makhdomId];
      rows.add([
        (i + 1).toString(),
        v.makhdomName.isNotEmpty ? v.makhdomName : (m?.fullName ?? 'غير معروف'),
        m?.phone ?? '',
        v.khademName,
        df.format(v.visitDate),
        v.visitType,
        (v.notes ?? '').trim(),
      ]);
    }

    return ReportResult(
      type: ReportType.visitationLog,
      title: 'سجل الافتقادات التفصيلي',
      subtitle: 'كشف بجميع الزيارات والمكالمات المسجلة مع الملاحظات',
      dateRangeText: dateRangeStr,
      generatedBy: generatedBy,
      generatedAt: now,
      summaryKpis: {
        'إجمالي الافتقادات': visits.length.toString(),
        'مخدومين تم افتقادهم':
            visits.map((e) => e.makhdomId).toSet().length.toString(),
        'زيارات منزلية':
            visits
                .where((e) => e.visitType.contains('زيارة'))
                .length
                .toString(),
        'مكالمات':
            visits
                .where((e) => e.visitType.contains('مكالمة'))
                .length
                .toString(),
      },
      headers: [
        'م',
        'اسم المخدوم',
        'الهاتف',
        'الخادم المسجل',
        'تاريخ الافتقاد',
        'النوع',
        'الملاحظات',
      ],
      rows: rows,
      makhdomeen: makhdomeen,
    );
  }

  /// 2. كشف الافتقاد الميداني (مع لوكيشن وملاحظات فارغة)
  Future<ReportResult> _buildFieldVisitationReport(
    ReportFilterData filters,
    List<MakhdomModel> makhdomeen,
    String dateRangeStr,
    String generatedBy,
    DateTime now,
  ) async {
    final rows = <List<String>>[];
    final df = DateFormat('yyyy/MM/dd');

    for (var i = 0; i < makhdomeen.length; i++) {
      final m = makhdomeen[i];
      final lastVisit =
          m.lastVisitDate != null ? df.format(m.lastVisitDate!) : 'لم يُفتقد';
      rows.add([
        (i + 1).toString(),
        m.fullName,
        m.phone,
        m.fatherPhone.isNotEmpty ? m.fatherPhone : m.motherPhone,
        m.address.isNotEmpty ? m.address : m.area,
        m.assignedKhademName ?? 'غير مسكن',
        lastVisit,
        m.notes ?? '',
      ]);
    }

    return ReportResult(
      type: ReportType.fieldVisitation,
      title: 'كشف الافتقاد الميداني والنزول',
      subtitle:
          'بيانات العناوين والتواصل مع أماكن فارغة لكتابة ملاحظات الافتقاد',
      dateRangeText: dateRangeStr,
      generatedBy: generatedBy,
      generatedAt: now,
      summaryKpis: {
        'إجمالي المخدومين': makhdomeen.length.toString(),
        'بعناوين مسجلة':
            makhdomeen.where((m) => m.address.isNotEmpty).length.toString(),
        'بلوكيشن خريطة':
            makhdomeen
                .where((m) => (m.homeLocationUrl ?? '').isNotEmpty)
                .length
                .toString(),
      },
      headers: [
        'م',
        'الاسم رباعي',
        'هاتف المخدوم',
        'هاتف ولي الأمر',
        'العنوان بالتفصيل',
        'الخادم المسؤول',
        'آخر افتقاد',
        'ملاحظات سابقة',
      ],
      rows: rows,
      makhdomeen: makhdomeen,
    );
  }

  /// 3. إحصائيات إنجاز وافتقاد الخدام
  Future<ReportResult> _buildServantsVisitationStatsReport(
    ReportFilterData filters,
    List<MakhdomModel> makhdomeen,
    List<KhademModel> khodam,
    String dateRangeStr,
    String generatedBy,
    DateTime now,
  ) async {
    final makhdomIds = makhdomeen.map((m) => m.id).toList();
    final visits = await _fetchVisitsInPeriod(filters, makhdomIds);

    final khademVisitsMap = <String, List<VisitModel>>{};
    for (var v in visits) {
      khademVisitsMap.putIfAbsent(v.khademId, () => []).add(v);
    }

    final rows = <List<String>>[];
    var rank = 1;

    for (var k in khodam) {
      final myVisits = khademVisitsMap[k.id] ?? [];
      final myMakhdomeen =
          makhdomeen.where((m) => m.assignedKhademId == k.id).toList();
      final homeVisits =
          myVisits.where((v) => v.visitType.contains('زيارة')).length;
      final calls =
          myVisits.where((v) => v.visitType.contains('مكالمة')).length;
      final uniqueVisitedCount =
          myVisits.map((v) => v.makhdomId).toSet().length;

      final coverage =
          myMakhdomeen.isNotEmpty
              ? ((uniqueVisitedCount / myMakhdomeen.length) * 100).toStringAsFixed(
                1,
              )
              : '0.0';

      rows.add([
        (rank++).toString(),
        k.name,
        myMakhdomeen.length.toString(),
        homeVisits.toString(),
        calls.toString(),
        myVisits.length.toString(),
        uniqueVisitedCount.toString(),
        '$coverage%',
      ]);
    }

    return ReportResult(
      type: ReportType.servantsVisitationStats,
      title: 'إحصائيات إنجاز وافتقاد الخدام',
      subtitle: 'تحليل مقارن لنشاط الخدام ونسب التغطية الرعوية للمخدومين',
      dateRangeText: dateRangeStr,
      generatedBy: generatedBy,
      generatedAt: now,
      summaryKpis: {
        'إجمالي الخدام': khodam.length.toString(),
        'إجمالي الافتقادات': visits.length.toString(),
        'معدل الزيارات للخدمة':
            khodam.isNotEmpty
                ? (visits.length / khodam.length).toStringAsFixed(1)
                : '0',
      },
      headers: [
        'م',
        'اسم الخادم',
        'عدد أولاده',
        'زيارات منزلية',
        'مكالمات',
        'إجمالي الافتقاد',
        'مخدومين تم الوصول لهم',
        'نسبة التغطية',
      ],
      rows: rows,
    );
  }

  /// 4. مصفوفة الحضور والغياب (التواريخ والمخدومين)
  Future<ReportResult> _buildAttendanceMatrixReport(
    ReportFilterData filters,
    List<MakhdomModel> makhdomeen,
    SessionState session,
    String dateRangeStr,
    String generatedBy,
    DateTime now,
  ) async {
    final sessions = await _fetchAttendanceSessionsInPeriod(filters, session);
    final headers = ['م', 'اسم المخدوم', 'الفصل'];

    for (var s in sessions) {
      headers.add(
        '${s.date.substring(5)}\n(${s.type == 'qoddas' ? 'قداس' : 'خدمة'})',
      );
    }
    headers.add('حضور');
    headers.add('النسبة');

    final rows = <List<String>>[];

    for (var i = 0; i < makhdomeen.length; i++) {
      final m = makhdomeen[i];
      final row = <String>[(i + 1).toString(), m.fullName, m.className ?? '-'];

      var attended = 0;
      for (var s in sessions) {
        if (s.attendedMakhdomIds.contains(m.id)) {
          attended++;
          row.add('حاضر');
        } else if (s.excuses.containsKey(m.id)) {
          row.add('عذر');
        } else {
          row.add('غائب');
        }
      }

      final rate =
          sessions.isNotEmpty
              ? ((attended / sessions.length) * 100).toStringAsFixed(0)
              : '0';

      row.add('$attended / ${sessions.length}');
      row.add('$rate%');
      rows.add(row);
    }

    return ReportResult(
      type: ReportType.attendanceMatrix,
      title: 'مصفوفة الحضور والغياب التاريخية',
      subtitle: 'سجل حضور وغياب وأعذار المخدومين في جميع الجلسات',
      dateRangeText: dateRangeStr,
      generatedBy: generatedBy,
      generatedAt: now,
      summaryKpis: {
        'عدد الجلسات': sessions.length.toString(),
        'إجمالي المخدومين': makhdomeen.length.toString(),
      },
      headers: headers,
      rows: rows,
      makhdomeen: makhdomeen,
    );
  }

  /// 5. تقرير نسب المواظبة والالتزام
  Future<ReportResult> _buildAttendanceRateReport(
    ReportFilterData filters,
    List<MakhdomModel> makhdomeen,
    SessionState session,
    String dateRangeStr,
    String generatedBy,
    DateTime now,
  ) async {
    final sessions = await _fetchAttendanceSessionsInPeriod(filters, session);

    final stats = <_MakhdomAttendanceStat>[];
    for (var m in makhdomeen) {
      var count = 0;
      for (var s in sessions) {
        if (s.attendedMakhdomIds.contains(m.id)) count++;
      }
      final rate =
          sessions.isNotEmpty ? (count / sessions.length) * 100 : 0.0;
      stats.add(
        _MakhdomAttendanceStat(
          makhdom: m,
          attendedCount: count,
          totalSessions: sessions.length,
          rate: rate,
        ),
      );
    }

    // فرز تنازلي حسب نسبة الحضور
    stats.sort((a, b) => b.rate.compareTo(a.rate));

    final rows = <List<String>>[];
    for (var i = 0; i < stats.length; i++) {
      final s = stats[i];
      rows.add([
        (i + 1).toString(),
        s.makhdom.fullName,
        s.makhdom.phone,
        s.makhdom.assignedKhademName ?? 'غير مسكن',
        '${s.attendedCount} من ${s.totalSessions}',
        '${s.rate.toStringAsFixed(1)}%',
        _getCommitmentBadge(s.rate),
      ]);
    }

    final avgRate =
        stats.isNotEmpty
            ? stats.map((e) => e.rate).reduce((a, b) => a + b) / stats.length
            : 0.0;

    return ReportResult(
      type: ReportType.attendanceRate,
      title: 'تقرير نسب المواظبة والالتزام',
      subtitle: 'ترتيب المخدومين تنازلياً حسب مستوى الحضور والمواظبة',
      dateRangeText: dateRangeStr,
      generatedBy: generatedBy,
      generatedAt: now,
      summaryKpis: {
        'متوسط الحضور العام': '${avgRate.toStringAsFixed(1)}%',
        'مواظب ممتاز (>75%)':
            stats.where((e) => e.rate >= 75).length.toString(),
        'متوسط (50-75%)':
            stats.where((e) => e.rate >= 50 && e.rate < 75).length.toString(),
        'متقطع / متعثر (<50%)':
            stats.where((e) => e.rate < 50).length.toString(),
      },
      headers: [
        'م',
        'اسم المخدوم',
        'الهاتف',
        'الخادم المسؤول',
        'مرات الحضور',
        'نسبة الحضور',
        'التقييم',
      ],
      rows: rows,
      makhdomeen: stats.map((e) => e.makhdom).toList(),
    );
  }

  /// 6. مقارنة حضور الخدمة بالقداس
  Future<ReportResult> _buildServiceVsQoddasReport(
    ReportFilterData filters,
    List<MakhdomModel> makhdomeen,
    SessionState session,
    String dateRangeStr,
    String generatedBy,
    DateTime now,
  ) async {
    final sessions = await _fetchAttendanceSessionsInPeriod(filters, session);
    final khedmaSessions = sessions.where((s) => s.type == 'khedma').toList();
    final qoddasSessions = sessions.where((s) => s.type == 'qoddas').toList();

    final rows = <List<String>>[];

    for (var i = 0; i < makhdomeen.length; i++) {
      final m = makhdomeen[i];
      var khedmaCount = 0;
      for (var s in khedmaSessions) {
        if (s.attendedMakhdomIds.contains(m.id)) khedmaCount++;
      }
      var qoddasCount = 0;
      for (var s in qoddasSessions) {
        if (s.attendedMakhdomIds.contains(m.id)) qoddasCount++;
      }

      final khedmaRate =
          khedmaSessions.isNotEmpty
              ? ((khedmaCount / khedmaSessions.length) * 100).toStringAsFixed(0)
              : '0';
      final qoddasRate =
          qoddasSessions.isNotEmpty
              ? ((qoddasCount / qoddasSessions.length) * 100).toStringAsFixed(0)
              : '0';

      rows.add([
        (i + 1).toString(),
        m.fullName,
        m.assignedKhademName ?? '-',
        '$khedmaCount / ${khedmaSessions.length} ($khedmaRate%)',
        '$qoddasCount / ${qoddasSessions.length} ($qoddasRate%)',
        (int.parse(qoddasRate) >= int.parse(khedmaRate))
            ? 'متوازن / ملتزم بالقداس'
            : 'يحتاج تشجيع للقداس',
      ]);
    }

    return ReportResult(
      type: ReportType.serviceVsQoddas,
      title: 'مقارنة حضور الخدمة بالقداس الإلهي',
      subtitle: 'تحليل توازن المخدوم بين اجتماع الخدمة والقداس',
      dateRangeText: dateRangeStr,
      generatedBy: generatedBy,
      generatedAt: now,
      summaryKpis: {
        'جلسات الخدمة': khedmaSessions.length.toString(),
        'جلسات القداس': qoddasSessions.length.toString(),
      },
      headers: [
        'م',
        'اسم المخدوم',
        'الخادم المسؤول',
        'حضور الخدمة',
        'حضور القداس',
        'التوجيه الرعوي',
      ],
      rows: rows,
      makhdomeen: makhdomeen,
    );
  }

  /// 7. تقرير الغياب المتكرر والانقطاع
  Future<ReportResult> _buildRepeatedAbsenceReport(
    ReportFilterData filters,
    List<MakhdomModel> makhdomeen,
    SessionState session,
    String dateRangeStr,
    String generatedBy,
    DateTime now,
  ) async {
    final sessions = await _fetchAttendanceSessionsInPeriod(filters, session);
    final threshold = filters.consecutiveAbsenceWeeks;

    final atRiskList = <_ConsecutiveAbsenceInfo>[];

    for (var m in makhdomeen) {
      var consecutiveAbsences = 0;
      // نعد من آخر جلسة تراجعياً
      for (var s in sessions.reversed) {
        if (!s.attendedMakhdomIds.contains(m.id)) {
          consecutiveAbsences++;
        } else {
          break;
        }
      }

      if (consecutiveAbsences >= threshold) {
        atRiskList.add(
          _ConsecutiveAbsenceInfo(
            makhdom: m,
            consecutiveWeeks: consecutiveAbsences,
          ),
        );
      }
    }

    atRiskList.sort((a, b) => b.consecutiveWeeks.compareTo(a.consecutiveWeeks));

    final rows = <List<String>>[];
    final df = DateFormat('yyyy/MM/dd');

    for (var i = 0; i < atRiskList.length; i++) {
      final item = atRiskList[i];
      final m = item.makhdom;
      final lastVisit =
          m.lastVisitDate != null ? df.format(m.lastVisitDate!) : 'لم يُفتقد';

      rows.add([
        (i + 1).toString(),
        m.fullName,
        m.phone,
        m.assignedKhademName ?? 'غير مسكن',
        '${item.consecutiveWeeks} أسابيع متتالية',
        lastVisit,
        item.consecutiveWeeks >= 4 ? 'خطر انقطاع تام' : 'انقطاع يستوجب الزيارة',
      ]);
    }

    return ReportResult(
      type: ReportType.repeatedAbsence,
      title: 'تقرير الغياب المتكرر والانقطاع (الإنذار المبكر)',
      subtitle:
          'المخدومين المنقطعين لـ $threshold أسابيع متتالية أو أكثر دون حضور',
      dateRangeText: dateRangeStr,
      generatedBy: generatedBy,
      generatedAt: now,
      summaryKpis: {
        'المنقطعين': atRiskList.length.toString(),
        'معيار الفلترة': '$threshold أسابيع متتالية',
        'انقطاع حرج (4+ أسابيع)':
            atRiskList.where((e) => e.consecutiveWeeks >= 4).length.toString(),
      },
      headers: [
        'م',
        'اسم المخدوم',
        'الهاتف',
        'الخادم المسؤول',
        'مدة الانقطاع',
        'آخر افتقاد',
        'مستوى الخطورة',
      ],
      rows: rows,
      makhdomeen: atRiskList.map((e) => e.makhdom).toList(),
    );
  }

  /// 8. مخدومين بلا افتقاد منذ فترة
  Future<ReportResult> _buildUnvisitedMakhdomeenReport(
    ReportFilterData filters,
    List<MakhdomModel> makhdomeen,
    String dateRangeStr,
    String generatedBy,
    DateTime now,
  ) async {
    final thresholdDays = filters.unvisitedDaysThreshold;
    final unvisited = <MakhdomModel>[];
    final df = DateFormat('yyyy/MM/dd');

    for (var m in makhdomeen) {
      if (m.lastVisitDate == null) {
        unvisited.add(m);
      } else {
        final days = now.difference(m.lastVisitDate!).inDays;
        if (days >= thresholdDays) {
          unvisited.add(m);
        }
      }
    }

    final rows = <List<String>>[];
    for (var i = 0; i < unvisited.length; i++) {
      final m = unvisited[i];
      final daysStr =
          m.lastVisitDate == null
              ? 'لم يسبق افتقاده'
              : 'منذ ${now.difference(m.lastVisitDate!).inDays} يوم (${df.format(m.lastVisitDate!)})';

      rows.add([
        (i + 1).toString(),
        m.fullName,
        m.phone,
        m.assignedKhademName ?? 'غير مسكن',
        m.address.isNotEmpty ? m.address : m.area,
        daysStr,
      ]);
    }

    return ReportResult(
      type: ReportType.unvisitedMakhdomeen,
      title: 'تقرير المخدومين بدون افتقاد',
      subtitle: 'المخدومين الذين مر عليهم $thresholdDays يوماً دون أي افتقاد',
      dateRangeText: dateRangeStr,
      generatedBy: generatedBy,
      generatedAt: now,
      summaryKpis: {
        'المهملين رعوياً': unvisited.length.toString(),
        'لم يسبق افتقادهم أبداً':
            unvisited.where((m) => m.lastVisitDate == null).length.toString(),
      },
      headers: [
        'م',
        'اسم المخدوم',
        'الهاتف',
        'الخادم المسؤول',
        'العنوان',
        'تاريخ ومدة آخر افتقاد',
      ],
      rows: rows,
      makhdomeen: unvisited,
    );
  }

  /// 9. مخدومين غير مسكنين على خادم
  Future<ReportResult> _buildUnassignedMakhdomeenReport(
    ReportFilterData filters,
    List<MakhdomModel> makhdomeen,
    String dateRangeStr,
    String generatedBy,
    DateTime now,
  ) async {
    final unassigned =
        makhdomeen
            .where(
              (m) =>
                  m.assignedKhademId == null ||
                  m.assignedKhademId!.isEmpty ||
                  m.assignedKhademId == 'unassigned',
            )
            .toList();

    final rows = <List<String>>[];
    for (var i = 0; i < unassigned.length; i++) {
      final m = unassigned[i];
      rows.add([
        (i + 1).toString(),
        m.fullName,
        m.phone,
        m.fatherPhone.isNotEmpty ? m.fatherPhone : m.motherPhone,
        m.grade,
        m.className ?? 'بدون فصل',
        m.address.isNotEmpty ? m.address : m.area,
      ]);
    }

    return ReportResult(
      type: ReportType.unassignedMakhdomeen,
      title: 'كشف المخدومين غير المسكنين',
      subtitle: 'مخدومين ليس لهم خادم مسؤول لتوزيعهم رعوياً',
      dateRangeText: dateRangeStr,
      generatedBy: generatedBy,
      generatedAt: now,
      summaryKpis: {'إجمالي غير المسكنين': unassigned.length.toString()},
      headers: [
        'م',
        'اسم المخدوم',
        'الهاتف',
        'هاتف ولي الأمر',
        'الصف',
        'الفصل',
        'العنوان',
      ],
      rows: rows,
      makhdomeen: unassigned,
    );
  }

  /// 10. كشف أعياد الميلاد
  Future<ReportResult> _buildBirthdaysReport(
    ReportFilterData filters,
    List<MakhdomModel> makhdomeen,
    String dateRangeStr,
    String generatedBy,
    DateTime now,
  ) async {
    final targetMonth = filters.dateRange.start.month;
    final bdays =
        makhdomeen.where((m) {
          if (m.birthDate == null) return false;
          return m.birthDate!.month == targetMonth;
        }).toList();

    bdays.sort((a, b) => (a.birthDate!.day).compareTo(b.birthDate!.day));

    final rows = <List<String>>[];
    for (var i = 0; i < bdays.length; i++) {
      final m = bdays[i];
      final age = now.year - m.birthDate!.year;
      rows.add([
        (i + 1).toString(),
        m.fullName,
        m.phone,
        m.assignedKhademName ?? '-',
        '${m.birthDate!.day} / ${m.birthDate!.month}',
        '$age سنة',
      ]);
    }

    return ReportResult(
      type: ReportType.birthdays,
      title: 'كشف أعياد ميلاد شهر $targetMonth',
      subtitle: 'مرتبة بالأيام مع أرقام الهواتف لتجهيز التهنئة والهدايا',
      dateRangeText: dateRangeStr,
      generatedBy: generatedBy,
      generatedAt: now,
      summaryKpis: {
        'أعياد ميلاد هذا الشهر': bdays.length.toString(),
        'شهر الاستخراج': targetMonth.toString(),
      },
      headers: [
        'م',
        'اسم المخدوم',
        'الهاتف',
        'الخادم المسؤول',
        'تاريخ الميلاد (يوم/شهر)',
        'العمر',
      ],
      rows: rows,
      makhdomeen: bdays,
    );
  }

  /// 11. كشف مخدومي خادم محدد
  Future<ReportResult> _buildServantMakhdomeenReport(
    ReportFilterData filters,
    List<MakhdomModel> makhdomeen,
    List<KhademModel> khodam,
    String dateRangeStr,
    String generatedBy,
    DateTime now,
  ) async {
    final targetKhadem = khodam.firstWhere(
      (k) => k.id == filters.khademId,
      orElse:
          () => KhademModel(
            id: '',
            email: '',
            name: 'الخادم المحدد',
            createdAt: now,
          ),
    );

    final boys =
        makhdomeen
            .where((m) => m.assignedKhademId == filters.khademId)
            .toList();

    final rows = <List<String>>[];
    final df = DateFormat('yyyy/MM/dd');

    for (var i = 0; i < boys.length; i++) {
      final m = boys[i];
      final lastVisit =
          m.lastVisitDate != null ? df.format(m.lastVisitDate!) : 'لم يُفتقد';
      rows.add([
        (i + 1).toString(),
        m.fullName,
        m.phone,
        m.fatherPhone.isNotEmpty ? m.fatherPhone : m.motherPhone,
        m.address.isNotEmpty ? m.address : m.area,
        m.className ?? '-',
        lastVisit,
      ]);
    }

    return ReportResult(
      type: ReportType.servantMakhdomeen,
      title: 'كشف مخدومي الخادم: ${targetKhadem.name}',
      subtitle: 'قائمة بيانات التواصل لجميع الأولاد المربوطين بهذا الخادم',
      dateRangeText: dateRangeStr,
      generatedBy: generatedBy,
      generatedAt: now,
      summaryKpis: {
        'اسم الخادم': targetKhadem.name,
        'عدد المخدومين': boys.length.toString(),
        'هاتف الخادم': targetKhadem.phone,
      },
      headers: [
        'م',
        'الاسم رباعي',
        'هاتف المخدوم',
        'هاتف ولي الأمر',
        'العنوان',
        'الفصل',
        'آخر افتقاد',
      ],
      rows: rows,
      makhdomeen: boys,
    );
  }

  /// 12. بطاقة أداء الخادم (مخصصة للأمناء فقط)
  Future<ReportResult> _buildServantPerformanceCardReport(
    ReportFilterData filters,
    List<MakhdomModel> makhdomeen,
    List<KhademModel> khodam,
    SessionState session,
    String dateRangeStr,
    String generatedBy,
    DateTime now,
  ) async {
    final targetKhadem = khodam.firstWhere(
      (k) => k.id == filters.khademId,
      orElse:
          () => KhademModel(
            id: '',
            email: '',
            name: 'الخادم المحدد',
            createdAt: now,
          ),
    );

    final boys =
        makhdomeen
            .where((m) => m.assignedKhademId == filters.khademId)
            .toList();
    final boyIds = boys.map((b) => b.id).toList();

    final visits = await _fetchVisitsInPeriod(filters, boyIds);
    final sessions = await _fetchAttendanceSessionsInPeriod(filters, session);

    final homeVisits =
        visits.where((v) => v.visitType.contains('زيارة')).length;
    final phoneCalls =
        visits.where((v) => v.visitType.contains('مكالمة')).length;
    final churchMeetings =
        visits.where((v) => v.visitType.contains('لقاء')).length;

    final coveredCount = visits.map((v) => v.makhdomId).toSet().length;
    final coverageRate =
        boys.isNotEmpty ? (coveredCount / boys.length) * 100 : 0.0;

    // حساب نسبة حضور أولاده
    var totalAttended = 0;
    var totalPossible = boys.length * sessions.length;
    for (var b in boys) {
      for (var s in sessions) {
        if (s.attendedMakhdomIds.contains(b.id)) totalAttended++;
      }
    }
    final avgAttendance =
        totalPossible > 0 ? (totalAttended / totalPossible) * 100 : 0.0;

    // تحديد المخدومين في دائرة الخطر
    final atRisk = <MakhdomModel>[];
    for (var b in boys) {
      // انقطاع افتقاد أكثر من 30 يوم
      final unvisitedDays =
          b.lastVisitDate == null ? 999 : now.difference(b.lastVisitDate!).inDays;
      if (unvisitedDays >= 30) {
        atRisk.add(b);
      }
    }

    final performance = ServantPerformanceData(
      khadem: targetKhadem,
      assignedMakhdomeenCount: boys.length,
      totalSessions: sessions.length,
      averageAttendanceRate: avgAttendance,
      homeVisitsCount: homeVisits,
      phoneCallsCount: phoneCalls,
      churchMeetingsCount: churchMeetings,
      totalVisits: visits.length,
      coveredMakhdomeenCount: coveredCount,
      coverageRate: coverageRate,
      atRiskMakhdomeen: atRisk,
    );

    final rows = <List<String>>[];
    for (var i = 0; i < boys.length; i++) {
      final b = boys[i];
      final boyVisits = visits.where((v) => v.makhdomId == b.id).length;
      var boyAttendances = 0;
      for (var s in sessions) {
        if (s.attendedMakhdomIds.contains(b.id)) boyAttendances++;
      }
      final rate =
          sessions.isNotEmpty
              ? ((boyAttendances / sessions.length) * 100).toStringAsFixed(0)
              : '0';

      rows.add([
        (i + 1).toString(),
        b.fullName,
        b.phone,
        '$boyAttendances / ${sessions.length} ($rate%)',
        boyVisits.toString(),
        (b.lastVisitDate != null)
            ? DateFormat('yyyy/MM/dd').format(b.lastVisitDate!)
            : 'لم يسبق',
        (boyVisits == 0 || int.parse(rate) < 50)
            ? 'يحتاج متابعة'
            : 'مستقر',
      ]);
    }

    return ReportResult(
      type: ReportType.servantPerformanceCard,
      title: 'بطاقة أداء ومتابعة الخادم: ${targetKhadem.name}',
      subtitle: 'ملخص إنجاز شامل لنشاط الافتقاد ونسب حضور الأولاد',
      dateRangeText: dateRangeStr,
      generatedBy: generatedBy,
      generatedAt: now,
      summaryKpis: {
        'إجمالي مخدوميه': boys.length.toString(),
        'نسبة حضور أولاده': '${avgAttendance.toStringAsFixed(1)}%',
        'إجمالي افتقاداته': visits.length.toString(),
        'نسبة التغطية الرعوية': '${coverageRate.toStringAsFixed(1)}%',
      },
      headers: [
        'م',
        'اسم المخدوم',
        'الهاتف',
        'نسبة الحضور',
        'مرات الافتقاد بالفترة',
        'آخر افتقاد',
        'الحالة',
      ],
      rows: rows,
      makhdomeen: boys,
      servantPerformance: performance,
    );
  }

  /// 13. تقرير إخوة الرب والحالات الخاصة (سري للأمناء)
  Future<ReportResult> _buildBrethrenOfLordReport(
    ReportFilterData filters,
    List<MakhdomModel> makhdomeen,
    String dateRangeStr,
    String generatedBy,
    DateTime now,
  ) async {
    final specialBoys = makhdomeen.where((m) => m.isBrethrenOfLord).toList();

    final rows = <List<String>>[];
    for (var i = 0; i < specialBoys.length; i++) {
      final m = specialBoys[i];
      rows.add([
        (i + 1).toString(),
        m.fullName,
        m.phone,
        m.fatherPhone.isNotEmpty ? m.fatherPhone : m.motherPhone,
        m.address.isNotEmpty ? m.address : m.area,
        m.assignedKhademName ?? 'غير مسكن',
        m.notes ?? 'لا توجد ملاحظات',
      ]);
    }

    return ReportResult(
      type: ReportType.brethrenOfLord,
      title: 'تقرير إخوة الرب والحالات الخاصة (سري للغاية)',
      subtitle:
          'كشف الحالات المستحقة للمتابعة والدعم الخاص (للأمناء فقط)',
      dateRangeText: dateRangeStr,
      generatedBy: generatedBy,
      generatedAt: now,
      summaryKpis: {
        'إجمالي الحالات': specialBoys.length.toString(),
        'السرية': 'محجوب عن الخدام',
      },
      headers: [
        'م',
        'اسم المخدوم',
        'الهاتف',
        'هاتف ولي الأمر',
        'العنوان بالتفصيل',
        'الخادم المسؤول',
        'ملاحظات وظروف خاصة',
      ],
      rows: rows,
      makhdomeen: specialBoys,
    );
  }

  String _getCommitmentBadge(double rate) {
    if (rate >= 80) return 'ممتاز ومواظب';
    if (rate >= 60) return 'جيد جداً';
    if (rate >= 40) return 'متوسط';
    return 'يحتاج افتقاد عاجل';
  }
}

class _MakhdomAttendanceStat {
  final MakhdomModel makhdom;
  final int attendedCount;
  final int totalSessions;
  final double rate;

  _MakhdomAttendanceStat({
    required this.makhdom,
    required this.attendedCount,
    required this.totalSessions,
    required this.rate,
  });
}

class _ConsecutiveAbsenceInfo {
  final MakhdomModel makhdom;
  final int consecutiveWeeks;

  _ConsecutiveAbsenceInfo({
    required this.makhdom,
    required this.consecutiveWeeks,
  });
}
