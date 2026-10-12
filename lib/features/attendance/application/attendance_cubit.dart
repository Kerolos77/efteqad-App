import 'package:efteqad/core/errors/app_failure.dart';
import 'dart:async';
import '../../../core/services/trusted_mutations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/attendance_session_model.dart';
import '../../../core/repositories/attendance_repository.dart';

const Object _unset = Object();

class AttendanceState {
  final Set<String> remoteIds;
  final Map<String, AttendanceExcuse> remoteExcuses;
  final Map<String, bool> pendingById;
  final Map<String, AttendanceExcuse?> pendingExcusesById;
  final Map<String, Object> saveErrors;
  final Map<String, bool> failedIntentById;
  final String status; // 'idle', 'saving', 'finalizing', 'finalized', 'error'
  final bool isFinalized;
  final bool hasLoadedRemote;
  final String? lockedByKhademId;
  final String? lockedByKhademName;
  final DateTime? lockExpiresAt;

  const AttendanceState({
    this.remoteIds = const {},
    this.remoteExcuses = const {},
    this.pendingById = const {},
    this.pendingExcusesById = const {},
    this.saveErrors = const {},
    this.failedIntentById = const {},
    this.status = 'idle',
    this.isFinalized = false,
    this.hasLoadedRemote = false,
    this.lockedByKhademId,
    this.lockedByKhademName,
    this.lockExpiresAt,
  });

  bool isAttended(String makhdomId) {
    if (pendingById.containsKey(makhdomId)) {
      return pendingById[makhdomId]!;
    }
    if (failedIntentById.containsKey(makhdomId)) {
      return failedIntentById[makhdomId]!;
    }
    return remoteIds.contains(makhdomId);
  }

  AttendanceExcuse? excuseFor(String makhdomId) {
    if (pendingExcusesById.containsKey(makhdomId)) {
      return pendingExcusesById[makhdomId];
    }
    return remoteExcuses[makhdomId];
  }

  bool isExcused(String makhdomId) =>
      !isAttended(makhdomId) && excuseFor(makhdomId) != null;

  bool isPending(String makhdomId) =>
      pendingById.containsKey(makhdomId) ||
      pendingExcusesById.containsKey(makhdomId);
  bool hasError(String makhdomId) => saveErrors.containsKey(makhdomId);

  bool isLockedByOther(String currentKhademId, {DateTime? now}) {
    if (lockedByKhademId == null || lockedByKhademId!.isEmpty) return false;
    if (lockedByKhademId == currentKhademId) return false;
    if (lockExpiresAt == null) return false;
    return lockExpiresAt!.isAfter(now ?? DateTime.now());
  }

  Set<String> get effectiveAttendedIds {
    final set = Set<String>.from(remoteIds);
    pendingById.forEach((id, isPresent) {
      if (isPresent) {
        set.add(id);
      } else {
        set.remove(id);
      }
    });
    failedIntentById.forEach((id, present) {
      if (present) {
        set.add(id);
      } else {
        set.remove(id);
      }
    });
    return set;
  }

  Set<String> get effectiveExcusedIds {
    final candidates = <String>{
      ...remoteExcuses.keys,
      ...pendingExcusesById.keys,
    };
    return candidates.where(isExcused).toSet();
  }

  int get attendedCount => effectiveAttendedIds.length;
  int get excusedCount => effectiveExcusedIds.length;

  AttendanceState copyWith({
    Set<String>? remoteIds,
    Map<String, AttendanceExcuse>? remoteExcuses,
    Map<String, bool>? pendingById,
    Map<String, AttendanceExcuse?>? pendingExcusesById,
    Map<String, Object>? saveErrors,
    Map<String, bool>? failedIntentById,
    String? status,
    bool? isFinalized,
    bool? hasLoadedRemote,
    Object? lockedByKhademId = _unset,
    Object? lockedByKhademName = _unset,
    Object? lockExpiresAt = _unset,
  }) {
    return AttendanceState(
      remoteIds: remoteIds ?? this.remoteIds,
      remoteExcuses: remoteExcuses ?? this.remoteExcuses,
      pendingById: pendingById ?? this.pendingById,
      pendingExcusesById: pendingExcusesById ?? this.pendingExcusesById,
      saveErrors: saveErrors ?? this.saveErrors,
      failedIntentById: failedIntentById ?? this.failedIntentById,
      status: status ?? this.status,
      isFinalized: isFinalized ?? this.isFinalized,
      hasLoadedRemote: hasLoadedRemote ?? this.hasLoadedRemote,
      lockedByKhademId: identical(lockedByKhademId, _unset)
          ? this.lockedByKhademId
          : lockedByKhademId as String?,
      lockedByKhademName: identical(lockedByKhademName, _unset)
          ? this.lockedByKhademName
          : lockedByKhademName as String?,
      lockExpiresAt: identical(lockExpiresAt, _unset)
          ? this.lockExpiresAt
          : lockExpiresAt as DateTime?,
    );
  }
}

