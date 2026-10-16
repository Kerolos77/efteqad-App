import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/utils/color_generator.dart';

class GradeMakhdomeenFilterBar extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final Map<String, String> availableClasses;
  final String? selectedClassFilterId;
  final ValueChanged<String?> onClassFilterChanged;
  final String? selectedKhademFilterId;
  final ValueChanged<String?> onKhademFilterChanged;
  final List<MakhdomModel> allMakhdomeen;
  final List<KhademModel> khodamList;
  final KhademModel? currentUser;
  final int myAssignedCount;
  final bool isDark;

  const GradeMakhdomeenFilterBar({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.availableClasses,
    required this.selectedClassFilterId,
    required this.onClassFilterChanged,
    required this.selectedKhademFilterId,
    required this.onKhademFilterChanged,
    required this.allMakhdomeen,
    required this.khodamList,
    required this.currentUser,
    required this.myAssignedCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(16.w, 8.h, 16.w, 12.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      ),
      child: Column(
        children: [
          TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: context.tr.searchAdminHint,
              prefixIcon: Icon(Icons.search_rounded, size: 22.sp),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: 18.sp),
                      onPressed: () => onSearchChanged(''),
                    )
                  : null,
            ),
          ),
          if (availableClasses.isNotEmpty) ...[
            SizedBox(height: 8.h),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildClassFilterChip(
                    context: context,
                    id: null,
                    name: 'كل الفصول',
                    count: allMakhdomeen.length,
                  ),
                  ...availableClasses.entries.map((entry) {
                    final count = allMakhdomeen
                        .where((m) => m.classId == entry.key)
                        .length;
                    return Padding(
                      padding: EdgeInsetsDirectional.only(start: 6.w),
                      child: _buildClassFilterChip(
                        context: context,
                        id: entry.key,
                        name: entry.value,
                        count: count,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
          SizedBox(height: 10.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildKhademFilterChip(
                  context: context,
                  id: null,
                  name: context.tr.all,
                  count: allMakhdomeen.length,
                  color: AppColors.primaryLight,
                ),
                if (currentUser != null && myAssignedCount > 0) ...[
                  SizedBox(width: 8.w),
                  _buildKhademFilterChip(
                    context: context,
                    id: currentUser!.id,
                    name: '⭐ ${context.tr.filterMyMakhdomeen}',
                    count: myAssignedCount,
                    color: AppColors.accentIndigo,
                  ),
                ],
                SizedBox(width: 8.w),
                _buildKhademFilterChip(
                  context: context,
                  id: 'unassigned',
                  name: context.tr.filterUnassigned,
                  count: allMakhdomeen.where((m) => !m.isAssigned).length,
                  color: AppColors.errorColor,
                ),
                SizedBox(width: 8.w),
                _buildKhademFilterChip(
                  context: context,
                  id: 'brethren',
                  name: context.tr.filterBrethren,
                  count: allMakhdomeen.where((m) => m.isBrethrenOfLord).length,
                  color: AppColors.accentGold,
                ),
                SizedBox(width: 8.w),
                ...khodamList
                    .where(
                      (k) => k.id != currentUser?.id || myAssignedCount == 0,
                    )
                    .map((khadem) {
                      final count = allMakhdomeen
                          .where((m) => m.assignedKhademId == khadem.id)
                          .length;
                      return Padding(
                        padding: EdgeInsetsDirectional.only(start: 8.w),
                        child: _buildKhademFilterChip(
                          context: context,
                          id: khadem.id,
                          name: khadem.name,
                          count: count,
                          color: ColorGenerator.getColorForId(khadem.id),
                        ),
                      );
                    }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKhademFilterChip({
    required BuildContext context,
    required String? id,
    required String name,
    required int count,
    required Color color,
  }) {
    final isSelected = selectedKhademFilterId == id;

    return GestureDetector(
      onTap: () => onKhademFilterChanged(isSelected ? null : id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark
                      ? AppColors.cardBorderDark
                      : AppColors.cardBorderLight),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : AppColors.textDark),
              ),
            ),
            SizedBox(width: 6.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                AppFormatters(
                  Localizations.localeOf(context),
                ).formatNumber(count),
                style: TextStyle(
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassFilterChip({
    required BuildContext context,
    required String? id,
    required String name,
    required int count,
  }) {
    final isSelected = selectedClassFilterId == id;

    return GestureDetector(
      onTap: () => onClassFilterChanged(isSelected ? null : id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.sacredGold
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected
                ? AppColors.sacredGold
                : (isDark
                      ? AppColors.cardBorderDark
                      : AppColors.cardBorderLight),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.diversity_3_rounded,
              size: 13.sp,
              color: isSelected
                  ? Colors.black87
                  : (isDark ? Colors.white60 : AppColors.textMuted),
            ),
            SizedBox(width: 4.w),
            Text(
              name,
              style: TextStyle(
                fontSize: 11.5.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? Colors.black87
                    : (isDark ? Colors.white70 : AppColors.textDark),
              ),
            ),
            SizedBox(width: 5.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.black.withValues(alpha: 0.12)
                    : AppColors.sacredGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                AppFormatters(
                  Localizations.localeOf(context),
                ).formatNumber(count),
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.black87 : AppColors.sacredGold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
