import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/services/attendance_analytics_service.dart';
import '../../../common/widgets/record_visit_sheet.dart';

class BehavioralSegmentationSection extends StatelessWidget {
  final BehavioralSegmentation segmentation;
  final List<MakhdomModel> segmentedList;
  final int totalCount;
  final String activeFilter;
  final ValueChanged<String> onFilterChanged;
  final bool isDark;
  final VoidCallback? onVisitRecorded;

  const BehavioralSegmentationSection({
    super.key,
    required this.segmentation,
    required this.segmentedList,
    required this.totalCount,
    required this.activeFilter,
    required this.onFilterChanged,
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

  Widget _buildSegmentTabChip({
    required String label,
    required int count,
    required String key,
    required Color color,
  }) {
    final isSelected = activeFilter == key;

    return InkWell(
      onTap: () => onFilterChanged(key),
      borderRadius: BorderRadius.circular(10.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark
                    ? color.withValues(alpha: 0.15)
                    : color.withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : AppColors.textDark),
              ),
            ),
            SizedBox(width: 6.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w900,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white : color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr.messageBehavioralSegmentation651,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            _buildSegmentTabChip(
              label: context.tr.all,
              count: totalCount,
              key: 'all',
              color: AppColors.primaryLight,
            ),
            _buildSegmentTabChip(
              label: context.tr.segmentConsistent,
              count: segmentation.consistent.length,
              key: 'consistent',
              color: AppColors.successColor,
            ),
            _buildSegmentTabChip(
              label: context.tr.segmentIrregular,
              count: segmentation.irregular.length,
              key: 'irregular',
              color: Colors.orange,
            ),
            _buildSegmentTabChip(
              label: context.tr.segmentAtRisk,
              count: segmentation.atRisk.length,
              key: 'atRisk',
              color: AppColors.errorColor,
            ),
            _buildSegmentTabChip(
              label: context.tr.insufficientAttendanceData,
              count: segmentation.insufficient.length,
              key: 'insufficient',
              color: Colors.blueGrey,
            ),
          ],
        ),
        SizedBox(height: 12.h),
        if (segmentedList.isEmpty)
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Center(
              child: Text(
                context.tr.noSearchResults,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13.sp),
              ),
            ),
          )
        else
          ...segmentedList.map((m) {
            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isDark
                      ? AppColors.cardBorderDark
                      : AppColors.cardBorderLight,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18.r,
                    backgroundColor: AppColors.royalGold.withValues(alpha: 0.15),
                    child: Text(
                      m.fullName.isNotEmpty ? m.fullName[0] : context.tr.messageM,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.royalGold,
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
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (m.phone.isNotEmpty)
                          Text(
                            m.phone,
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else if (m.area.isNotEmpty)
                          Text(
                            m.area,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (m.phone.isNotEmpty) ...[
                        IconButton(
                          onPressed: () => _makeCall(m.phone),
                          icon: Icon(
                            Icons.phone_rounded,
                            size: 18.sp,
                            color: AppColors.successColor,
                          ),
                          visualDensity: VisualDensity.compact,
                          tooltip: context.tr.messageCall,
                        ),
                        IconButton(
                          onPressed: () => _openWhatsApp(m.phone),
                          icon: FaIcon(
                            FontAwesomeIcons.whatsapp,
                            size: 18.sp,
                            color: Colors.teal,
                          ),
                          visualDensity: VisualDensity.compact,
                          tooltip: context.tr.messageWhatsapp,
                        ),
                      ],
                      IconButton(
                        onPressed: () async {
                          await RecordVisitSheet.show(context, makhdom: m);
                          onVisitRecorded?.call();
                        },
                        icon: Icon(
                          Icons.edit_calendar_rounded,
                          size: 18.sp,
                          color: AppColors.primaryLight,
                        ),
                        visualDensity: VisualDensity.compact,
                        tooltip: context.tr.messageVisit650,
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