class AttendanceCubit extends Cubit<AttendanceState> {
  final AttendanceRepository _repository;
  final String sessionId;
  final String grade;
  final String date;
  final String type;
  final String khademId;
  final String khademName;
  final String? taskId;
  final String Function() _userId;

  StreamSubscription<AttendanceSessionModel?>? _sessionSubscription;
  Timer? _heartbeatTimer;
  final Map<String, int> _sequences = {};
  final Map<String, Future<void>> _queues = {};
  final Map<String, String> _failedOperations = {};
  final Set<String> _markedPresentInThisSession = {};

  AttendanceCubit({
    required AttendanceRepository repository,
    required this.sessionId,
    required this.grade,
    required this.date,
    required this.type,
    required this.khademId,
    required this.khademName,
    this.taskId,
    String Function()? userId,
  }) : _userId = userId ?? (() => khademId),
       _repository = repository,
       super(const AttendanceState()) {
    _initSessionSubscription();
  }

  void _initSessionSubscription() {
    _sessionSubscription = _repository
        .watchGradeSession(
          sessionId: sessionId,
          grade: grade,
          taskId: taskId,
          expectedUid: khademId,
        )
        .listen(
          (session) {
            if (isClosed || _userId() != khademId) return;
            if (session != null) {
              emit(
                state.copyWith(
                  remoteIds: Set<String>.from(session.attendedMakhdomIds),
                  remoteExcuses: Map<String, AttendanceExcuse>.from(
                    session.excuses,
                  ),
                  isFinalized: session.isFinalized,
                  status: session.isFinalized
                      ? 'finalized'
                      : (state.pendingById.isEmpty &&
                                state.pendingExcusesById.isEmpty
                            ? 'idle'
                            : 'saving'),
                  hasLoadedRemote: true,
                  lockedByKhademId: session.lockedByKhademId,
                  lockedByKhademName: session.lockedByKhademName,
                  lockExpiresAt: session.lockExpiresAt,
                ),
              );
            } else {
              emit(
                state.copyWith(
                  remoteIds: const {},
                  remoteExcuses: const {},
                  isFinalized: false,
                  hasLoadedRemote: true,
                  status:
                      state.pendingById.isEmpty &&
                          state.pendingExcusesById.isEmpty
                      ? 'idle'
                      : 'saving',
                  lockedByKhademId: null,
                  lockedByKhademName: null,
                  lockExpiresAt: null,
                ),
              );
            }
          },
          onError: (error) {
            if (isClosed || _userId() != khademId) return;
            emit(state.copyWith(status: 'error', hasLoadedRemote: false));
          },
        );
  }

