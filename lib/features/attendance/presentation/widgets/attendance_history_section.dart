import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/models/attendance_session_model.dart';
import 'attendance_empty_history_card.dart';
import 'attendance_history_tile.dart';

class AttendanceHistorySection extends StatelessWidget {
  final List<AttendanceSessionModel> sessions;
  final bool isLoading;
  final String currentUid;
  final bool isDark;
  final void Function(AttendanceSessionModel) onOpenSession;

  const AttendanceHistorySection({
    super.key,
    required this.sessions,
    required this.isLoading,
    required this.currentUid,
    required this.isDark,
    required this.onOpenSession,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'سجل جلسات الحضور السابقة',
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
        SizedBox(height: 8.h),
        if (isLoading && sessions.isEmpty)
          Padding(
            padding: EdgeInsets.all(24.r),
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (sessions.isEmpty)
          AttendanceEmptyHistoryCard(isDark: isDark)
        else
          ...sessions.take(15).map(
                (s) => AttendanceHistoryTile(
                  session: s,
                  currentUid: currentUid,
                  isDark: isDark,
                  onTap: () => onOpenSession(s),
                ),
              ),
      ],
    );
  }
}
