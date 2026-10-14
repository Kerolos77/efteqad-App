import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/domain_labels.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/router/router_services.dart';
import '../../../../core/session/session_state.dart';
import '../../models/report_filter_data.dart';
import '../../models/report_type.dart';

class ReportFilterPanel extends StatelessWidget {
  final ReportType selectedType;
  final ReportFilterData filters;
  final SessionState session;
  final List<KhademModel> availableKhodam;
  final ValueChanged<ReportFilterData> onFiltersChanged;

  const ReportFilterPanel({
    super.key,
    required this.selectedType,
    required this.filters,
    required this.session,
    required this.availableKhodam,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppConstants.sacredGold : AppConstants.primaryLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 20, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                'فلاتر التقرير وخيارات الاستخراج',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. الفلاتر الزمنية السريعة
          _buildDateFilters(context, isDark, primaryColor),
          const SizedBox(height: 14),

          // 2. فلتر الصف (لأمين الخدمة فقط)
          if (session.isStageAdmin) ...[
            _buildGradeDropdown(context, isDark),
            const SizedBox(height: 12),
          ],

          // 3. فلتر اختيار الخادم (للأمناء أو إذا كان التقرير يتطلب خادماً مفرداً)
          if ((session.isStageAdmin || session.isGradeAdmin) ||
              selectedType.requiresSingleKhadem) ...[
            _buildKhademDropdown(isDark),
            const SizedBox(height: 12),
          ],

          // 4. فلاتر متغيرة حسب نوع التقرير المختار
          if (selectedType == ReportType.repeatedAbsence)
            _buildAbsenceThreshold(isDark),

          if (selectedType == ReportType.unvisitedMakhdomeen)
            _buildUnvisitedThreshold(isDark),

          if (selectedType.category == ReportCategory.visitation)
            _buildVisitationTypeFilter(isDark),

          if (selectedType.category == ReportCategory.attendance &&
              selectedType != ReportType.serviceVsQoddas)
            _buildAttendanceTypeFilter(isDark),
        ],
      ),
    );
  }

  Widget _buildDateFilters(
    BuildContext context,
    bool isDark,
    Color primaryColor,
  ) {
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الفترة الزمنية:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: QuickDateFilter.values.map((q) {
            final isSelected = filters.quickDateFilter == q;
            return ChoiceChip(
              label: Text(q.label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  if (q == QuickDateFilter.custom) {
                    _pickCustomRange(context);
                  } else {
                    onFiltersChanged(
                      filters.copyWith(
                        quickDateFilter: q,
                        dateRange: q.toRange(),
                      ),
                    );
                  }
                }
              },
              labelStyle: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? (isDark ? Colors.black87 : Colors.white)
                    : (isDark ? Colors.white70 : Colors.grey.shade800),
              ),
              selectedColor: primaryColor,
              backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                'من ${dateFormat.format(filters.dateRange.start)} إلى ${dateFormat.format(filters.dateRange.end)}',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: filters.dateRange,
    );
    if (picked != null) {
      onFiltersChanged(
        filters.copyWith(
          quickDateFilter: QuickDateFilter.custom,
          dateRange: picked,
        ),
      );
    }
  }

  Widget _buildGradeDropdown(BuildContext context, bool isDark) {
    final currentGrade = filters.grade ?? 'all';
    final firestore = RouterServices.maybeOf(context)?.firestore;
    final labels = DomainLabels(Localizations.localeOf(context));

    return StreamBuilder<ServiceModel?>(
      stream: firestore?.watchService(session.serviceId),
      builder: (context, snapshot) {
        final service = snapshot.data;
        final grades = service?.grades ?? [];

        final List<DropdownMenuItem<String>> items = [
          const DropdownMenuItem(value: 'all', child: Text('جميع المراحل والصفوف')),
          if (grades.isNotEmpty)
            ...grades.map(
              (g) => DropdownMenuItem(
                value: g.id,
                child: Text(labels.gradeName(g.id, grades)),
              ),
            )
          else ...[
            DropdownMenuItem(value: '1st', child: Text(labels.gradeName('1st'))),
            DropdownMenuItem(value: '2nd', child: Text(labels.gradeName('2nd'))),
            DropdownMenuItem(value: '3rd', child: Text(labels.gradeName('3rd'))),
          ],
        ];

        final effectiveValue = items.any((it) => it.value == currentGrade)
            ? currentGrade
            : 'all';

        return DropdownButtonFormField<String>(
          key: ValueKey('grade_$effectiveValue'),
          initialValue: effectiveValue,
          decoration: InputDecoration(
            labelText: 'المرحلة / الصف الدراسي',
            labelStyle: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: items,
          onChanged: (val) {
            if (val != null) {
              onFiltersChanged(filters.copyWith(grade: val));
            }
          },
        );
      },
    );
  }

  Widget _buildKhademDropdown(bool isDark) {
    final requiresSingle = selectedType.requiresSingleKhadem;
    final currentVal = filters.khademId;
    final effectiveVal = (currentVal != null &&
            (currentVal == 'all' ||
                availableKhodam.any((k) => k.id == currentVal)))
        ? currentVal
        : (requiresSingle && availableKhodam.isNotEmpty
            ? availableKhodam.first.id
            : 'all');

    return DropdownButtonFormField<String>(
      key: ValueKey('khadem_$effectiveVal'),
      initialValue: effectiveVal,
      decoration: InputDecoration(
        labelText: requiresSingle ? 'اختر الخادم المطلوب تقييمه *' : 'الخادم المسؤول',
        labelStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade700),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: [
        if (!requiresSingle)
          const DropdownMenuItem(value: 'all', child: Text('جميع الخدام')),
        ...availableKhodam.map(
          (k) => DropdownMenuItem(value: k.id, child: Text(k.name)),
        ),
      ],
      onChanged: (val) {
        if (val != null) {
          onFiltersChanged(filters.copyWith(khademId: val));
        }
      },
    );
  }

  Widget _buildAbsenceThreshold(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DropdownButtonFormField<int>(
        key: ValueKey('absence_${filters.consecutiveAbsenceWeeks}'),
        initialValue: filters.consecutiveAbsenceWeeks,
        decoration: InputDecoration(
          labelText: 'حد الغياب المتتالي للإنذار',
          labelStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade700),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: const [
          DropdownMenuItem(value: 2, child: Text('انقطاع أسبوعين متتاليين')),
          DropdownMenuItem(value: 3, child: Text('انقطاع 3 أسابيع متتالية (الافتراضي)')),
          DropdownMenuItem(value: 4, child: Text('انقطاع 4 أسابيع متتالية (خطر)')),
        ],
        onChanged: (val) {
          if (val != null) {
            onFiltersChanged(filters.copyWith(consecutiveAbsenceWeeks: val));
          }
        },
      ),
    );
  }

  Widget _buildUnvisitedThreshold(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DropdownButtonFormField<int>(
        key: ValueKey('unvisited_${filters.unvisitedDaysThreshold}'),
        initialValue: filters.unvisitedDaysThreshold,
        decoration: InputDecoration(
          labelText: 'المدة بدون افتقاد',
          labelStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade700),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: const [
          DropdownMenuItem(value: 15, child: Text('أكثر من 15 يوماً')),
          DropdownMenuItem(value: 30, child: Text('أكثر من شهر (30 يوماً)')),
          DropdownMenuItem(value: 45, child: Text('أكثر من 45 يوماً')),
          DropdownMenuItem(value: 60, child: Text('أكثر من شهرين (60 يوماً)')),
        ],
        onChanged: (val) {
          if (val != null) {
            onFiltersChanged(filters.copyWith(unvisitedDaysThreshold: val));
          }
        },
      ),
    );
  }

  Widget _buildVisitationTypeFilter(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DropdownButtonFormField<String>(
        key: ValueKey('visitation_${filters.activityType}'),
        initialValue: filters.activityType,
        decoration: InputDecoration(
          labelText: 'نوع الافتقاد',
          labelStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade700),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: const [
          DropdownMenuItem(value: 'all', child: Text('كل أنواع الافتقاد')),
          DropdownMenuItem(value: 'زيارة منزلية', child: Text('زيارة منزلية فقط')),
          DropdownMenuItem(value: 'مكالمة تليفونية', child: Text('مكالمة تليفونية فقط')),
          DropdownMenuItem(value: 'لقاء في الكنيسة', child: Text('لقاء في الكنيسة فقط')),
        ],
        onChanged: (val) {
          if (val != null) {
            onFiltersChanged(filters.copyWith(activityType: val));
          }
        },
      ),
    );
  }

  Widget _buildAttendanceTypeFilter(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DropdownButtonFormField<String>(
        key: ValueKey('attendance_${filters.activityType}'),
        initialValue: filters.activityType,
        decoration: InputDecoration(
          labelText: 'نوع الجلسة',
          labelStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade700),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: const [
          DropdownMenuItem(value: 'all', child: Text('الكل (خدمة + قداس)')),
          DropdownMenuItem(value: 'khedma', child: Text('جلسات الخدمة فقط')),
          DropdownMenuItem(value: 'qoddas', child: Text('جلسات القداس فقط')),
        ],
        onChanged: (val) {
          if (val != null) {
            onFiltersChanged(filters.copyWith(activityType: val));
          }
        },
      ),
    );
  }
}
