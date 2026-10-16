import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/localization/domain_labels.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/router/router_services.dart';
import '../../../../core/session/session_state.dart';
import '../../models/report_filter_data.dart';
import '../../models/report_type.dart';

class ReportGradeDropdown extends StatelessWidget {
  final ReportFilterData filters;
  final SessionState session;
  final bool isDark;
  final ValueChanged<ReportFilterData> onFiltersChanged;

  const ReportGradeDropdown({
    super.key,
    required this.filters,
    required this.session,
    required this.isDark,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentGrade = filters.grade ?? 'all';
    final firestore = RouterServices.maybeOf(context)?.firestore;
    final labels = DomainLabels(Localizations.localeOf(context));

    return StreamBuilder<ServiceModel?>(
      stream: firestore?.watchService(session.serviceId),
      builder: (context, snapshot) {
        final service = snapshot.data;
        final grades = service?.grades ?? [];

        final List<DropdownMenuItem<String>> items = [
          const DropdownMenuItem(
            value: 'all',
            child: Text('جميع المراحل والصفوف'),
          ),
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
              fontSize: 12.sp,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 10.h,
            ),
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
}

class ReportKhademDropdown extends StatelessWidget {
  final ReportFilterData filters;
  final ReportType selectedType;
  final List<KhademModel> availableKhodam;
  final bool isDark;
  final ValueChanged<ReportFilterData> onFiltersChanged;

  const ReportKhademDropdown({
    super.key,
    required this.filters,
    required this.selectedType,
    required this.availableKhodam,
    required this.isDark,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
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
        labelText:
            requiresSingle ? 'اختر الخادم المطلوب تقييمه *' : 'الخادم المسؤول',
        labelStyle: TextStyle(
          fontSize: 12.sp,
          color: isDark ? Colors.white70 : Colors.grey.shade700,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 10.h,
        ),
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
}

class ReportThresholdFilters extends StatelessWidget {
  final ReportType selectedType;
  final ReportFilterData filters;
  final bool isDark;
  final ValueChanged<ReportFilterData> onFiltersChanged;

  const ReportThresholdFilters({
    super.key,
    required this.selectedType,
    required this.filters,
    required this.isDark,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedType == ReportType.repeatedAbsence)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: DropdownButtonFormField<int>(
              key: ValueKey('absence_${filters.consecutiveAbsenceWeeks}'),
              initialValue: filters.consecutiveAbsenceWeeks,
              decoration: InputDecoration(
                labelText: 'حد الغياب المتتالي للإنذار',
                labelStyle: TextStyle(
                  fontSize: 12.sp,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 10.h,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 2, child: Text('انقطاع أسبوعين متتاليين')),
                DropdownMenuItem(
                  value: 3,
                  child: Text('انقطاع 3 أسابيع متتالية (الافتراضي)'),
                ),
                DropdownMenuItem(
                  value: 4,
                  child: Text('انقطاع 4 أسابيع متتالية (خطر)'),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  onFiltersChanged(
                    filters.copyWith(consecutiveAbsenceWeeks: val),
                  );
                }
              },
            ),
          ),
        if (selectedType == ReportType.unvisitedMakhdomeen)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: DropdownButtonFormField<int>(
              key: ValueKey('unvisited_${filters.unvisitedDaysThreshold}'),
              initialValue: filters.unvisitedDaysThreshold,
              decoration: InputDecoration(
                labelText: 'المدة بدون افتقاد',
                labelStyle: TextStyle(
                  fontSize: 12.sp,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 10.h,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 15, child: Text('أكثر من 15 يوماً')),
                DropdownMenuItem(
                  value: 30,
                  child: Text('أكثر من شهر (30 يوماً)'),
                ),
                DropdownMenuItem(value: 45, child: Text('أكثر من 45 يوماً')),
                DropdownMenuItem(
                  value: 60,
                  child: Text('أكثر من شهرين (60 يوماً)'),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  onFiltersChanged(
                    filters.copyWith(unvisitedDaysThreshold: val),
                  );
                }
              },
            ),
          ),
        if (selectedType.category == ReportCategory.visitation)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: DropdownButtonFormField<String>(
              key: ValueKey('visitation_${filters.activityType}'),
              initialValue: filters.activityType,
              decoration: InputDecoration(
                labelText: 'نوع الافتقاد',
                labelStyle: TextStyle(
                  fontSize: 12.sp,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 10.h,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('كل أنواع الافتقاد')),
                DropdownMenuItem(
                  value: 'زيارة منزلية',
                  child: Text('زيارة منزلية فقط'),
                ),
                DropdownMenuItem(
                  value: 'مكالمة تليفونية',
                  child: Text('مكالمة تليفونية فقط'),
                ),
                DropdownMenuItem(
                  value: 'لقاء في الكنيسة',
                  child: Text('لقاء في الكنيسة فقط'),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  onFiltersChanged(filters.copyWith(activityType: val));
                }
              },
            ),
          ),
        if (selectedType.category == ReportCategory.attendance &&
            selectedType != ReportType.serviceVsQoddas)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: DropdownButtonFormField<String>(
              key: ValueKey('attendance_${filters.activityType}'),
              initialValue: filters.activityType,
              decoration: InputDecoration(
                labelText: 'نوع الجلسة',
                labelStyle: TextStyle(
                  fontSize: 12.sp,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 10.h,
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'all',
                  child: Text('الكل (خدمة + قداس)'),
                ),
                DropdownMenuItem(
                  value: 'khedma',
                  child: Text('جلسات الخدمة فقط'),
                ),
                DropdownMenuItem(
                  value: 'qoddas',
                  child: Text('جلسات القداس فقط'),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  onFiltersChanged(filters.copyWith(activityType: val));
                }
              },
            ),
          ),
      ],
    );
  }
}
