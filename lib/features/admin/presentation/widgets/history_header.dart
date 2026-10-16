import '../../../../core/localization/app_formatters.dart';
import 'package:efteqad/core/localization/domain_labels.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/makhdom_model.dart';
import 'history_header_expanded_details.dart';

class HistoryHeader extends StatelessWidget {
  final MakhdomModel makhdom;
  final String? latestVisitNotes;
  final bool isDark;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<String> onCall;
  final ValueChanged<String> onWhatsApp;
  final ValueChanged<String?> onOpenLocation;
  final void Function(String text, String label) onCopy;

  const HistoryHeader({
    super.key,
    required this.makhdom,
    this.latestVisitNotes,
    required this.isDark,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onCall,
    required this.onWhatsApp,
    required this.onOpenLocation,
    required this.onCopy,
  });

  Widget _buildInitialAvatarText(MakhdomModel makhdom) {
    final initials = makhdom.fullName.isNotEmpty
        ? makhdom.fullName
              .trim()
              .split(' ')
              .take(2)
              .map((e) => e.isNotEmpty ? e[0] : '')
              .join()
        : '?';
    return Container(
      color: AppColors.sacredGold.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 22.sp,
          fontWeight: FontWeight.w900,
          color: AppColors.sacredGold,
        ),
      ),
    );
  }

  Widget _buildHeaderBadge({
    required IconData icon,
    required String text,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: color),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionIconButton({
    required Widget icon,
    required Color color,
    required String tooltip,
    required bool isDark,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            width: 38.w,
            height: 38.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1.w,
              ),
            ),
            child: IconTheme(
              data: IconThemeData(color: color, size: 18.sp),
              child: icon,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsetsDirectional.fromSTEB(16.w, 12.h, 16.w, 12.h),
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark
              ? AppColors.cardBorderDark
              : AppColors.cardBorderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 18.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // سطر الهوية: الصورة الشخصية والاسم والوسامات
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 62.w,
                height: 62.h,
                decoration: BoxDecoration(
                  color: AppColors.sacredGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.sacredGold, width: 2.w),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.sacredGold.withValues(alpha: 0.2),
                      blurRadius: 8.r,
                      offset: Offset(0, 3.h),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18.r),
                  child:
                      (makhdom.photoUrl != null && makhdom.photoUrl!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: makhdom.photoUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              _buildInitialAvatarText(makhdom),
                        )
                      : _buildInitialAvatarText(makhdom),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      makhdom.fullName,
                      style: TextStyle(
                        fontSize: 17.5.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppColors.textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 5.h,
                      children: [
                        _buildHeaderBadge(
                          icon: Icons.school_rounded,
                          text: DomainLabels(
                            Localizations.localeOf(context),
                          ).gradeName(makhdom.grade),
                          color: AppColors.primaryLight,
                          isDark: isDark,
                        ),
                        if (makhdom.isBrethrenOfLord)
                          _buildHeaderBadge(
                            icon: Icons.star_rounded,
                            text: context.tr.brethrenBadge,
                            color: AppColors.accentGold,
                            isDark: isDark,
                          ),
                        if (makhdom.assignedKhademName != null &&
                            makhdom.assignedKhademName!.isNotEmpty)
                          _buildHeaderBadge(
                            icon: Icons.person_rounded,
                            text: makhdom.assignedKhademName!,
                            color: AppColors.sacredGold,
                            isDark: isDark,
                          )
                        else
                          _buildHeaderBadge(
                            icon: Icons.person_off_rounded,
                            text: context.tr.unassignedBadge,
                            color: isDark
                                ? Colors.white54
                                : AppColors.textMuted,
                            isDark: isDark,
                          ),
                        if (makhdom.age != null)
                          _buildHeaderBadge(
                            icon: Icons.cake_outlined,
                            text: context.tr.ageYearsOld(makhdom.age!),
                            color: Colors.pinkAccent,
                            isDark: isDark,
                          ),
                        if (makhdom.area.isNotEmpty)
                          _buildHeaderBadge(
                            icon: Icons.location_on_outlined,
                            text: makhdom.area,
                            color: AppColors.accentBlue,
                            isDark: isDark,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            !makhdom.hasKnownTrackingOrigin
                ? context.tr.trackingOriginUnknown
                : makhdom.isTrackingEstimated
                ? context.tr.trackingStartEstimatedLabel(
                    AppFormatters(
                      Localizations.localeOf(context),
                    ).formatDate(makhdom.effectiveTrackingStartDate),
                  )
                : context.tr.trackingStartLabel(
                    AppFormatters(
                      Localizations.localeOf(context),
                    ).formatDate(makhdom.effectiveTrackingStartDate),
                  ),
            style: TextStyle(
              fontSize: 12.sp,
              color: isDark ? Colors.white60 : AppColors.textMuted,
            ),
          ),
          if (latestVisitNotes != null && latestVisitNotes!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr.visitReportLabel,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.sacredGold,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    latestVisitNotes!,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      color: isDark ? Colors.white70 : AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          if (makhdom.legacyNotes != null && makhdom.legacyNotes!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr.legacyNotesLabel,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    makhdom.legacyNotes!,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      color: isDark ? Colors.white70 : AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 16.h),

          // أزرار التواصل السريع وزر التوسيع
          Row(
            children: [
              if (makhdom.phone.isNotEmpty) ...[
                _buildQuickActionIconButton(
                  icon: Icon(Icons.call_rounded, size: 18.sp),
                  color: AppColors.successColor,
                  tooltip: context.tr.callAction,
                  isDark: isDark,
                  onPressed: () => onCall(makhdom.phone),
                ),
                SizedBox(width: 6.w),
                _buildQuickActionIconButton(
                  icon: FaIcon(FontAwesomeIcons.whatsapp, size: 18.sp),
                  color: const Color(0xFF25D366),
                  tooltip: context.tr.whatsappAction,
                  isDark: isDark,
                  onPressed: () => onWhatsApp(makhdom.phone),
                ),
                SizedBox(width: 6.w),
              ],
              if (makhdom.homeLocationUrl != null &&
                  makhdom.homeLocationUrl!.isNotEmpty) ...[
                _buildQuickActionIconButton(
                  icon: Icon(Icons.map_outlined, size: 18.sp),
                  color: AppColors.primaryLight,
                  tooltip: context.tr.mapAction,
                  isDark: isDark,
                  onPressed: () => onOpenLocation(makhdom.homeLocationUrl),
                ),
                SizedBox(width: 6.w),
              ],
              const Spacer(),
              Flexible(
                child: InkWell(
                  onTap: onToggleExpanded,
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.sacredGold.withValues(
                        alpha: isDark ? 0.15 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: AppColors.sacredGold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18.sp,
                          color: AppColors.sacredGold,
                        ),
                        SizedBox(width: 4.w),
                        Flexible(
                          child: Text(
                            isExpanded
                                ? context.tr.hideDetailsAction
                                : context.tr.allDetailsAction,
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w900,
                              color: AppColors.sacredGold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // التفاصيل الموسعة
          if (isExpanded)
            HistoryHeaderExpandedDetails(
              makhdom: makhdom,
              isDark: isDark,
              onCall: onCall,
              onWhatsApp: onWhatsApp,
              onCopy: onCopy,
            ),
        ],
      ),
    );
  }
}
