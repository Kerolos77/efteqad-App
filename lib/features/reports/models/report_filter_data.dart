import 'package:flutter/material.dart';

enum QuickDateFilter {
  thisWeek,
  thisMonth,
  lastMonth,
  last3Months,
  thisQuarter,
  custom,
}

extension QuickDateFilterExtension on QuickDateFilter {
  String get label {
    switch (this) {
      case QuickDateFilter.thisWeek:
        return 'هذا الأسبوع';
      case QuickDateFilter.thisMonth:
        return 'هذا الشهر';
      case QuickDateFilter.lastMonth:
        return 'الشهر الماضي';
      case QuickDateFilter.last3Months:
        return 'آخر 3 شهور';
      case QuickDateFilter.thisQuarter:
        return 'الربع الحالي';
      case QuickDateFilter.custom:
        return 'فترة مخصصة';
    }
  }

  DateTimeRange toRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (this) {
      case QuickDateFilter.thisWeek:
        // اعتبار الأحد أو الجمعة بداية الأسبوع؛ هنا نأخذ آخر 7 أيام
        return DateTimeRange(
          start: today.subtract(const Duration(days: 7)),
          end: today.add(const Duration(days: 1)),
        );

      case QuickDateFilter.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 1),
        );

      case QuickDateFilter.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        return DateTimeRange(
          start: lastMonth,
          end: DateTime(now.year, now.month, 1),
        );

      case QuickDateFilter.last3Months:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 3, 1),
          end: today.add(const Duration(days: 1)),
        );

      case QuickDateFilter.thisQuarter:
        final currentQuarter = ((now.month - 1) ~/ 3) + 1;
        final startMonth = (currentQuarter - 1) * 3 + 1;
        return DateTimeRange(
          start: DateTime(now.year, startMonth, 1),
          end: DateTime(now.year, startMonth + 3, 1),
        );

      case QuickDateFilter.custom:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 30)),
          end: today.add(const Duration(days: 1)),
        );
    }
  }
}

class ReportFilterData {
  final String? serviceId;
  final String? grade; // 'all' or specific grade e.g. '1st', '2nd'
  final String? classId; // 'all' or specific class id
  final String? khademId; // 'all' or specific khadem id
  final QuickDateFilter quickDateFilter;
  final DateTimeRange dateRange;
  final String activityType; // 'all', 'khedma', 'qoddas'
  final int consecutiveAbsenceWeeks; // 2, 3, 4
  final int unvisitedDaysThreshold; // 15, 30, 45, 60
  final bool activeOnly;

  ReportFilterData({
    this.serviceId,
    this.grade = 'all',
    this.classId = 'all',
    this.khademId = 'all',
    this.quickDateFilter = QuickDateFilter.thisMonth,
    DateTimeRange? dateRange,
    this.activityType = 'all',
    this.consecutiveAbsenceWeeks = 3,
    this.unvisitedDaysThreshold = 30,
    this.activeOnly = true,
  }) : dateRange = dateRange ?? QuickDateFilter.thisMonth.toRange();

  ReportFilterData copyWith({
    String? serviceId,
    String? grade,
    String? classId,
    String? khademId,
    QuickDateFilter? quickDateFilter,
    DateTimeRange? dateRange,
    String? activityType,
    int? consecutiveAbsenceWeeks,
    int? unvisitedDaysThreshold,
    bool? activeOnly,
  }) {
    return ReportFilterData(
      serviceId: serviceId ?? this.serviceId,
      grade: grade ?? this.grade,
      classId: classId ?? this.classId,
      khademId: khademId ?? this.khademId,
      quickDateFilter: quickDateFilter ?? this.quickDateFilter,
      dateRange: dateRange ?? this.dateRange,
      activityType: activityType ?? this.activityType,
      consecutiveAbsenceWeeks:
          consecutiveAbsenceWeeks ?? this.consecutiveAbsenceWeeks,
      unvisitedDaysThreshold:
          unvisitedDaysThreshold ?? this.unvisitedDaysThreshold,
      activeOnly: activeOnly ?? this.activeOnly,
    );
  }
}
