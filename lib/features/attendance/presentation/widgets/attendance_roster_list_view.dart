import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/attendance_session_model.dart';
import '../../../../core/services/attendance_roster_repository.dart';
import '../../application/attendance_cubit.dart';
import 'attendance_empty_view.dart';
import 'attendance_roster_card.dart';

class AttendanceRosterListView extends StatelessWidget {
  final List<AttendanceRosterRow> filteredList;
  final AttendanceState attendanceState;
  final bool canEdit;
  final String sessionType;
  final String Function(String) getGradeLabel;
  final void Function(AttendanceRosterRow, bool) onToggleAttendance;
  final void Function(AttendanceRosterRow, AttendanceExcuse?) onExcuseTap;
  final bool isDark;

  const AttendanceRosterListView({
    super.key,
    required this.filteredList,
    required this.attendanceState,
    required this.canEdit,
    required this.sessionType,
    required this.getGradeLabel,
    required this.onToggleAttendance,
    required this.onExcuseTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (filteredList.isEmpty) {
      return AttendanceEmptyView(
        icon: Icons.search_off_rounded,
        title: context.tr.noSearchResults,
        isDark: isDark,
      );
    }

    return ListView.builder(
      padding: EdgeInsetsDirectional.fromSTEB(16.w, 0, 16.w, 16.h),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final makhdom = filteredList[index];
        final isAttended = attendanceState.isAttended(makhdom.id);
        final excuse = attendanceState.excuseFor(makhdom.id);
        final isPending = attendanceState.isPending(makhdom.id);
        final hasError = attendanceState.hasError(makhdom.id);

        return AttendanceRosterCard(
          makhdom: makhdom,
          isAttended: isAttended,
          excuse: excuse,
          isPending: isPending,
          hasError: hasError,
          isDark: isDark,
          isAuthorized: canEdit,
          sessionType: sessionType,
          gradeLabel: getGradeLabel(makhdom.grade),
          onToggleAttendance: (val) => onToggleAttendance(makhdom, val),
          onExcuseTap: () => onExcuseTap(makhdom, excuse),
          onErrorTap: () {
            final err = attendanceState.saveErrors[makhdom.id];
            if (err != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppFailure.fromException(err).localizedMessage(context.tr),
                  ),
                  backgroundColor: AppColors.errorColor,
                ),
              );
            }
          },
        );
      },
    );
  }
}
