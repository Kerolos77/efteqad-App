import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/attendance_session_model.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/services/attendance_analytics_service.dart';
import '../../../admin/presentation/widgets/makhdom_card.dart';
import '../../../common/widgets/record_visit_sheet.dart';
import 'at_risk_alert_banner.dart';
import 'makhdomeen_filter_bar.dart';
import 'servant_hero_card.dart';

class MyMakhdomeenTab extends StatefulWidget {
  final List<MakhdomModel> myMakhdomeen;
  final List<AttendanceSessionModel> sessions;
  final VoidCallback? onSwitchToAnalytics;
  final String? servantName;
  final Color? khademColor;

  const MyMakhdomeenTab({
    super.key,
    required this.myMakhdomeen,
    this.sessions = const [],
    this.onSwitchToAnalytics,
    this.servantName,
    this.khademColor,
  });

  @override
  State<MyMakhdomeenTab> createState() => _MyMakhdomeenTabState();
}

class _MyMakhdomeenTabState extends State<MyMakhdomeenTab> {
  String _search = '';
  String _filter = 'all'; // 'all', 'visited', 'unvisited', 'brethren'

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatters = AppFormatters(Localizations.localeOf(context));
    final totalCount = widget.myMakhdomeen.length;
    final visitedCount = widget.myMakhdomeen
        .where((m) => m.visitCount > 0)
        .length;
    final unvisitedCount = totalCount - visitedCount;
    final brethrenCount = widget.myMakhdomeen.where((m) => m.isBrethrenOfLord).length;
    final percentage = totalCount > 0 ? (visitedCount / totalCount) : 0.0;

    final atRiskList = widget.sessions.isNotEmpty
        ? AttendanceAnalyticsService.getAtRiskStudents(
            makhdomeen: widget.myMakhdomeen,
            sessions: widget.sessions,
          )
        : <AtRiskStudentInfo>[];

    final filtered = widget.myMakhdomeen.where((m) {
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final matches =
            m.fullName.toLowerCase().contains(q) ||
            m.area.toLowerCase().contains(q) ||
            m.phone.contains(q);
        if (!matches) return false;
      }
      switch (_filter) {
        case 'visited':
          return m.visitCount > 0;
        case 'unvisited':
          return m.visitCount == 0;
        case 'brethren':
          return m.isBrethrenOfLord;
        default:
          return true;
      }
    }).toList();

    return Column(
      children: [
        if (widget.servantName != null && widget.khademColor != null)
          ServantHeroCard(
            servantName: widget.servantName!,
            khademColor: widget.khademColor!,
            visitedCount: visitedCount,
            totalCount: totalCount,
            isDark: isDark,
          )
        else
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.backgroundDark
                  : AppColors.backgroundLight,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr.messageOfVisited(
                        formatters.formatNumber(visitedCount),
                        formatters.formatNumber(totalCount),
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                      ),
                    ),
                    Text(
                      '${(percentage * 100).toInt()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                        color: AppColors.royalGold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: percentage,
                    minHeight: 6.h,
                    backgroundColor: isDark
                        ? Colors.white10
                        : const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.royalGold,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // At-risk warning banner
        AtRiskAlertBanner(
          atRiskCount: atRiskList.length,
          isDark: isDark,
          onViewAnalytics: widget.onSwitchToAnalytics,
        ),

        // Search & Filter
        if (widget.myMakhdomeen.isNotEmpty) ...[
          MakhdomeenFilterBar(
            searchQuery: _search,
            onSearchChanged: (val) => setState(() => _search = val.trim()),
            activeFilter: _filter,
            onFilterChanged: (key) => setState(() => _filter = key),
            totalCount: totalCount,
            unvisitedCount: unvisitedCount,
            visitedCount: visitedCount,
            brethrenCount: brethrenCount,
            isDark: isDark,
          ),
          SizedBox(height: 8.h),
        ],

        // Student list
        Expanded(
          child: widget.myMakhdomeen.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 16.h,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(18.r),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white10
                                : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_search_rounded,
                            size: 40.sp,
                            color: isDark
                                ? Colors.white38
                                : Colors.grey.shade400,
                          ),
                        ),
                        SizedBox(height: 14.h),
                        Text(
                          context.tr.noMakhdomeenAssignedTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16.sp,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          context.tr.noMakhdomeenAssignedSubtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : filtered.isEmpty
                  ? Center(
                      child: Text(
                        context.tr.noSearchResults,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          fontSize: 13.sp,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.only(bottom: 24.h),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final m = filtered[index];
                        return MakhdomCard(
                          makhdom: m,
                          onLogVisit: () {
                            RecordVisitSheet.show(context, makhdom: m);
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
