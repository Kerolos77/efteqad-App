import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/makhdom_model.dart';

class MakhdomCardActionsBar extends StatelessWidget {
  final MakhdomModel makhdom;
  final bool isDark;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<String> onMakeCall;
  final ValueChanged<String> onOpenWhatsApp;
  final ValueChanged<String?> onOpenLocation;
  final VoidCallback? onLogVisit;
  final VoidCallback onOpenHistory;

  const MakhdomCardActionsBar({
    super.key,
    required this.makhdom,
    required this.isDark,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onMakeCall,
    required this.onOpenWhatsApp,
    required this.onOpenLocation,
    this.onLogVisit,
    required this.onOpenHistory,
  });

  Widget _buildDockButton({
    required dynamic icon,
    String? label,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
    bool isFa = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: label != null ? 10.w : 9.w,
          vertical: 6.h,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isFa)
              FaIcon(icon as IconData, size: 14.sp, color: iconColor)
            else
              Icon(icon as IconData, size: 15.sp, color: iconColor),
            if (label != null) ...[
              SizedBox(width: 5.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: iconColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 14.w,
        vertical: 8.h,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF131D31)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(22.r),
        ),
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.cardBorderDark
                : AppColors.cardBorderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // زر الاتصال المباشر بالمخدوم
                  if (makhdom.phone.isNotEmpty)
                    _buildDockButton(
                      icon: Icons.call,
                      bgColor: AppColors.successColor.withValues(
                        alpha: 0.12,
                      ),
                      iconColor: AppColors.successColor,
                      onTap: () => onMakeCall(makhdom.phone),
                    ),

                  // زر الواتساب
                  if (makhdom.phone.isNotEmpty) ...[
                    SizedBox(width: 6.w),
                    _buildDockButton(
                      icon: FontAwesomeIcons.whatsapp,
                      bgColor: const Color(0xFF25D366).withValues(alpha: 0.12),
                      iconColor: const Color(0xFF25D366),
                      isFa: true,
                      onTap: () => onOpenWhatsApp(makhdom.phone),
                    ),
                  ],

                  // زر اللوكيشن
                  if (makhdom.homeLocationUrl != null &&
                      makhdom.homeLocationUrl!.isNotEmpty) ...[
                    SizedBox(width: 6.w),
                    _buildDockButton(
                      icon: Icons.map_outlined,
                      bgColor: AppColors.primaryLight.withValues(
                        alpha: 0.12,
                      ),
                      iconColor: AppColors.primaryLight,
                      onTap: () => onOpenLocation(makhdom.homeLocationUrl),
                    ),
                  ],

                  // زر تسجيل افتقاد مباشر (إن وُجد)
                  if (onLogVisit != null) ...[
                    SizedBox(width: 6.w),
                    _buildDockButton(
                      icon: Icons.add_task,
                      label: context.tr.visitAction,
                      bgColor: AppColors.accentIndigo.withValues(
                        alpha: 0.14,
                      ),
                      iconColor: AppColors.accentIndigo,
                      onTap: onLogVisit!,
                    ),
                  ],

                  // زر سجل الافتقاد والحضور الشامل
                  SizedBox(width: 6.w),
                  _buildDockButton(
                    icon: Icons.history_edu_rounded,
                    label: context.tr.historyAction,
                    bgColor: AppColors.sacredGold.withValues(
                      alpha: 0.15,
                    ),
                    iconColor: AppColors.sacredGold,
                    onTap: onOpenHistory,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 6.w),

          // زر إظهار/إخفاء التفاصيل
          InkWell(
            onTap: onToggleExpanded,
            borderRadius: BorderRadius.circular(10.r),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 8.w,
                vertical: 4.h,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16.sp,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
