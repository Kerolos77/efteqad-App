import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:efteqad/core/localization/app_formatters.dart';
import 'package:efteqad/core/localization/domain_labels.dart';
import 'package:efteqad/core/services/trusted_mutations.dart'
    show canonicalVisitType;
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/visit_model.dart';
import '../../models/history_analysis.dart';

class HistoryVisitTimelineCard extends StatelessWidget {
  final VisitWithImpact item;
  final bool isDark;
  final ValueChanged<VisitModel> onEditVisitNotes;

  const HistoryVisitTimelineCard({
    super.key,
    required this.item,
    required this.isDark,
    required this.onEditVisitNotes,
  });

  @override
  Widget build(BuildContext context) {
    final displayDateFormat = AppFormatters(Localizations.localeOf(context));
    final visit = item.visit;
    final dateStr = displayDateFormat.formatDate(
      visit.visitDate,
      format: 'EEEE d MMMM yyyy',
    );

    Color typeColor;
    IconData typeIcon;
    final typeLabel = visit.visitType.isNotEmpty
        ? DomainLabels(
            Localizations.localeOf(context),
          ).visitTypeName(visit.visitType)
        : context.tr.pastoralVisitGeneral;

    final typeCode = canonicalVisitType(visit.visitType);
    if (typeCode == 'home') {
      typeColor = const Color(0xFF059669);
      typeIcon = Icons.home_work_rounded;
    } else if (typeCode == 'phone') {
      typeColor = const Color(0xFF2563EB);
      typeIcon = Icons.phone_in_talk_rounded;
    } else if (typeCode == 'church') {
      typeColor = const Color(0xFF7C3AED);
      typeIcon = Icons.church_rounded;
    } else {
      typeColor = AppColors.sacredGold;
      typeIcon = Icons.volunteer_activism_rounded;
    }

    Color outcomeColor = AppColors.textMuted;
    String outcomeText = '';
    IconData outcomeIcon = Icons.help_outline_rounded;

    switch (item.outcome) {
      case VisitFridayOutcome.both:
        outcomeColor = AppColors.successColor;
        outcomeText = context.tr.visitOutcomeBoth;
        outcomeIcon = Icons.stars_rounded;
        break;
      case VisitFridayOutcome.serviceOnly:
        outcomeColor = const Color(0xFF10B981);
        outcomeText = context.tr.visitOutcomeServiceOnly;
        outcomeIcon = Icons.check_circle_rounded;
        break;
      case VisitFridayOutcome.massOnly:
        outcomeColor = const Color(0xFF10B981);
        outcomeText = context.tr.visitOutcomeMassOnly;
        outcomeIcon = Icons.check_circle_rounded;
        break;
      case VisitFridayOutcome.missed:
        outcomeColor = AppColors.errorColor;
        outcomeText = context.tr.visitOutcomeMissed;
        outcomeIcon = Icons.error_outline_rounded;
        break;
      case VisitFridayOutcome.pending:
        outcomeColor = AppColors.sacredGold;
        outcomeText = context.tr.visitOutcomePending;
        outcomeIcon = Icons.hourglass_top_rounded;
        break;
      case VisitFridayOutcome.noData:
        outcomeColor = AppColors.textMuted;
        outcomeText = context.tr.visitOutcomeNoData;
        outcomeIcon = Icons.help_outline_rounded;
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: typeColor.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 14.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس الكارت
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20.r),
              ),
              border: Border(
                bottom: BorderSide(
                  color: typeColor.withValues(alpha: isDark ? 0.2 : 0.12),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor,
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [
                      BoxShadow(
                        color: typeColor.withValues(alpha: 0.3),
                        blurRadius: 6.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(typeIcon, size: 14.sp, color: Colors.white),
                      SizedBox(width: 5.w),
                      Flexible(
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 15.sp,
                        color: typeColor,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          dateStr,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.sp,
                            color: isDark
                                ? Colors.white
                                : AppColors.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الخادم القائم بالافتقاد
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(4.r),
                      decoration: BoxDecoration(
                        color: AppColors.sacredGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.person_pin_rounded,
                        size: 16.sp,
                        color: AppColors.sacredGold,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Flexible(
                      child: Text(
                        context.tr.visitingServantLabel,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white60
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        visit.khademName.isNotEmpty
                            ? visit.khademName
                            : context.tr.assignedKhademPlaceholder,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // تقرير وملاحظات الافتقاد
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.25)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: isDark
                          ? AppColors.cardBorderDark
                          : AppColors.cardBorderLight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            size: 17.sp,
                            color: typeColor,
                          ),
                          SizedBox(width: 6.w),
                          Flexible(
                            child: Text(
                              context.tr.visitReportNotesHeader,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w800,
                                color: typeColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () => onEditVisitNotes(visit),
                            borderRadius: BorderRadius.circular(8.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 3.h,
                              ),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit_rounded,
                                    size: 12.sp,
                                    color: typeColor,
                                  ),
                                  SizedBox(width: 4.w),
                                  Flexible(
                                    child: Text(
                                      (visit.notes != null &&
                                              visit.notes!.trim().isNotEmpty)
                                          ? context.tr.editNoteAction
                                          : context.tr.addNoteAction,
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w800,
                                        color: typeColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      if (visit.notes != null && visit.notes!.trim().isNotEmpty)
                        Text(
                          visit.notes!,
                          style: TextStyle(
                            fontSize: 13.sp,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : AppColors.textDark,
                          ),
                        )
                      else
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 14.sp,
                              color: AppColors.textMuted,
                            ),
                            SizedBox(width: 6.w),
                            Flexible(
                              child: Text(
                                context.tr.visitNoDetailedNotes,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.textMuted,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),

                // أثر الافتقاد في الجمعة التالية
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: outcomeColor.withValues(alpha: isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: outcomeColor.withValues(alpha: isDark ? 0.3 : 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: outcomeColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          outcomeIcon,
                          size: 16.sp,
                          color: outcomeColor,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr.visitOutcomeHeader(
                                item.nextFridayFormatted,
                              ),
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white60
                                    : AppColors.textMuted,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              outcomeText,
                              style: TextStyle(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w800,
                                color: outcomeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
