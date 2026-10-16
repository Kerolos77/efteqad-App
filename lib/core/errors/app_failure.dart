import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../localization/app_localizations.dart';

/// Represents a standardized application failure across network, database,
/// permissions, decoding, and auth layers.
class AppFailure implements Exception {
  // Standard Error Code Constants
  static const String codePermissionDenied = 'permission-denied';
  static const String codeNetworkError = 'network-error';
  static const String codeNotFound = 'not-found';
  static const String codeDecodeError = 'decode-error';
  static const String codeUnauthenticated = 'unauthenticated';
  static const String codeUnknown = 'unknown';
  static const String codeExcelEmpty = 'excel-empty';
  static const String codeExcelColumns = 'excel-columns';
  static const String codeExcelUnreadable = 'excel-unreadable';
  static const String codeAttendanceFinalized = 'attendance-finalized';
  static const String codePendingSaves = 'pending-saves';
  static const String codeStageAdminRequiresSuccessor =
      'stage-admin-requires-successor';

  final String code;
  final String message;
  final bool retryable;
  final Object? cause;
  final StackTrace? stackTrace;

  const AppFailure({
    required this.code,
    required this.message,
    this.retryable = false,
    this.cause,
    this.stackTrace,
  });

  /// Factory for permission-denied errors (not retryable).
  factory AppFailure.permissionDenied({
    String? message,
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return AppFailure(
      code: codePermissionDenied,
      message: message ?? 'Permission denied.',
      retryable: false,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  /// Factory for network/connectivity errors (retryable).
  factory AppFailure.network({
    String? message,
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return AppFailure(
      code: codeNetworkError,
      message: message ?? 'Network connection failed.',
      retryable: true,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  /// Factory for resource not-found errors (not retryable).
  factory AppFailure.notFound({
    String? message,
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return AppFailure(
      code: codeNotFound,
      message: message ?? 'Requested resource was not found.',
      retryable: false,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  /// Factory for schema or JSON/Map decode errors (not retryable).
  factory AppFailure.decode({
    String? message,
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return AppFailure(
      code: codeDecodeError,
      message: message ?? 'Failed to decode data.',
      retryable: false,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  /// Universal mapping factory for any caught exception or error.
  factory AppFailure.fromException(Object error, [StackTrace? stackTrace]) {
    if (error is AppFailure) {
      return error;
    }

    if (error is FirebaseFunctionsException &&
        error.details is Map &&
        (error.details as Map)['reason'] == 'STAGE_ADMIN_REQUIRES_SUCCESSOR') {
      return AppFailure(
        code: codeStageAdminRequiresSuccessor,
        message: 'Active successor required.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return AppFailure.permissionDenied(
            message: error.message ?? 'Permission denied.',
            cause: error,
            stackTrace: stackTrace,
          );
        case 'unavailable':
        case 'deadline-exceeded':
          return AppFailure.network(
            message: error.message ?? 'Network connection failed.',
            cause: error,
            stackTrace: stackTrace,
          );
        case 'not-found':
          return AppFailure.notFound(
            message: error.message ?? 'Requested resource was not found.',
            cause: error,
            stackTrace: stackTrace,
          );
        case 'unauthenticated':
          return AppFailure(
            code: codeUnauthenticated,
            message: error.message ?? 'User is unauthenticated.',
            retryable: false,
            cause: error,
            stackTrace: stackTrace,
          );
        default:
          return AppFailure(
            code: error.code,
            message: error.message ?? 'Application error occurred.',
            retryable: true,
            cause: error,
            stackTrace: stackTrace,
          );
      }
    }

    final errorString = error.toString().toLowerCase();
    if (errorString.contains('socketexception') ||
        errorString.contains('network') ||
        errorString.contains('connection refused') ||
        errorString.contains('connection reset') ||
        errorString.contains('clientexception')) {
      return AppFailure.network(
        message: 'Network connection failed.',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (error is FormatException || error is TypeError) {
      return AppFailure.decode(
        message: 'Failed to parse data format.',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    return AppFailure(
      code: codeUnknown,
      message: error.toString(),
      retryable: true,
      cause: error,
      stackTrace: stackTrace,
    );
  }

  String localizedMessage(GeneratedAppLocalizations tr) {
    final normalized = code.toLowerCase();
    if (normalized == codeExcelEmpty) return tr.excelEmptyFailure;
    if (normalized == codeExcelColumns) return tr.excelColumnsFailure;
    if (normalized == codeExcelUnreadable) return tr.excelReadFailure;
    if (normalized == codeAttendanceFinalized) {
      return tr.attendanceFinalizedFailure;
    }
    if (normalized == codePendingSaves) return tr.pendingSavesFailure;
    if (normalized == codePermissionDenied) return tr.failurePermissionDenied;
    if (normalized == codeNetworkError ||
        normalized == 'unavailable' ||
        normalized == 'deadline-exceeded') {
      return tr.failureNetwork;
    }
    if (normalized == codeNotFound) return tr.failureNotFound;
    if (normalized == codeDecodeError) return tr.failureDecode;
    if ({
      'invalid-credential',
      'wrong-password',
      'invalid-email',
    }.contains(normalized)) {
      return tr.loginFailedCheckCredentials;
    }
    if (normalized == codeUnauthenticated ||
        normalized == 'requires-recent-login') {
      return tr.failureAuthentication;
    }
    if (normalized == codeStageAdminRequiresSuccessor) {
      return tr.stageSuccessorRequired;
    }
    return tr.dataUnavailable;
  }

  @override
  String toString() =>
      'AppFailure(code: $code, message: $message, retryable: $retryable)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppFailure &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          message == other.message &&
          retryable == other.retryable;

  @override
  int get hashCode => code.hashCode ^ message.hashCode ^ retryable.hashCode;
}
