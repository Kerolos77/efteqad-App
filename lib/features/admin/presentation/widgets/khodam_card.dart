import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/utils/color_generator.dart';

class KhodamCard extends StatelessWidget {
  final KhademModel khadem;
  final int assignedCount;
  final int visitedCount;
  final bool isDark;
  final VoidCallback onCall;
  final VoidCallback onAssign;

  const KhodamCard({
    super.key,
    required this.khadem,
    required this.assignedCount,
    required this.visitedCount,
    required this.isDark,
    required this.onCall,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final color = ColorGenerator.getColorForId(khadem.id);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: isDark
              ? AppColors.cardBorderDark
              : AppColors.cardBorderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.035),
            blurRadius: 14.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // صورة وأيقونة الخادم بلونه الثابت
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: color, width: 2.w),
                ),
                child: Center(
                  child: Text(
                    khadem.name.isNotEmpty
                        ? khadem.name[0]
                        : context.tr.messageS,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 14.w),

              // اسم الخادم والإيميل
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      khadem.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      khadem.email,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // كبسولة عدد المخدومين
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 5.h,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  context.tr.assignedMakhdomeenCount(assignedCount),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // شريط تقدم وإحصائية سريعة للخادم
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6.r),
                  child: LinearProgressIndicator(
                    value: assignedCount > 0
                        ? (visitedCount / assignedCount)
                        : 0,
                    minHeight: 6.h,
                    backgroundColor: isDark
                        ? Colors.white10
                        : const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                context.tr.visitedOfTotalCount(visitedCount, assignedCount),
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // الأزرار التفاعلية
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (khadem.phone.isNotEmpty) ...[
                InkWell(
                  onTap: onCall,
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 7.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successColor.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.call,
                          size: 14.sp,
                          color: AppColors.successColor,
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          context.tr.callAction,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.successColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
              ],
              ElevatedButton.icon(
                onPressed: onAssign,
                icon: Icon(Icons.group_add_outlined, size: 15.sp),
                label: Text(
                  context.tr.assignMakhdomeenActionBtn,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 8.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
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
