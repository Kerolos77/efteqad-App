import 'package:efteqad/core/localization/app_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/attendance_session_model.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/models/visit_model.dart';
import '../../../../core/services/attendance_analytics_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/utils/calendar_dates.dart';
import '../../../../core/widgets/query_content.dart';
import '../widgets/analytics_attendance_section.dart';
import '../widgets/analytics_smart_insights_section.dart';
import '../widgets/analytics_visits_section.dart';

class AnalyticsTab extends StatefulWidget {
  final FirestoreService? firestoreService;
  final DateTime? asOf;
  final List<MakhdomModel> makhdomeen;
  final List<KhademModel> khodam;
  final String? grade; // '1st', '2nd', '3rd', or null for Stage Admin
  final String? serviceId;

  const AnalyticsTab({
    super.key,
    required this.makhdomeen,
    required this.khodam,
    this.grade,
    this.serviceId,
    this.firestoreService,
    this.asOf,
  });

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  late final FirestoreService _firestoreService =
      widget.firestoreService ?? FirestoreService();
  String _selectedSubTab = 'visits'; // 'visits', 'attendance', 'insights'

  late final DateTime _asOf = widget.asOf ?? DateTime.now();
  bool _allTime = false;
  DateTime? get _from => _allTime ? null : calendarDay(_asOf, -89);
  List<VisitModel> _windowVisits = [];
  Set<String> get _visitedIds => _windowVisits.map((v) => v.makhdomId).toSet();

  Stream<List<AttendanceSessionModel>> _buildAttendanceStream() {
    if (widget.grade != null) {
      return _firestoreService.getAttendanceSessionsForGradeStream(
        widget.grade!,
        from: _from,
        to: _asOf,
        serviceId: widget.serviceId,
      );
    }
    return _firestoreService.getAllAttendanceSessionsStream(
      from: _from,
      to: _asOf,
      serviceId: widget.serviceId,
    );
  }

  Future<void> _makeCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) return;
    final url = Uri.parse('tel:$clean');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    var clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.startsWith('0')) clean = '2$clean';
    if (!clean.startsWith('20') && clean.length == 11) clean = '2$clean';
    if (clean.isEmpty) return;
    final url = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.makhdomeen.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insights_outlined,
              size: 50.sp,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
            ),
            SizedBox(height: 12.h),
            Text(
              context.tr.noAnalyticsData,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp),
            ),
          ],
        ),
      );
    }

    return QueryContent<List<VisitModel>>(
      queryKey: '${widget.serviceId}/${widget.grade}/$_from/$_asOf',
      query: () => _firestoreService.getAllVisitsStream(
        grade: widget.grade,
        from: _from,
        to: _asOf,
        serviceId: widget.serviceId,
      ),
      builder: (context, visits) {
        _windowVisits = visits;
        return QueryContent<List<AttendanceSessionModel>>(
          queryKey: '${widget.serviceId}/${widget.grade}/$_from/$_asOf',
          query: _buildAttendanceStream,
          builder: (context, sessions) {
            final atRiskList = AttendanceAnalyticsService.getAtRiskStudents(
              makhdomeen: widget.makhdomeen,
              sessions: sessions,
              minConsecutiveAbsences: 2,
              asOf: _asOf,
              from: _from,
            );

            return SingleChildScrollView(
              padding: EdgeInsetsDirectional.fromSTEB(16.w, 12.h, 16.w, 85.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الهيدر الرئيسي
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr.performanceAndCareIndicators,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Row(
                            children: [
                              Text(
                                context.tr.liveFollowupAndRates,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.sacredGold.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  _allTime
                                      ? context.tr.filterAllTime
                                      : context.tr.messageLast90Days,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.sacredGold
                                        : const Color(0xFF92400E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    _from == null
                        ? context.tr.filterAllTime
                        : context.tr.analyticsDateBounds(
                            AppFormatters(
                              Localizations.localeOf(context),
                            ).formatDate(_from!),
                            AppFormatters(
                              Localizations.localeOf(context),
                            ).formatDate(_asOf),
                          ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _allTime = !_allTime;
                    }),
                    child: Text(
                      _allTime
                          ? context.tr.filterLast90Days
                          : context.tr.filterAllTime,
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // شريط التنقل الفرعي الثلاثي
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildSubTabChip(
                          id: 'visits',
                          label: context.tr.tabVisitsAnalytics,
                          icon: Icons.volunteer_activism_outlined,
                          isDark: isDark,
                        ),
                        SizedBox(width: 8.w),
                        _buildSubTabChip(
                          id: 'attendance',
                          label: context.tr.tabAttendanceAnalytics,
                          icon: Icons.fact_check_outlined,
                          isDark: isDark,
                        ),
                        SizedBox(width: 8.w),
                        _buildSubTabChip(
                          id: 'insights',
                          label: context.tr.tabSmartInsights,
                          icon: Icons.psychology_outlined,
                          isDark: isDark,
                          badge: atRiskList.isNotEmpty
                              ? '${atRiskList.length}'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 18.h),

                  // محتوى التبويب المختار
                  if (_selectedSubTab == 'visits')
                    AnalyticsVisitsSection(
                      makhdomeen: widget.makhdomeen,
                      khodam: widget.khodam,
                      visitedIds: _visitedIds,
                      isDark: isDark,
                      onMakeCall: _makeCall,
                    )
                  else if (_selectedSubTab == 'attendance')
                    AnalyticsAttendanceSection(
                      makhdomeen: widget.makhdomeen,
                      sessions: sessions,
                      isDark: isDark,
                      asOf: _asOf,
                      from: _from,
                    )
                  else
                    AnalyticsSmartInsightsSection(
                      makhdomeen: widget.makhdomeen,
                      sessions: sessions,
                      atRiskList: atRiskList,
                      windowVisits: _windowVisits,
                      from: _from,
                      asOf: _asOf,
                      isDark: isDark,
                      onMakeCall: _makeCall,
                      onOpenWhatsApp: _openWhatsApp,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSubTabChip({
    required String id,
    required String label,
    required IconData icon,
    required bool isDark,
    String? badge,
  }) {
    final isSelected = _selectedSubTab == id;

    return InkWell(
      onTap: () => setState(() => _selectedSubTab = id),
      borderRadius: BorderRadius.circular(12.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.surfaceLight : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDark ? 0.3 : 0.05,
                    ),
                    blurRadius: 4.r,
                    offset: Offset(0, 2.h),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15.sp,
              color: isSelected
                  ? AppColors.primaryLight
                  : (isDark ? Colors.white54 : AppColors.textMuted),
            ),
            SizedBox(width: 5.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5.sp,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? (isDark ? Colors.white : AppColors.textPrimary)
                    : (isDark ? Colors.white54 : AppColors.textMuted),
              ),
            ),
            if (badge != null) ...[
              SizedBox(width: 4.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppColors.errorColor,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