  /// Acquires the 45s lease lock and starts a 20s heartbeat timer while active.
  Future<bool> acquireLockAndStartHeartbeat({bool force = false}) async {
    if (isClosed || khademId.isEmpty) return false;
    final acquired = await _repository.acquireSessionLock(
      sessionId: sessionId,
      grade: grade,
      khademId: khademId,
      khademName: khademName,
      force: force,
    );
    if (acquired && !isClosed) {
      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) {
        if (isClosed) return;
        if (!state.isLockedByOther(khademId)) {
          _repository.acquireSessionLock(
            sessionId: sessionId,
            grade: grade,
            khademId: khademId,
            khademName: khademName,
          );
        }
      });
    }
    return acquired;
  }

  /// Releases the lease lock immediately when exiting or backgrounding the app.
  Future<void> releaseLock({bool force = false}) async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    if (khademId.isEmpty) return;
    await _repository.releaseSessionLock(
      sessionId: sessionId,
      grade: grade,
      khademId: khademId,
      force: force,
    );
  }

  Future<void> retryLoading() async {
    if (_userId() != khademId || isClosed) return;
    await _sessionSubscription?.cancel();
    if (isClosed || _userId() != khademId) return;
    _initSessionSubscription();
  }

  bool isAttended(String makhdomId) => state.isAttended(makhdomId);
  bool isExcused(String makhdomId) => state.isExcused(makhdomId);

  Future<void> togglePresence(String makhdomId) async {
    final currentlyPresent = isAttended(makhdomId);
    await setPresence(makhdomId: makhdomId, isPresent: !currentlyPresent);
  }

  Future<void> setPresence({
    required String makhdomId,
    required bool isPresent,
    String? operationId,
  }) async {
    final uid = _userId();
    if (uid != khademId || isClosed) {
      throw StateError('The initiating account changed.');
    }
    if (state.status == 'finalizing') {
      throw StateError('Finalization in progress.');
    }
    if (state.isFinalized) {
      throw AppFailure(
        code: 'attendance-finalized',
        message: 'Attendance is finalized.',
      );
    }

    // Track whether this servant checked the student in this session so
    // unchecking a mistake only removes this servant's mark (CRDT safe).
    final bool onlyOwnMark;
    if (isPresent) {
      _markedPresentInThisSession.add(makhdomId);
      onlyOwnMark = false;
    } else {
      onlyOwnMark = _markedPresentInThisSession.remove(makhdomId);
    }

    final currentSeq = (_sequences[makhdomId] ?? 0) + 1;
    _sequences[makhdomId] = currentSeq;

    // تحديث متفائل (Optimistic Update)
    final newPending = Map<String, bool>.from(state.pendingById);
    newPending[makhdomId] = isPresent;

    final newErrors = Map<String, Object>.from(state.saveErrors);
    newErrors.remove(makhdomId);

    final newFailed = Map<String, bool>.from(state.failedIntentById);
    newFailed.remove(makhdomId);

    emit(
      state.copyWith(
        pendingById: newPending,
        saveErrors: newErrors,
        failedIntentById: newFailed,
        status: 'saving',
      ),
    );

    final op = operationId ?? newOperationId('presence');
    final previous = _queues[makhdomId];
    final done = Completer<void>();
    _queues[makhdomId] = done.future;
    try {
      if (previous != null) await previous;
      if (_userId() != uid || isClosed) {
        throw StateError('The initiating account changed.');
      }
      await _repository.setPresence(
        sessionId: sessionId,
        grade: grade,
        makhdomId: makhdomId,
        isPresent: isPresent,
        date: date,
        type: type,
        khademId: khademId,
        khademName: khademName,
        taskId: taskId,
        operationId: op,
        onlyOwnMark: onlyOwnMark,
      );

      if (_userId() != uid || isClosed) {
        throw StateError('The initiating account changed.');
      }
      // تحقق من تسلسل الطلب لضمان عدم تجاوز طلب أحدث
      if (!isClosed && _sequences[makhdomId] == currentSeq) {
        _failedOperations.remove(makhdomId);
        final updatedPending = Map<String, bool>.from(state.pendingById);
        updatedPending.remove(makhdomId);

        final updatedFailed = Map<String, bool>.from(state.failedIntentById);
        updatedFailed.remove(makhdomId);

        emit(
          state.copyWith(
            pendingById: updatedPending,
            failedIntentById: updatedFailed,
            status: updatedPending.isEmpty && state.pendingExcusesById.isEmpty
                ? (state.isFinalized ? 'finalized' : 'idle')
                : 'saving',
          ),
        );
      }
    } catch (e) {
      if (!isClosed && _sequences[makhdomId] == currentSeq) {
        final updatedPending = Map<String, bool>.from(state.pendingById);
        updatedPending.remove(makhdomId);

        final updatedErrors = Map<String, Object>.from(state.saveErrors);
        updatedErrors[makhdomId] = e;

        final updatedFailed = Map<String, bool>.from(state.failedIntentById);
        updatedFailed[makhdomId] = isPresent;
        _failedOperations[makhdomId] = op;

        emit(
          state.copyWith(
            pendingById: updatedPending,
            saveErrors: updatedErrors,
            failedIntentById: updatedFailed,
            status: 'error',
          ),
        );
      }
    } finally {
      done.complete();
      if (identical(_queues[makhdomId], done.future)) _queues.remove(makhdomId);
    }
  }

  /// Sets or clears an excuse note for a student on an independent CRDT channel.
  Future<void> setExcuse({
    required String makhdomId,
    required String? note,
  }) async {
    final uid = _userId();
    if (uid != khademId || isClosed) {
      throw StateError('The initiating account changed.');
    }
    if (state.isFinalized) {
      throw AppFailure(
        code: 'attendance-finalized',
        message: 'Attendance is finalized.',
      );
    }

    final clean = note?.trim() ?? '';
    final excuseObj = clean.isNotEmpty
        ? AttendanceExcuse(
            note: clean,
            byKhademId: khademId,
            byKhademName: khademName,
            updatedAt: DateTime.now(),
          )
        : null;

    // If the student is currently marked present and the servant explicitly
    // records an excuse, unmark presence first so the student becomes excused.
    if (excuseObj != null && isAttended(makhdomId)) {
      await setPresence(makhdomId: makhdomId, isPresent: false);
    }

    final updatedPendingExcuses = Map<String, AttendanceExcuse?>.from(
      state.pendingExcusesById,
    );
    updatedPendingExcuses[makhdomId] = excuseObj;

    emit(
      state.copyWith(
        pendingExcusesById: updatedPendingExcuses,
        status: 'saving',
      ),
    );

    try {
      await _repository.setExcuse(
        sessionId: sessionId,
        grade: grade,
        makhdomId: makhdomId,
        note: clean.isNotEmpty ? clean : null,
        date: date,
        type: type,
        khademId: khademId,
        khademName: khademName,
      );
      if (!isClosed) {
        final afterPending = Map<String, AttendanceExcuse?>.from(
          state.pendingExcusesById,
        )..remove(makhdomId);
        final afterRemote = Map<String, AttendanceExcuse>.from(
          state.remoteExcuses,
        );
        if (excuseObj != null) {
          afterRemote[makhdomId] = excuseObj;
        } else {
          afterRemote.remove(makhdomId);
        }
        emit(
          state.copyWith(
            remoteExcuses: afterRemote,
            pendingExcusesById: afterPending,
            status: state.pendingById.isEmpty && afterPending.isEmpty
                ? (state.isFinalized ? 'finalized' : 'idle')
                : 'saving',
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        final afterPending = Map<String, AttendanceExcuse?>.from(
          state.pendingExcusesById,
        )..remove(makhdomId);
        emit(state.copyWith(pendingExcusesById: afterPending, status: 'error'));
      }
      rethrow;
    }
  }

  Future<void> retry(String makhdomId) async {
    if (!state.hasError(makhdomId) &&
        !state.failedIntentById.containsKey(makhdomId)) {
      return;
    }
    final target = state.failedIntentById[makhdomId] ?? isAttended(makhdomId);
    await setPresence(
      makhdomId: makhdomId,
      isPresent: target,
      operationId: _failedOperations[makhdomId],
    );
  }

  Future<void> finalizeAttendance({String? taskId}) async {
    if (isClosed || _userId() != khademId) {
      throw StateError('The initiating account changed.');
    }
    if (!state.hasLoadedRemote ||
        state.saveErrors.isNotEmpty ||
        state.failedIntentById.isNotEmpty) {
      throw StateError(
        'Resolve attendance loading and failed saves before finalizing.',
      );
    }
    if (state.pendingById.isNotEmpty || state.pendingExcusesById.isNotEmpty) {
      throw AppFailure(
        code: 'pending-saves',
        message: 'Attendance saves are pending.',
        retryable: true,
      );
    }

    emit(state.copyWith(status: 'finalizing'));

    try {
      await _repository.finalizeAttendance(
        sessionId: sessionId,
        grade: grade,
        taskId: taskId ?? this.taskId,
      );
      if (isClosed || _userId() != khademId) {
        throw StateError('The initiating account changed.');
      }
      emit(state.copyWith(status: 'finalized', isFinalized: true));
    } catch (e) {
      if (!isClosed) emit(state.copyWith(status: 'error'));
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    _heartbeatTimer?.cancel();
    await _sessionSubscription?.cancel();
    return super.close();
  }
}
