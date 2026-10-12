import '../../../core/models/task_model.dart';
import '../../../core/session/session_state.dart';

/// Mirrors the trusted attendance operation's current actor and task scope.
bool canManageAttendance(SessionState session, TaskModel task, String? userId) {
  if (!session.isActive ||
      userId == null ||
      session.userId != userId ||
      task.isCompleted ||
      task.dueDate == null ||
      !['attendance_khedma', 'attendance_qoddas'].contains(task.type)) {
    return false;
  }
  if (session.isStageAdmin) return true;
  if (session.isGradeAdmin) return session.grade == task.grade;
  return session.isServant &&
      task.assignedKhademId == userId &&
      (task.grade == 'all' || session.grade == task.grade);
}

/// Allows all active servants and grade admins of the same grade (plus stage admin)
/// to take attendance for their grade in the standalone Attendance system.
bool canManageGradeAttendance(
  SessionState session,
  String grade,
  String? userId,
) {
  if (!session.isActive || userId == null || session.userId != userId) {
    return false;
  }
  if (session.isStageAdmin) return true;
  if (session.isGradeAdmin) return session.grade == grade;
  return session.isServant && (grade == 'all' || session.grade == grade);
}
