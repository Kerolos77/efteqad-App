import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/models/attendance_session_model.dart';
import 'attendance_session_card.dart';

class AttendanceActiveSessionsSection extends StatelessWidget {
  final AttendanceSessionModel? todayKhedma;
  final AttendanceSessionModel? todayQoddas;
  final String currentUid;
  final bool isDark;
  final VoidCallback onOpenKhedma;
  final VoidCallback onOpenQoddas;

  const AttendanceActiveSessionsSection({
    super.key,
    required this.todayKhedma,
    required this.todayQoddas,
    required this.currentUid,
    required this.isDark,
    required this.onOpenKhedma,
    required this.onOpenQoddas,
  });

  @override
  Widget build(BuildContext context) {
    final khedmaCard = AttendanceSessionCard(
      title: 'حضور اجتماع الخدمة',
      subtitle: 'رصد حضور المخدومين وأعذار الغياب في اجتماع الخدمة',
      icon: Icons.fact_check_rounded,
      accentColor: const Color(0xFF8B5CF6),
      sessionType: 'khedma',
      session: todayKhedma,
      currentUid: currentUid,
      isDark: isDark,
      onOpen: onOpenKhedma,
    );

    final qoddasCard = AttendanceSessionCard(
      title: 'حضور القداس الإلهي',
      subtitle: 'رصد حضور المخدومين وأعذار الغياب في القداس',
      icon: Icons.church_rounded,
      accentColor: AppColors.accentGold,
      sessionType: 'qoddas',
      session: todayQoddas,
      currentUid: currentUid,
      isDark: isDark,
      onOpen: onOpenQoddas,
    );

    final isWide = MediaQuery.sizeOf(context).width >= 800;

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: khedmaCard),
          SizedBox(width: 14.w),
          Expanded(child: qoddasCard),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        khedmaCard,
        SizedBox(height: 10.h),
        qoddasCard,
      ],
    );
  }
}
