import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/models/makhdom_model.dart';
import '../widgets/assign_makhdomeen_modal.dart';
import '../widgets/khodam_card.dart';

class KhodamTab extends StatelessWidget {
  final List<KhademModel> khodam;
  final List<MakhdomModel> allMakhdomeen;

  const KhodamTab({
    super.key,
    required this.khodam,
    required this.allMakhdomeen,
  });

  Future<void> _makeCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) return;
    final url = Uri.parse('tel:$clean');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _openAssignModal(BuildContext context, KhademModel khadem) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AssignMakhdomeenModal(
        targetKhadem: khadem,
        allMakhdomeen: allMakhdomeen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (khodam.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_off_outlined,
                size: 40.sp,
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              context.tr.noKhodamRegisteredYet,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16.sp),
            ),
            SizedBox(height: 6.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Text(
                context.tr.khodamAutoAppearNote,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsetsDirectional.fromSTEB(16.w, 12.h, 16.w, 85.h),
      itemCount: khodam.length,
      itemBuilder: (context, index) {
        final khadem = khodam[index];
        final assignedCount = allMakhdomeen
            .where((m) => m.assignedKhademId == khadem.id)
            .length;
        final visitedCount = allMakhdomeen
            .where((m) => m.assignedKhademId == khadem.id && m.visitCount > 0)
            .length;

        return KhodamCard(
          khadem: khadem,
          assignedCount: assignedCount,
          visitedCount: visitedCount,
          isDark: isDark,
          onCall: () => _makeCall(khadem.phone),
          onAssign: () => _openAssignModal(context, khadem),
        );
      },
    );
  }
}
