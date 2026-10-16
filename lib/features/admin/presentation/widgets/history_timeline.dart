import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/visit_model.dart';
import '../../models/history_analysis.dart';
import 'history_filters.dart';
import 'history_visit_timeline_card.dart';
import 'history_attendance_timeline_card.dart';

class HistoryTimeline extends StatelessWidget {
  final HistoryAnalysis analysis;
  final Set<String>? visibleVisitIds;
  final Widget? moreVisits;
  final HistoryFilterType selectedFilter;
  final bool Function(DateTime) isDateInRange;
  final bool isDark;
  final ValueChanged<VisitModel> onEditVisitNotes;

  const HistoryTimeline({
    super.key,
    required this.analysis,
    this.visibleVisitIds,
    this.moreVisits,
    required this.selectedFilter,
    required this.isDateInRange,
    required this.isDark,
    required this.onEditVisitNotes,
  });

  @override
  Widget build(BuildContext context) {
    // بناء قائمة العناصر المتطابقة مع الفلتر والنطاق الزمني
    final List<Widget> items = [];

    // إضافة الافتقادات إذا كان الفلتر يسمح
    if (selectedFilter == HistoryFilterType.all ||
        selectedFilter == HistoryFilterType.visitsOnly ||
        selectedFilter == HistoryFilterType.fruitfulOnly) {
      for (final vi in analysis.visitsWithImpact) {
        if (visibleVisitIds != null &&
            !visibleVisitIds!.contains(vi.visit.id)) {
          continue;
        }
        if (!isDateInRange(vi.visit.visitDate)) continue;
        if (selectedFilter == HistoryFilterType.fruitfulOnly &&
            vi.outcome != VisitFridayOutcome.both &&
            vi.outcome != VisitFridayOutcome.serviceOnly &&
            vi.outcome != VisitFridayOutcome.massOnly) {
          continue;
        }

        items.add(
          HistoryVisitTimelineCard(
            item: vi,
            isDark: isDark,
            onEditVisitNotes: onEditVisitNotes,
          ),
        );
      }
    }

    // إضافة جمعات الحضور إذا كان الفلتر يسمح
    if (selectedFilter == HistoryFilterType.all ||
        selectedFilter == HistoryFilterType.attendanceOnly ||
        selectedFilter == HistoryFilterType.absencesOnly ||
        selectedFilter == HistoryFilterType.fruitfulOnly) {
      for (final fr in analysis.fridayRecords) {
        if (!isDateInRange(fr.date)) continue;
        if (selectedFilter == HistoryFilterType.absencesOnly && !fr.isAbsent) {
          continue;
        }
        if (selectedFilter == HistoryFilterType.fruitfulOnly &&
            (!fr.isAttendedAny || fr.precedingVisit == null)) {
          continue;
        }

        items.add(
          HistoryAttendanceTimelineCard(
            item: fr,
            isDark: isDark,
          ),
        );
      }
    }

    if (moreVisits != null) items.add(moreVisits!);
    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 36.h),
          child: Column(
            children: [
              Icon(
                Icons.event_busy_rounded,
                size: 48.sp,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: 12.h),
              Text(
                context.tr.noEventsMatchingFilter,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => items[index],
          childCount: items.length,
        ),
      ),
    );
  }
}
