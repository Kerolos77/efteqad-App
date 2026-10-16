import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/attendance_session_model.dart';
import '../../../core/repositories/attendance_repository.dart';
import '../../../core/services/attendance_roster_repository.dart';
import '../presentation/widgets/attendance_excuse_dialog.dart';
import '../presentation/widgets/attendance_finalize_dialog.dart';
import '../presentation/widgets/attendance_reopen_dialog.dart';
import 'attendance_cubit.dart';

class AttendanceActionHandler {
  final BuildContext context;
  final AttendanceCubit cubit;
  final String currentUid;
  final String? taskId;

  const AttendanceActionHandler({
    required this.context,
    required this.cubit,
    required this.currentUid,
    this.taskId,
  });

  Future<void> reopenAttendance({
    required String sessionId,
    required String sessionGrade,
    required AttendanceRepository repository,
  }) async {
    await AttendanceReopenDialog.show(
      context,
      sessionId: sessionId,
      sessionGrade: sessionGrade,
      repository: repository,
    );
  }

  Future<void> toggleAttendance(
    AttendanceRosterRow makhdom,
    bool isPresent,
  ) async {
    if (cubit.state.isLockedByOther(currentUid)) {
      final holder = cubit.state.lockedByKhademName ?? 'خادم آخر';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يقوم حالياً $holder برصد الغياب لهذه الفرقة.'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    if (cubit.state.isFinalized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr.messageThisSessionHasBeenFinalizedAndCannot),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    try {
      await cubit.setPresence(
        makhdomId: makhdom.id,
        isPresent: isPresent,
      );
      if (context.mounted && cubit.state.saveErrors.containsKey(makhdom.id)) {
        final err = cubit.state.saveErrors[makhdom.id];
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
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppFailure.fromException(e).localizedMessage(context.tr),
            ),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> showExcuseDialog(
    AttendanceRosterRow makhdom,
    AttendanceExcuse? existingExcuse,
  ) async {
    final result = await AttendanceExcuseDialog.show(
      context,
      studentName: makhdom.fullName,
      existingExcuse: existingExcuse,
    );

    if (result == null || !context.mounted) return;
    try {
      await cubit.setExcuse(
        makhdomId: makhdom.id,
        note: result == '__CLEAR__' ? null : result,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppFailure.fromException(e).localizedMessage(context.tr),
            ),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> finalizeAttendance() async {
    if (cubit.state.pendingById.isNotEmpty ||
        cubit.state.pendingExcusesById.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr.messagePleaseWaitForPendingSavesToFinish),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    final confirmed = await AttendanceFinalizeDialog.show(context);

    if (confirmed == true && context.mounted) {
      try {
        await cubit.finalizeAttendance(taskId: taskId);
        await cubit.releaseLock();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr.messageAttendanceFinalizedSuccessfully),
              backgroundColor: AppColors.successColor,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppFailure.fromException(e).localizedMessage(context.tr),
              ),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
      }
    }
  }
}
