import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/attendance_analytics_service.dart';
import '../../../common/widgets/record_visit_sheet.dart';

class AbsenceAlertsSection extends StatelessWidget {
  final List<AtRiskStudentInfo> atRiskList;
  final bool hasAttendanceData;
  final bool isDark;
  final VoidCallback? onVisitRecorded;

  const AbsenceAlertsSection({
    super.key,
    required this.atRiskList,
    required this.hasAttendanceData,
    required this.isDark,
    this.onVisitRecorded,
  });

  Future<void> _makeCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) return;
    final url = Uri.parse('tel:$clean');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return;
    final url = Uri.parse('https://wa.me/2$clean');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.notifications_active_rounded,
              color: AppColors.errorColor,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              context.tr.absenceAlertsHeader,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800),
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: (atRiskList.isEmpty
                        ? AppColors.successColor
                        : AppColors.errorColor)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                '${atRiskList.length}',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                  color: atRiskList.isEmpty
                      ? AppColors.successColor
                      : AppColors.errorColor,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          context.tr.absenceAlertsSubtitle,
          style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted),
        ),
        SizedBox(height: 10.h),
        if (atRiskList.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isDark
                    ? AppColors.cardBorderDark
                    : AppColors.cardBorderLight,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.successColor,
                  size: 22.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    !hasAttendanceData
                        ? context.tr.insufficientAttendanceData
                        : context.tr.noAbsenceAlerts,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5.sp,
                      color: AppColors.successColor,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...atRiskList.map((info) => _buildAtRiskStudentCard(context, info)),
      ],
    );
  }

  Widget _buildAtRiskStudentCard(BuildContext context, AtRiskStudentInfo info) {
    final m = info.makhdom;
    final color = info.isCritical ? AppColors.errorColor : Colors.orange;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.6 : 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Text(
                  m.fullName.isNotEmpty ? m.fullName[0] : context.tr.messageM,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: color,
                    fontSize: 14.sp,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.fullName,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.sp,
                      ),
                    ),
                    if (m.area.isNotEmpty)
                      Text(
                        m.area,
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  context.tr.missedFridaysCount(info.consecutiveAbsences),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 10.5.sp,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (m.phone.isNotEmpty) ...[
                OutlinedButton.icon(
                  onPressed: () => _makeCall(m.phone),
                  icon: Icon(
                    Icons.phone_rounded,
                    size: 14.sp,
                    color: AppColors.successColor,
                  ),
                  label: Text(
                    context.tr.messageCall,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.successColor,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 6.h,
                    ),
                    side: const BorderSide(color: AppColors.successColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                OutlinedButton.icon(
                  onPressed: () => _openWhatsApp(m.phone),
                  icon: FaIcon(
                    FontAwesomeIcons.whatsapp,
                    size: 14.sp,
                    color: Colors.teal,
                  ),
                  label: Text(
                    context.tr.messageWhatsapp,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.teal,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 6.h,
                    ),
                    side: const BorderSide(color: Colors.teal),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
              ],
              ElevatedButton.icon(
                onPressed: () async {
                  await RecordVisitSheet.show(context, makhdom: m);
                  onVisitRecorded?.call();
                },
                icon: Icon(
                  Icons.edit_calendar_rounded,
                  size: 14.sp,
                  color: Colors.white,
                ),
                label: Text(
                  context.tr.messageVisit650,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
