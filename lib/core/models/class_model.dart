import 'package:cloud_firestore/cloud_firestore.dart';

class ClassModel {
  final String id;
  final String name;
  final String serviceId;
  final String gradeId;
  final List<String> servantIds;
  final List<String> servantNames;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ClassModel({
    required this.id,
    required this.name,
    required this.serviceId,
    required this.gradeId,
    this.servantIds = const [],
    this.servantNames = const [],
    required this.createdAt,
    this.updatedAt,
  });

  String? get servantId => servantIds.isNotEmpty ? servantIds.first : null;
  String? get servantName => servantNames.isNotEmpty ? servantNames.join('، ') : null;

  factory ClassModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    final rawServantIds = data['servantIds'];
    List<String> servantIds = [];
    if (rawServantIds is List) {
      servantIds = rawServantIds.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    } else if (data['servantId'] != null && (data['servantId'] as String).isNotEmpty) {
      servantIds = [data['servantId'] as String];
    }

    final rawServantNames = data['servantNames'];
    List<String> servantNames = [];
    if (rawServantNames is List) {
      servantNames = rawServantNames.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    } else if (data['servantName'] != null && (data['servantName'] as String).isNotEmpty) {
      servantNames = [data['servantName'] as String];
    }

    return ClassModel(
      id: id,
      name: data['name'] as String? ?? '',
      serviceId: data['serviceId'] as String? ?? 'thanawy',
      gradeId: data['gradeId'] as String? ?? '',
      servantIds: servantIds,
      servantNames: servantNames,
      createdAt: parseDate(data['createdAt']),
      updatedAt: data['updatedAt'] != null ? parseDate(data['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name.trim(),
      'serviceId': serviceId,
      'gradeId': gradeId,
      'servantId': servantId,
      'servantName': servantName,
      'servantIds': servantIds,
      'servantNames': servantNames,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  ClassModel copyWith({
    String? id,
    String? name,
    String? serviceId,
    String? gradeId,
    List<String>? servantIds,
    List<String>? servantNames,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassModel(
      id: id ?? this.id,
      name: name ?? this.name,
      serviceId: serviceId ?? this.serviceId,
      gradeId: gradeId ?? this.gradeId,
      servantIds: servantIds ?? this.servantIds,
      servantNames: servantNames ?? this.servantNames,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
