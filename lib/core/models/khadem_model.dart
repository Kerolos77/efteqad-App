import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/constants.dart';

class KhademModel {
  final String id; // UID from Firebase Auth
  final String email;
  final String name;
  final String phone;
  final String? colorHex;
  final int assignedCount;
  final String role; // 'stageAdmin', 'gradeAdmin', 'servant', 'pending'
  final String? grade; // '1st', '2nd', '3rd', or null
  final String status; // 'active', 'pending', 'rejected'
  final String? rejectionReason; // Reason why application was rejected by Stage Admin
  final String? locale;
  final String? fcmToken; // FCM push token for device
  final String? serviceId; // Service ID (e.g. ebtedai, thanawy)
  final List<String> serviceIds; // All services the khadem belongs to
  final DateTime createdAt;

  const KhademModel({
    required this.id,
    required this.email,
    required this.name,
    this.phone = '',
    this.colorHex,
    this.assignedCount = 0,
    this.role = AppConstants.rolePending,
    this.grade,
    this.status = AppConstants.rolePending,
    this.rejectionReason,
    this.locale,
    this.fcmToken,
    this.serviceId,
    this.serviceIds = const [],
    required this.createdAt,
  });

  bool get isStageAdmin => role == AppConstants.roleStageAdmin;
  bool get isGradeAdmin => role == AppConstants.roleGradeAdmin;
  bool get isRejected => status == 'rejected';
  bool get isPending =>
      role == AppConstants.rolePending ||
      status == AppConstants.rolePending ||
      status == 'rejected' ||
      (role != AppConstants.roleStageAdmin && grade == null);
  bool get isActive => !isPending && !isRejected;

  KhademModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? colorHex,
    int? assignedCount,
    String? role,
    String? grade,
    String? status,
    String? rejectionReason,
    String? locale,
    String? fcmToken,
    String? serviceId,
    List<String>? serviceIds,
    DateTime? createdAt,
  }) {
    return KhademModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      colorHex: colorHex ?? this.colorHex,
      assignedCount: assignedCount ?? this.assignedCount,
      role: role ?? this.role,
      grade: grade ?? this.grade,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      locale: locale ?? this.locale,
      fcmToken: fcmToken ?? this.fcmToken,
      serviceId: serviceId ?? this.serviceId,
      serviceIds: serviceIds ?? this.serviceIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'colorHex': colorHex,
      'assignedCount': assignedCount,
      'role': role,
      'grade': grade,
      'status': status,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      'locale': locale,
      'fcmToken': fcmToken,
      if (serviceId != null) 'serviceId': serviceId,
      if (serviceIds.isNotEmpty) 'serviceIds': serviceIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory KhademModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final role = map['role'] ?? AppConstants.rolePending;
    final parsedServiceId = map['serviceId'] as String?;
    final rawServiceIds = map['serviceIds'];
    List<String> parsedServiceIds = [];
    if (rawServiceIds is List) {
      parsedServiceIds = rawServiceIds.map((e) => e.toString()).toList();
    } else if (parsedServiceId != null && parsedServiceId.isNotEmpty) {
      parsedServiceIds = [parsedServiceId];
    }

    return KhademModel(
      id: docId,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      colorHex: map['colorHex'],
      assignedCount: (map['assignedCount'] is num)
          ? (map['assignedCount'] as num).toInt()
          : 0,
      role: role,
      grade: map['grade'],
      status:
          map['status'] ??
          ((role == AppConstants.roleStageAdmin || map['grade'] != null)
              ? 'active'
              : AppConstants.rolePending),
      rejectionReason: map['rejectionReason'] as String?,
      locale: map['locale'] is String ? map['locale'] as String : null,
      fcmToken: map['fcmToken'],
      serviceId: parsedServiceId,
      serviceIds: parsedServiceIds,
      createdAt: parseDate(map['createdAt']),
    );
  }
}
