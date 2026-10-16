import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:efteqad/core/errors/app_failure.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/visit_model.dart';
import '../../../../core/services/firestore_service.dart';

class EditVisitNotesDialog extends StatefulWidget {
  final VisitModel visit;
  final String makhdomId;
  final FirestoreService firestoreService;

  const EditVisitNotesDialog({
    super.key,
    required this.visit,
    required this.makhdomId,
    required this.firestoreService,
  });

  static Future<void> show(
    BuildContext context, {
    required VisitModel visit,
    required String makhdomId,
    required FirestoreService firestoreService,
  }) {
    return showDialog(
      context: context,
      builder: (_) => EditVisitNotesDialog(
        visit: visit,
        makhdomId: makhdomId,
        firestoreService: firestoreService,
      ),
    );
  }

  @override
  State<EditVisitNotesDialog> createState() => _EditVisitNotesDialogState();
}

class _EditVisitNotesDialogState extends State<EditVisitNotesDialog> {
  late final TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.visit.notes ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final tr = context.tr;
    setState(() => _isSaving = true);
    try {
      final newNotes = _controller.text.trim();
      await widget.firestoreService.updateVisitNotes(
        visitId: widget.visit.id,
        notes: newNotes,
        makhdomId: widget.makhdomId,
      );
      if (mounted) {
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(tr.visitNotesUpdatedSuccess),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              AppFailure.fromException(e).localizedMessage(tr),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: AppColors.sacredGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.edit_note_rounded,
              color: AppColors.sacredGold,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              context.tr.editVisitNotesTitle,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16.sp,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr.editVisitNotesSubtitle,
            style: TextStyle(
              fontSize: 12.5.sp,
              color: isDark ? Colors.white70 : AppColors.textMuted,
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _controller,
            maxLines: 4,
            autofocus: true,
            decoration: InputDecoration(
              hintText: context.tr.editVisitNotesHint,
              hintStyle: TextStyle(fontSize: 12.5.sp),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.black26
                  : const Color(0xFFF8FAFC),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.sacredGold,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? SizedBox(
                  width: 16.w,
                  height: 16.h,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  context.tr.save,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
        ),
      ],
    );
  }
}
