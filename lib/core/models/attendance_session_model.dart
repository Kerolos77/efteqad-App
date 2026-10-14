import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceExcuse {
  final String note;
  final String byKhademId;
  final String byKhademName;
  final DateTime updatedAt;

  const AttendanceExcuse({
    required this.note,
    required this.byKhademId,
    required this.byKhademName,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'note': note,
    'byKhademId': byKhademId,
    'byKhademName': byKhademName,
    'updatedAtMs': updatedAt.millisecondsSinceEpoch,
  };

  factory AttendanceExcuse.fromMap(Map<String, dynamic> map) {
    DateTime parseUpdatedAt(dynamic val) {
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return AttendanceExcuse(
      note: (map['note'] ?? '').toString().trim(),
      byKhademId: (map['byKhademId'] ?? '').toString(),
      byKhademName: (map['byKhademName'] ?? '').toString(),
      updatedAt: parseUpdatedAt(map['updatedAtMs'] ?? map['updatedAt']),
    );
  }
}

class AttendanceSessionModel {
  final String
  id; // Format: ${date}_${type}_${grade} e.g. 2026-10-09_khedma_1st
  final String date; // YYYY-MM-DD
  final String type; // 'khedma' or 'qoddas'
  final String grade; // '1st', '2nd', '3rd', or 'all'
  final List<String> attendedMakhdomIds;
  final Map<String, Map<String, bool>> presentBy;
  final Map<String, AttendanceExcuse> excuses;
  final String takenByKhademId;
  final String takenByKhademName;
  final String status; // 'draft', 'finalized'
  final DateTime? finalizedAt;
  final DateTime updatedAt;

  final String serviceId;
  final String? lockedByKhademId;
  final String? lockedByKhademName;
  final DateTime? lockExpiresAt;

  const AttendanceSessionModel({
    required this.id,
    required this.date,
    required this.type,
    required this.grade,
    this.serviceId = 'thanawy',
    this.attendedMakhdomIds = const [],
    this.presentBy = const {},
    this.excuses = const {},
    this.takenByKhademId = '',
    this.takenByKhademName = '',
    this.status = 'draft',
    this.finalizedAt,
    required this.updatedAt,
    this.lockedByKhademId,
    this.lockedByKhademName,
    this.lockExpiresAt,
  });

  bool isAttended(String makhdomId) {
    final byServants = presentBy[makhdomId];
    if (byServants != null && byServants.values.any((v) => v == true)) {
      return true;
    }
    return attendedMakhdomIds.contains(makhdomId);
  }

  bool isExcused(String makhdomId) =>
      !isAttended(makhdomId) && excuses.containsKey(makhdomId);

  AttendanceExcuse? excuseFor(String makhdomId) => excuses[makhdomId];

  int get attendedCount => attendedMakhdomIds.length;
  int get excusedCount =>
      excuses.keys.where((makhdomId) => !isAttended(makhdomId)).length;

  bool get isMass => type == 'qoddas';
  bool get isService => type == 'khedma';
  bool get isFinalized => status == 'finalized';
  bool get isDraft => status == 'draft';

  bool isLockActive({DateTime? now}) {
    if (lockedByKhademId == null || lockedByKhademId!.isEmpty) return false;
    if (lockExpiresAt == null) return false;
    return lockExpiresAt!.isAfter(now ?? DateTime.now());
  }

  bool isLockedByOther(String currentKhademId, {DateTime? now}) {
    if (!isLockActive(now: now)) return false;
    return lockedByKhademId != currentKhademId;
  }

  static String generateSessionId({
    required String date,
    required String type,
    required String grade,
  }) {
    return '${date}_${type}_$grade';
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'type': type,
      'grade': grade,
      'serviceId': serviceId,
      'attendedMakhdomIds': attendedMakhdomIds,
      'presentBy': presentBy,
      'excuses': excuses.map((k, v) => MapEntry(k, v.toMap())),
      'takenByKhademId': takenByKhademId,
      'takenByKhademName': takenByKhademName,
      'status': status,
      'finalizedAt': finalizedAt != null
          ? Timestamp.fromDate(finalizedAt!)
          : null,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lockedByKhademId': lockedByKhademId,
      'lockedByKhademName': lockedByKhademName,
      'lockExpiresAt': lockExpiresAt != null
          ? Timestamp.fromDate(lockExpiresAt!)
          : null,
    };
  }

  factory AttendanceSessionModel.fromMap(
    Map<String, dynamic> map,
    String docId,
  ) {
    // The trusted backend's session ID/day uses UTC calendar dates. Retain that
    // day regardless of the viewing device's time zone; legacy strings read as-is.
    String parseSessionDay(dynamic value) {
      if (value is String) return value;
      if (value is Timestamp) {
        final date = value.toDate().toUtc();
        return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }
      return '';
    }

    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final rawPresentBy = map['presentBy'];
    final parsedPresentBy = <String, Map<String, bool>>{};
    if (rawPresentBy is Map) {
      rawPresentBy.forEach((studentKey, servantMap) {
        if (servantMap is Map) {
          final inner = <String, bool>{};
          servantMap.forEach((k, v) {
            if (v == true) inner[k.toString()] = true;
          });
          if (inner.isNotEmpty) {
            parsedPresentBy[studentKey.toString()] = inner;
          }
        }
      });
    }

    final rawList = map['attendedMakhdomIds'];
    final legacyIds = rawList is List
        ? rawList.map((e) => e.toString()).toSet()
        : <String>{};

    // If presentBy is populated, union its active student keys with legacyIds
    // so offline CRDT per-servant marks and legacy attendedMakhdomIds work together.
    final mergedAttendedIds = <String>{
      ...legacyIds,
      ...parsedPresentBy.keys,
    }.toList();

    final rawExcuses = map['excuses'];
    final parsedExcuses = <String, AttendanceExcuse>{};
    if (rawExcuses is Map) {
      rawExcuses.forEach((studentKey, excuseVal) {
        if (excuseVal is Map) {
          final excuse = AttendanceExcuse.fromMap(
            Map<String, dynamic>.from(excuseVal),
          );
          if (excuse.note.isNotEmpty) {
            parsedExcuses[studentKey.toString()] = excuse;
          }
        }
      });
    }

    final rawServiceId = map['serviceId'] as String?;
    final resolvedServiceId =
        (rawServiceId != null && rawServiceId.isNotEmpty) ? rawServiceId : 'thanawy';

    return AttendanceSessionModel(
      id: docId,
      date: parseSessionDay(map['date']),
      type: map['type'] ?? 'khedma',
      grade: map['grade'] ?? '1st',
      serviceId: resolvedServiceId,
      attendedMakhdomIds: mergedAttendedIds,
      presentBy: parsedPresentBy,
      excuses: parsedExcuses,
      takenByKhademId: map['takenByKhademId'] ?? '',
      takenByKhademName: map['takenByKhademName'] ?? '',
      status: map['status'] ?? 'draft',
      finalizedAt: parseNullableDate(map['finalizedAt']),
      updatedAt: parseDate(map['updatedAt']),
      lockedByKhademId: map['lockedByKhademId']?.toString(),
      lockedByKhademName: map['lockedByKhademName']?.toString(),
      lockExpiresAt: parseNullableDate(map['lockExpiresAt']),
    );
  }

  AttendanceSessionModel copyWith({
    String? id,
    String? date,
    String? type,
    String? grade,
    String? serviceId,
    List<String>? attendedMakhdomIds,
    Map<String, Map<String, bool>>? presentBy,
    Map<String, AttendanceExcuse>? excuses,
    String? takenByKhademId,
    String? takenByKhademName,
    String? status,
    DateTime? finalizedAt,
    DateTime? updatedAt,
    String? lockedByKhademId,
    String? lockedByKhademName,
    DateTime? lockExpiresAt,
  }) {
    return AttendanceSessionModel(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      grade: grade ?? this.grade,
      serviceId: serviceId ?? this.serviceId,
      attendedMakhdomIds: attendedMakhdomIds ?? this.attendedMakhdomIds,
      presentBy: presentBy ?? this.presentBy,
      excuses: excuses ?? this.excuses,
      takenByKhademId: takenByKhademId ?? this.takenByKhademId,
      takenByKhademName: takenByKhademName ?? this.takenByKhademName,
      status: status ?? this.status,
      finalizedAt: finalizedAt ?? this.finalizedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lockedByKhademId: lockedByKhademId ?? this.lockedByKhademId,
      lockedByKhademName: lockedByKhademName ?? this.lockedByKhademName,
      lockExpiresAt: lockExpiresAt ?? this.lockExpiresAt,
    );
  }
}
