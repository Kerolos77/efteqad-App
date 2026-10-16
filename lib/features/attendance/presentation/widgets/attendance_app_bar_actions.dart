import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../application/attendance_cubit.dart';
import 'attendance_status_badge.dart';

class AttendanceAppBarActions extends StatelessWidget {
  final bool canReopen;
  final bool canFinalize;
  final AttendanceState attendanceState;
  final VoidCallback onReopen;
  final VoidCallback onFinalize;

  const AttendanceAppBarActions({
    super.key,
    required this.canReopen,
    required this.canFinalize,
    required this.attendanceState,
    required this.onReopen,
    required this.onFinalize,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canReopen &&
            attendanceState.isFinalized &&
            attendanceState.hasLoadedRemote)
          IconButton(
            icon: const Icon(Icons.lock_open_rounded),
            tooltip: context.tr.reopenAttendance,
            onPressed: onReopen,
          ),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.35,
          ),
          child: AttendanceStatusBadge(state: attendanceState),
        ),
        if (canFinalize)
          IconButton(
            icon: Icon(Icons.check_circle_outline, size: 22.sp),
            tooltip: context.tr.messageFinalizeAttendance,
            onPressed: onFinalize,
          ),
        SizedBox(width: 4.w),
      ],
    );
  }
}
