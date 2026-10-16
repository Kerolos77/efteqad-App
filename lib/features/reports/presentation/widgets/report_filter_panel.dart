import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/session/session_state.dart';
import '../../models/report_filter_data.dart';
import '../../models/report_type.dart';
import 'report_criteria_filters.dart';
import 'report_date_filter_section.dart';

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
    final primaryColor = isDark ? AppColors.sacredGold : AppColors.primaryLight;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 20.sp, color: primaryColor),
              SizedBox(width: 8.w),
              Text(
                'فلاتر التقرير وخيارات الاستخراج',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // 1. الفلاتر الزمنية السريعة
          ReportDateFilterSection(
            filters: filters,
            isDark: isDark,
            primaryColor: primaryColor,
            onFiltersChanged: onFiltersChanged,
          ),
          SizedBox(height: 14.h),

          // 2. فلتر الصف (لأمين الخدمة فقط)
          if (session.isStageAdmin) ...[
            ReportGradeDropdown(
              filters: filters,
              session: session,
              isDark: isDark,
              onFiltersChanged: onFiltersChanged,
            ),
            SizedBox(height: 12.h),
          ],

          // 3. فلتر اختيار الخادم (للأمناء أو إذا كان التقرير يتطلب خادماً مفرداً)
          if ((session.isStageAdmin || session.isGradeAdmin) ||
              selectedType.requiresSingleKhadem) ...[
            ReportKhademDropdown(
              filters: filters,
              selectedType: selectedType,
              availableKhodam: availableKhodam,
              isDark: isDark,
              onFiltersChanged: onFiltersChanged,
            ),
            SizedBox(height: 12.h),
          ],

          // 4. فلاتر متغيرة حسب نوع التقرير المختار
          ReportThresholdFilters(
            selectedType: selectedType,
            filters: filters,
            isDark: isDark,
            onFiltersChanged: onFiltersChanged,
          ),
        ],
      ),
    );
  }
}
