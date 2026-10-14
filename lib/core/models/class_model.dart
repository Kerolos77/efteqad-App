import 'package:cloud_firestore/cloud_firestore.dart';

class ClassModel {
  final String id;
  final String name;
  final String serviceId;
  final String gradeId;
  final String? servantId;
  final String? servantName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ClassModel({
    required this.id,
    required this.name,
    required this.serviceId,
    required this.gradeId,
    this.servantId,
    this.servantName,
    required this.createdAt,
    this.updatedAt,
  });

  factory ClassModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return ClassModel(
      id: id,
      name: data['name'] as String? ?? '',
      serviceId: data['serviceId'] as String? ?? 'thanawy',
      gradeId: data['gradeId'] as String? ?? '',
      servantId: data['servantId'] as String?,
      servantName: data['servantName'] as String?,
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
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  ClassModel copyWith({
    String? id,
    String? name,
    String? serviceId,
    String? gradeId,
    String? servantId,
    String? servantName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassModel(
      id: id ?? this.id,
      name: name ?? this.name,
      serviceId: serviceId ?? this.serviceId,
      gradeId: gradeId ?? this.gradeId,
      servantId: servantId ?? this.servantId,
      servantName: servantName ?? this.servantName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
