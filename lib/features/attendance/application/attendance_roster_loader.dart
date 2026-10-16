import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/task_model.dart';
import '../../../core/services/attendance_roster_repository.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/session/session_cubit.dart';

class AttendanceRosterLoader {
  static Future<List<AttendanceRosterRow>> load({
    required BuildContext context,
    required TaskModel task,
    required String sessionGrade,
    required bool isDirectSession,
    Future<List<AttendanceRosterRow>> Function(String)? customLoader,
  }) async {
    if (customLoader != null) {
      return customLoader(task.id);
    }
    final session = context.read<SessionCubit>().state;

    if (!isDirectSession &&
        task.id.isNotEmpty &&
        !task.id.startsWith('direct_')) {
      try {
        final all = await AttendanceRosterRepository().load(task.id);
        if (sessionGrade == 'all') return all;
        return all.where((r) => r.grade == sessionGrade).toList();
      } catch (_) {}
    }

    try {
      if (session.isStageAdmin ||
          (session.isGradeAdmin &&
              (session.grade == sessionGrade || sessionGrade == 'all'))) {
        final list = sessionGrade == 'all'
            ? await FirestoreService()
                .getMakhdomeenStream(serviceId: session.serviceId)
                .first
            : await FirestoreService().getMakhdomeenByGrade(
                sessionGrade,
                serviceId: session.serviceId,
              );
        return list
            .where((m) => m.active)
            .map(
              (m) => AttendanceRosterRow(
                id: m.id,
                fullName: m.fullName,
                grade: m.grade,
                active: m.active,
                classId: m.classId,
                className: m.className,
              ),
            )
            .toList();
      } else if (session.userId != null) {
        final list = await FirestoreService()
            .getMakhdomeenForKhademStream(
              session.userId!,
              serviceId: session.serviceId,
            )
            .first;
        return list
            .where((m) =>
                m.active &&
                (sessionGrade == 'all' || m.grade == sessionGrade))
            .map(
              (m) => AttendanceRosterRow(
                id: m.id,
                fullName: m.fullName,
                grade: m.grade,
                active: m.active,
                classId: m.classId,
                className: m.className,
              ),
            )
            .toList();
      }
    } catch (_) {
      return [];
    }
    return [];
  }
}
