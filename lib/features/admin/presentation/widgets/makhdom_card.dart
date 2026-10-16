import 'package:efteqad/core/localization/domain_labels.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/utils/color_generator.dart';
import 'makhdom_card_expanded_details.dart';
import 'makhdom_card_actions_bar.dart';

class MakhdomCard extends StatefulWidget {
  final MakhdomModel makhdom;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onUnassign;
  final VoidCallback? onLogVisit;

  const MakhdomCard({
    super.key,
    required this.makhdom,
    this.onEdit,
    this.onDelete,
    this.onUnassign,
    this.onLogVisit,
  });

  @override
  State<MakhdomCard> createState() => _MakhdomCardState();
}

class _MakhdomCardState extends State<MakhdomCard> {
  bool _isExpanded = false;

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
    final url = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openLocation(String? urlString) async {
    if (urlString == null || urlString.trim().isEmpty) return;
    final url = Uri.parse(urlString.trim());
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildInitialAvatar(MakhdomModel m, Color color) {
    return Center(
      child: Text(
        m.fullName.isNotEmpty ? m.fullName[0] : context.tr.messageM,
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMiniTag(IconData icon, String text, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.5.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.sp, color: AppColors.textMuted),
          SizedBox(width: 4.w),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 130.w),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final makhdom = widget.makhdom;
    final khademColor = ColorGenerator.getColorForId(
      makhdom.assignedKhademId ?? makhdom.assignedKhademName,
    );

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: isDark
              ? AppColors.cardBorderDark
              : AppColors.cardBorderLight,
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.035),
            blurRadius: 16.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22.r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(22.r),
          onTap: () {
            context.push(AppRoutes.makhdomHistory(widget.makhdom.id));
          },
          child: Column(
            children: [
              // القسم الأساسي للكارت
              Padding(
                padding: EdgeInsets.all(15.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الصف العلوي: الصورة + الاسم والشارات + زر المنيو
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // الصورة أو الحرف مع إطار بلون الخادم المسؤول
                        Container(
                          width: 52.w,
                          height: 52.h,
                          decoration: BoxDecoration(
                            color: khademColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(18.r),
                            border: Border.all(
                              color: makhdom.isAssigned
                                  ? khademColor
                                  : (isDark ? Colors.white24 : Colors.black12),
                              width: 2.w,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16.r),
                            child:
                                (makhdom.photoUrl != null &&
                                    makhdom.photoUrl!.isNotEmpty)
                                ? CachedNetworkImage(
                                    imageUrl: makhdom.photoUrl!,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) =>
                                        _buildInitialAvatar(
                                          makhdom,
                                          khademColor,
                                        ),
                                  )
                                : _buildInitialAvatar(makhdom, khademColor),
                          ),
                        ),
                        SizedBox(width: 14.w),

                        // الاسم والتاجات
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                makhdom.fullName,
                                style: TextStyle(
                                  fontSize: 15.5.sp,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 5.h),

                              // التاجات المصغرة (أخوة الرب، المنطقة، المدرسة)
                              Wrap(
                                spacing: 6.w,
                                runSpacing: 4.h,
                                children: [
                                  if (makhdom.isBrethrenOfLord)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 7.w,
                                        vertical: 2.5.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentGold
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6.r),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.star,
                                            size: 10.sp,
                                            color: AppColors.accentGold,
                                          ),
                                          SizedBox(width: 3.w),
                                          Text(
                                            context.tr.brethrenBadge,
                                            style: TextStyle(
                                              fontSize: 10.5.sp,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.accentGold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (makhdom.area.isNotEmpty)
                                    _buildMiniTag(
                                      Icons.location_on_outlined,
                                      makhdom.area,
                                      isDark,
                                    ),
                                  if (makhdom.school.isNotEmpty)
                                    _buildMiniTag(
                                      Icons.school_rounded,
                                      makhdom.school,
                                      isDark,
                                    ),
                                  if (makhdom.age != null)
                                    _buildMiniTag(
                                      Icons.cake_outlined,
                                      context.tr.ageYearsOld(makhdom.age!),
                                      isDark,
                                    ),
                                  if (makhdom.secondaryType.isNotEmpty)
                                    _buildMiniTag(
                                      Icons.category_outlined,
                                      DomainLabels(
                                        Localizations.localeOf(context),
                                      ).secondaryTypeName(
                                        makhdom.secondaryType,
                                        customLabel:
                                            makhdom.secondaryTypeCustomLabel,
                                      ),
                                      isDark,
                                    ),
                                  if (makhdom.className != null &&
                                      makhdom.className!.isNotEmpty)
                                    _buildMiniTag(
                                      Icons.diversity_3_rounded,
                                      makhdom.className!,
                                      isDark,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // زر الخيارات الأنيق
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_horiz,
                            color: isDark
                                ? Colors.white54
                                : AppColors.textMuted,
                            size: 20.sp,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          onSelected: (val) {
                            if (val == 'history') {
                              context.push(
                                AppRoutes.makhdomHistory(widget.makhdom.id),
                              );
                            }
                            if (val == 'edit') widget.onEdit?.call();
                            if (val == 'delete') widget.onDelete?.call();
                            if (val == 'unassign') widget.onUnassign?.call();
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'history',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.history_edu_rounded,
                                    size: 18.sp,
                                    color: AppColors.sacredGold,
                                  ),
                                  SizedBox(width: 10.w),
                                  Text(
                                    context.tr.historyAction,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.onEdit != null)
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 18.sp,
                                      color: AppColors.primaryLight,
                                    ),
                                    SizedBox(width: 10.w),
                                    Text(
                                      context.tr.editDetailsAction,
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (widget.onUnassign != null && makhdom.isAssigned)
                              PopupMenuItem(
                                value: 'unassign',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.person_remove_outlined,
                                      size: 18.sp,
                                      color: AppColors.warningColor,
                                    ),
                                    SizedBox(width: 10.w),
                                    Text(
                                      context.tr.unassignServantAction,
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (widget.onDelete != null)
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      size: 18.sp,
                                      color: AppColors.errorColor,
                                    ),
                                    SizedBox(width: 10.w),
                                    Text(
                                      context.tr.deleteMakhdomAction,
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.errorColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: 12.h),

                    // سطر حالة الخادم والافتقاد
                    Row(
                      children: [
                        // كبسولة الخادم المسؤول
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: khademColor.withValues(
                                alpha: isDark ? 0.2 : 0.1,
                              ),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: khademColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 13.sp,
                                  color: khademColor,
                                ),
                                SizedBox(width: 5.w),
                                Flexible(
                                  child: Text(
                                    makhdom.isAssigned
                                        ? makhdom.assignedKhademName!
                                        : context.tr.unassignedBadge,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w700,
                                      color: makhdom.isAssigned
                                          ? khademColor
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),

                        // حالة الافتقاد
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: makhdom.visitCount > 0
                                ? AppColors.successColor.withValues(
                                    alpha: 0.12,
                                  )
                                : (isDark
                                      ? Colors.white10
                                      : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6.w,
                                height: 6.h,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: makhdom.visitCount > 0
                                      ? AppColors.successColor
                                      : AppColors.warningColor,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                makhdom.visitCount > 0
                                    ? context.tr.visitCountSummary(
                                        makhdom.visitCount,
                                      )
                                    : context.tr.notVisitedYetBadge,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                  color: makhdom.visitCount > 0
                                      ? AppColors.successColor
                                      : (isDark
                                            ? Colors.white70
                                            : AppColors.textMuted),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // قسم التفاصيل الموسعة (العنوان، تليفون الوالدين، الملاحظات)
              if (_isExpanded)
                MakhdomCardExpandedDetails(
                  makhdom: makhdom,
                  isDark: isDark,
                  onMakeCall: _makeCall,
                ),

              // شريط الأزرار السريع السفلي (Modern Action Dock)
              MakhdomCardActionsBar(
                makhdom: makhdom,
                isDark: isDark,
                isExpanded: _isExpanded,
                onToggleExpanded: () => setState(() => _isExpanded = !_isExpanded),
                onMakeCall: _makeCall,
                onOpenWhatsApp: _openWhatsApp,
                onOpenLocation: _openLocation,
                onLogVisit: widget.onLogVisit,
                onOpenHistory: () {
                  context.push(AppRoutes.makhdomHistory(makhdom.id));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
