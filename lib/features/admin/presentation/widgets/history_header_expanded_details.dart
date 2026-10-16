import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/makhdom_model.dart';

class HistoryHeaderExpandedDetails extends StatelessWidget {
  final MakhdomModel makhdom;
  final bool isDark;
  final ValueChanged<String> onCall;
  final ValueChanged<String> onWhatsApp;
  final void Function(String text, String label) onCopy;

  const HistoryHeaderExpandedDetails({
    super.key,
    required this.makhdom,
    required this.isDark,
    required this.onCall,
    required this.onWhatsApp,
    required this.onCopy,
  });

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

  Widget _buildDetailRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    String? copyValue,
    Color? iconColor,
    VoidCallback? onCallTap,
    VoidCallback? onWhatsAppTap,
  }) {
    final effectiveColor = iconColor ?? AppColors.sacredGold;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16.sp, color: effectiveColor),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              '$label: ',
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textDirection: onCallTap != null ? TextDirection.ltr : null,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onCallTap != null) ...[
            SizedBox(width: 4.w),
            _buildQuickActionIconButton(
              icon: Icon(Icons.call_rounded, size: 14.sp),
              color: AppColors.successColor,
              tooltip: context.tr.callAction,
              isDark: isDark,
              onPressed: onCallTap,
            ),
          ],
          if (onWhatsAppTap != null) ...[
            SizedBox(width: 4.w),
            _buildQuickActionIconButton(
              icon: FaIcon(FontAwesomeIcons.whatsapp, size: 14.sp),
              color: const Color(0xFF25D366),
              tooltip: context.tr.whatsappAction,
              isDark: isDark,
              onPressed: onWhatsAppTap,
            ),
          ],
          if (copyValue != null && copyValue.isNotEmpty) ...[
            SizedBox(width: 4.w),
            IconButton(
              icon: Icon(Icons.copy_rounded, size: 15.sp),
              tooltip: context.tr.copyPhoneAction,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(minWidth: 28.w, minHeight: 28.h),
              onPressed: () => onCopy(copyValue, label),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 24.h),
        if (makhdom.phone.isNotEmpty)
          _buildDetailRow(
            context: context,
            icon: Icons.phone_android_rounded,
            label: context.tr.makhdomPhoneLabel,
            value: makhdom.phone,
            copyValue: makhdom.phone,
            iconColor: AppColors.successColor,
          ),
        if (makhdom.fatherPhone.isNotEmpty)
          _buildDetailRow(
            context: context,
            icon: Icons.phone_iphone_rounded,
            label: context.tr.fatherPhoneLabel,
            value: makhdom.fatherPhone,
            copyValue: makhdom.fatherPhone,
            iconColor: AppColors.accentBlue,
            onCallTap: () => onCall(makhdom.fatherPhone),
            onWhatsAppTap: () => onWhatsApp(makhdom.fatherPhone),
          ),
        if (makhdom.motherPhone.isNotEmpty)
          _buildDetailRow(
            context: context,
            icon: Icons.phone_iphone_rounded,
            label: context.tr.motherPhoneLabel,
            value: makhdom.motherPhone,
            copyValue: makhdom.motherPhone,
            iconColor: Colors.purpleAccent,
            onCallTap: () => onCall(makhdom.motherPhone),
            onWhatsAppTap: () => onWhatsApp(makhdom.motherPhone),
          ),
        if (makhdom.address.isNotEmpty)
          _buildDetailRow(
            context: context,
            icon: Icons.home_rounded,
            label: context.tr.addressLabel,
            value: makhdom.address,
            copyValue: makhdom.address,
            iconColor: AppColors.primaryLight,
          ),
        if (makhdom.school.isNotEmpty)
          _buildDetailRow(
            context: context,
            icon: Icons.business_rounded,
            label: context.tr.schoolLabel,
            value: makhdom.school,
            iconColor: Colors.teal,
          ),
        if (makhdom.assignedKhademName != null &&
            makhdom.assignedKhademName!.isNotEmpty)
          _buildDetailRow(
            context: context,
            icon: Icons.badge_rounded,
            label: context.tr.assignedKhademLabel,
            value: makhdom.assignedKhademName!,
            iconColor: AppColors.sacredGold,
          ),
        if (makhdom.notes != null && makhdom.notes!.isNotEmpty) ...[
          SizedBox(height: 10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey.shade300,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.sticky_note_2_outlined,
                      size: 15.sp,
                      color: AppColors.sacredGold,
                    ),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        context.tr.generalNotesTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  makhdom.notes!,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    height: 1.4,
                    color: isDark ? Colors.white70 : AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
