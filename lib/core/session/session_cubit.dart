import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/khadem_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/profile_repository.dart';
import 'session_state.dart';
import '../services/device_registration_service.dart';

class SessionCubit extends Cubit<SessionState> {
  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;
  final Future<void> Function() _beforeSignOut;

  StreamSubscription<AuthIdentity?>? _authSubscription;
  StreamSubscription<KhademModel?>? _profileSubscription;
  Timer? _splashTimer;
  bool _splashCompleted = true;
  SessionState? _pendingPostSplashState;
  String? _currentProfileUid;

  SessionCubit({
    required AuthRepository authRepository,
    required ProfileRepository profileRepository,
    Future<void> Function()? beforeSignOut,
    Duration minimumSplashDuration = Duration.zero,
  }) : _authRepository = authRepository,
       _profileRepository = profileRepository,
       _beforeSignOut =
           beforeSignOut ??
           (() => DeviceRegistrationService.shared.unbindUser()),
       super(const SessionState.booting()) {
    if (minimumSplashDuration > Duration.zero) {
      _splashCompleted = false;
      _splashTimer = Timer(minimumSplashDuration, _completeSplash);
    }
    _initAuthListener();
  }

  void _completeSplash() {
    _splashCompleted = true;
    final pending = _pendingPostSplashState;
    _pendingPostSplashState = null;
    if (pending != null && !isClosed) {
      emit(pending);
    }
  }

  void _emitState(SessionState nextState) {
    if (isClosed) return;
    if (!_splashCompleted && nextState.status != SessionStatus.booting) {
      _pendingPostSplashState = nextState;
      return;
    }
    emit(nextState);
  }

  AuthIdentity? get authIdentity => _authRepository.currentAuth;

  void _initAuthListener() {
    _authSubscription = _authRepository.watchAuth().listen(
      _onAuthChanged,
      onError: (error) {
        _emitState(
          SessionState.failure(userId: _currentProfileUid, failure: error),
        );
      },
    );
  }

  void _onAuthChanged(AuthIdentity? identity) {
    if (identity == null) {
      _cancelProfileSubscription();
      _currentProfileUid = null;
      _emitState(const SessionState.signedOut());
      return;
    }

    if (identity.uid != _currentProfileUid) {
      _cancelProfileSubscription();
      _currentProfileUid = identity.uid;
      _subscribeToProfile(identity.uid);
    }
  }

  void _subscribeToProfile(String uid) {
    _emitState(SessionState.profileLoading(userId: uid));

    _profileSubscription = _profileRepository
        .watchProfile(uid)
        .listen(
          (profile) => _onProfileUpdated(uid, profile),
          onError: (error) {
            if (isClosed || uid != _currentProfileUid) return;
            _emitState(SessionState.failure(userId: uid, failure: error));
          },
        );
  }

  void _onProfileUpdated(String uid, KhademModel? profile) {
    if (isClosed || uid != _currentProfileUid) return;
    if (profile == null) {
      // ملف غير موجود أو مستخدم جديد قيد الانتظار
      _emitState(
        SessionState(
          status: SessionStatus.pending,
          userId: uid,
          role: UserRole.pending,
          profile: null,
        ),
      );
      return;
    }

    // التحقق الصارم من حالة الحذف (deleting lifecycle)
    if (profile.status == 'deleting') {
      _emitState(
        SessionState(
          status: SessionStatus.deleting,
          userId: uid,
          role: UserRole.fromString(profile.role),
          grade: profile.grade,
          profile: profile,
        ),
      );
      return;
    }

    final role = UserRole.fromString(profile.role);
    final isValidGrade =
        profile.grade != null &&
        (profile.grade == '1st' ||
            profile.grade == '2nd' ||
            profile.grade == '3rd');

    if (role == UserRole.stageAdmin) {
      // أمين المرحلة لا يحتاج لسنة، لكن يجب أن يكون نشطاً (غير قيد الحذف أو معلق)
      if (profile.status == 'active') {
        _emitState(
          SessionState(
            status: SessionStatus.active,
            userId: uid,
            role: UserRole.stageAdmin,
            grade: profile.grade,
            profile: profile,
          ),
        );
      } else {
        _emitState(
          SessionState(
            status: SessionStatus.pending,
            userId: uid,
            role: UserRole.stageAdmin,
            grade: profile.grade,
            profile: profile,
          ),
        );
      }
    } else if (role == UserRole.gradeAdmin || role == UserRole.servant) {
      // أمين السنة والخادم يحتاجان لسنة صالحة وحالة نشطة
      if (isValidGrade && profile.status == 'active') {
        _emitState(
          SessionState(
            status: SessionStatus.active,
            userId: uid,
            role: role,
            grade: profile.grade,
            profile: profile,
          ),
        );
      } else {
        _emitState(
          SessionState(
            status: SessionStatus.pending,
            userId: uid,
            role: role,
            grade: profile.grade,
            profile: profile,
          ),
        );
      }
    } else {
      // دور قيد الانتظار (Pending)
      _emitState(
        SessionState(
          status: SessionStatus.pending,
          userId: uid,
          role: UserRole.pending,
          grade: profile.grade,
          profile: profile,
        ),
      );
    }
  }

  /// إعادة المحاولة عند حدوث خطأ في الاتصال أو استرداد الملف
  void retry() {
    final uid = _currentProfileUid ?? state.userId;
    if (uid != null) {
      _cancelProfileSubscription();
      _subscribeToProfile(uid);
    }
  }

  Future<void> signOut() async {
    final expectedUid = state.userId;
    await _beforeSignOut();
    // A delayed cleanup for the old account cannot sign out a newer identity.
    if (_authRepository.currentAuth?.uid != expectedUid) return;
    try {
      await _authRepository.signOut();
    } catch (_) {
      // SDK failures can retain A or coincide with a genuine identity change.
      // Keep A's trusted listener live, or reconcile to the actual current identity.
      if (!isClosed) _onAuthChanged(_authRepository.currentAuth);
      rethrow;
    }
    if (!isClosed) _onAuthChanged(_authRepository.currentAuth);
  }

  void _cancelProfileSubscription() {
    _profileSubscription?.cancel();
    _profileSubscription = null;
  }

  @override
  Future<void> close() async {
    _splashTimer?.cancel();
    await _authSubscription?.cancel();
    await _profileSubscription?.cancel();
    return super.close();
  }
}
