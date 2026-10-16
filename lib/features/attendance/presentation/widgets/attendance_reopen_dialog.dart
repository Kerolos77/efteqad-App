import 'package:flutter/material.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/repositories/attendance_repository.dart';
import '../../../../core/services/trusted_mutations.dart';

class AttendanceReopenDialog extends StatefulWidget {
  final String sessionId;
  final String sessionGrade;
  final AttendanceRepository repository;

  const AttendanceReopenDialog({
    super.key,
    required this.sessionId,
    required this.sessionGrade,
    required this.repository,
  });

  static Future<void> show(
    BuildContext context, {
    required String sessionId,
    required String sessionGrade,
    required AttendanceRepository repository,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => AttendanceReopenDialog(
        sessionId: sessionId,
        sessionGrade: sessionGrade,
        repository: repository,
      ),
    );
  }

  @override
  State<AttendanceReopenDialog> createState() => _AttendanceReopenDialogState();
}

class _AttendanceReopenDialogState extends State<AttendanceReopenDialog> {
  var _reason = '';
  final _operationId = newOperationId('reopen');
  var _saving = false;
  Object? _error;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr.reopenAttendance),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            onChanged: (value) => _reason = value,
            enabled: !_saving && _error == null,
            maxLength: 500,
            decoration: InputDecoration(labelText: context.tr.reopenReason),
          ),
          if (_error != null)
            Text(
              AppFailure.fromException(_error!).localizedMessage(context.tr),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(context.tr.messageCancel),
        ),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  if (_reason.trim().isEmpty) return;
                  setState(() {
                    _saving = true;
                  });
                  final navigator = Navigator.of(context);
                  try {
                    await widget.repository.reopenAttendance(
                      sessionId: widget.sessionId,
                      grade: widget.sessionGrade,
                      reason: _reason.trim(),
                      operationId: _operationId,
                    );
                    if (mounted) navigator.pop();
                  } catch (e) {
                    if (mounted) {
                      setState(() {
                        _saving = false;
                        _error = e;
                      });
                    }
                  }
                },
          child: Text(context.tr.reopenAttendanceAction),
        ),
      ],
    );
  }
}
