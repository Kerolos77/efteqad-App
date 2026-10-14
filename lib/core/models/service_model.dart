import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceGrade {
  final String id;
  final String name;
  final int order;

  const ServiceGrade({
    required this.id,
    required this.name,
    required this.order,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'order': order,
    };
  }

  factory ServiceGrade.fromMap(Map<String, dynamic> map) {
    return ServiceGrade(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      order: (map['order'] is num) ? (map['order'] as num).toInt() : 1,
    );
  }
}

class ServiceModel {
  final String id;
  final String name;
  final List<String> adminUids;
  final List<String> adminEmails;
  final int gradesCount;
  final List<ServiceGrade> grades;
  final bool active;
  final DateTime createdAt;
  final Map<String, dynamic>? config;

  const ServiceModel({
    required this.id,
    required this.name,
    this.adminUids = const [],
    this.adminEmails = const [],
    this.gradesCount = 0,
    this.grades = const [],
    this.active = true,
    required this.createdAt,
    this.config,
  });

  ServiceModel copyWith({
    String? id,
    String? name,
    List<String>? adminUids,
    List<String>? adminEmails,
    int? gradesCount,
    List<ServiceGrade>? grades,
    bool? active,
    DateTime? createdAt,
    Map<String, dynamic>? config,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      adminUids: adminUids ?? this.adminUids,
      adminEmails: adminEmails ?? this.adminEmails,
      gradesCount: gradesCount ?? this.gradesCount,
      grades: grades ?? this.grades,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      config: config ?? this.config,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'adminUids': adminUids,
      'adminEmails': adminEmails,
      'gradesCount': gradesCount,
      'grades': grades.map((g) => g.toMap()).toList(),
      'active': active,
      'createdAt': Timestamp.fromDate(createdAt),
      if (config != null) 'config': config,
    };
  }

  factory ServiceModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final rawGrades = map['grades'];
    List<ServiceGrade> parsedGrades = [];
    if (rawGrades is List) {
      parsedGrades = rawGrades
          .whereType<Map<String, dynamic>>()
          .map((g) => ServiceGrade.fromMap(g))
          .toList();
    }

    return ServiceModel(
      id: docId,
      name: map['name'] ?? '',
      adminUids: (map['adminUids'] is List)
          ? List<String>.from(map['adminUids'])
          : (map['adminUid'] != null ? [map['adminUid'].toString()] : const []),
      adminEmails: (map['adminEmails'] is List)
          ? List<String>.from(map['adminEmails'])
          : (map['adminEmail'] != null ? [map['adminEmail'].toString()] : const []),
      gradesCount: (map['gradesCount'] is num)
          ? (map['gradesCount'] as num).toInt()
          : parsedGrades.length,
      grades: parsedGrades,
      active: map['active'] != false,
      createdAt: parseDate(map['createdAt']),
      config: map['config'] is Map<String, dynamic>
          ? map['config'] as Map<String, dynamic>
          : null,
    );
  }
}
