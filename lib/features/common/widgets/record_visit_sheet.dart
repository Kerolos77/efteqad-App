import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/models/visit_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/visit_draft_store.dart';
import '../../../../core/services/trusted_mutations.dart';
import 'visit_date_picker_tile.dart';
import 'visit_draft_banner.dart';
import 'visit_type_selector.dart';

class RecordVisitSheet extends StatefulWidget {
  final MakhdomModel makhdom;
  final String? khademName;

  final FirestoreService? firestoreService;
  final AuthService? authService;
  final VisitDraftStore? draftStore;

  const RecordVisitSheet({
    super.key,
    this.firestoreService,
    this.authService,
    this.draftStore,
    required this.makhdom,
    this.khademName,
  });

  static Future<void> show(
    BuildContext context, {
    required MakhdomModel makhdom,
    String? khademName,
  }) {
    if (kIsWeb && MediaQuery.sizeOf(context).width >= 600) {
      return showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.r),
              child: SingleChildScrollView(
                child: RecordVisitSheet(makhdom: makhdom, khademName: khademName),
              ),
            ),
          ),
        ),
      );
    }
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          RecordVisitSheet(makhdom: makhdom, khademName: khademName),
    );
  }

  @override
  State<RecordVisitSheet> createState() => _RecordVisitSheetState();
}

class _RecordVisitSheetState extends State<RecordVisitSheet> {
  late final AuthService _authService;
  late final FirestoreService _firestoreService;
  late final VisitDraftStore _draftStore;
  final TextEditingController _notesController = TextEditingController();

  String? _visitType;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  bool _hasDraft = false;
  bool _isLoadingDraft = true;
  Object? _draftLoadError;
  String? _draftOperationId;
  String? _draftUid;
  VisitModel? _submittedVisit;

  @override
  void initState() {
    super.initState();
    _firestoreService = widget.firestoreService ?? FirestoreService();
    _authService = widget.authService ?? AuthService();
    _draftStore = widget.draftStore ?? VisitDraftStore();
    _loadDraftIfAny();
  }

  Future<void> _loadDraftIfAny() async {
    try {
      final user = _authService.currentUser;
      if (user == null) throw StateError('Authentication required.');
      _draftUid = user.uid;
      final drafts = await _draftStore.getDrafts(user.uid);
      if (!mounted) return;
      if (_authService.currentUser?.uid != user.uid) {
        throw StateError(
          'The initiating account changed. Resume with that account.',
        );
      }
      final match = drafts
          .where((d) => d['makhdomId'] == widget.makhdom.id)
          .firstOrNull;
      if (match != null && mounted) {
        _hasDraft = true;
        _draftOperationId = match['operationId'] as String?;
        _notesController.text = match['notes']?.toString() ?? '';
        if (match['visitType'] != null) {
          _visitType = canonicalVisitType(match['visitType'].toString());
        }
        if (match['visitDate'] != null) {
          _selectedDate =
              DateTime.tryParse(match['visitDate'].toString()) ?? _selectedDate;
        }
        if (_draftOperationId != null) {
          _submittedVisit = VisitModel(
            id: '',
            makhdomId: widget.makhdom.id,
            makhdomName: widget.makhdom.fullName,
            khademId: user.uid,
            khademName: widget.khademName ?? user.displayName ?? '',
            visitDate: _selectedDate,
            visitType: _visitType ?? 'home',
            notes: match['notes'] as String?,
            serviceId: widget.makhdom.serviceId,
            grade: widget.makhdom.grade,
            createdAt: DateTime.now(),
          );
        }
      }
    } catch (error) {
      _draftLoadError = error;
    } finally {
      if (mounted) setState(() => _isLoadingDraft = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visitType ??= 'home';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving || _isLoadingDraft || _draftLoadError != null) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null || currentUser.uid != _draftUid) {
        throw StateError(
          'The initiating account changed. Resume with that account.',
        );
      }
      final khademName =
          widget.khademName ??
          (currentUser.displayName?.isNotEmpty == true
              ? currentUser.displayName!
              : context.tr.servant);

      final operationId = _draftOperationId ??= newOperationId('visit');

      final effectiveVisitType = _visitType ?? 'home';

      final visit = _submittedVisit ??= VisitModel(
        id: '',
        makhdomId: widget.makhdom.id,
        makhdomName: widget.makhdom.fullName,
        khademId: currentUser.uid,
        khademName: khademName,
        visitDate: _selectedDate,
        visitType: effectiveVisitType,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        serviceId: widget.makhdom.serviceId,
        grade: widget.makhdom.grade,
        createdAt: DateTime.now(),
      );

      await _firestoreService.recordVisit(visit, operationId: operationId);
      if (_authService.currentUser?.uid != currentUser.uid) {
        throw StateError('The initiating account changed.');
      }
      await _draftStore.removeDraft(currentUser.uid, widget.makhdom.id);
      if (_authService.currentUser?.uid != currentUser.uid) {
        throw StateError('The initiating account changed.');
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.visitSavedSuccess),
            backgroundColor: AppColors.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppFailure.fromException(e).localizedMessage(context.tr),
            ),
            backgroundColor: AppColors.warningColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _visitType ??= 'home';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: (kIsWeb && MediaQuery.sizeOf(context).width >= 600)
            ? BorderRadius.circular(24.r)
            : BorderRadius.vertical(top: Radius.circular(28.r)),
        border: Border.all(
          color: isDark
              ? AppColors.cardBorderDark
              : AppColors.cardBorderLight,
        ),
      ),
      padding: EdgeInsetsDirectional.fromSTEB(
        20.w,
        12.h,
        20.w,
        MediaQuery.of(context).viewInsets.bottom + 24.h,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: AppColors.accentIndigo.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(
                    Icons.add_task,
                    color: AppColors.accentIndigo,
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr.logVisitTitle,
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
                      ),
                      Text(
                        widget.makhdom.fullName,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_draftLoadError != null)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  context.tr.dataUnavailable,
                  style: TextStyle(
                    color: AppColors.errorColor,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            if (_hasDraft) ...[
              SizedBox(height: 12.h),
              const VisitDraftBanner(),
            ],
            SizedBox(height: 20.h),

            // Visit type selection
            VisitTypeSelector(
              selectedType: _visitType ?? 'home',
              isEnabled: _submittedVisit == null,
              onTypeSelected: (type) => setState(() => _visitType = type),
            ),
            SizedBox(height: 16.h),

            // Date selection
            VisitDatePickerTile(
              selectedDate: _selectedDate,
              isEnabled: _submittedVisit == null,
              onDateSelected: (date) => setState(() => _selectedDate = date),
            ),
            SizedBox(height: 14.h),

            // Notes TextField
            TextField(
              enabled: _submittedVisit == null,
              controller: _notesController,
              maxLines: 4,
              minLines: 2,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(fontSize: 14.sp),
              decoration: InputDecoration(
                labelText: context.tr.messageVisitNotesAndDiscussion,
                labelStyle: TextStyle(fontSize: 13.sp),
                hintText: context
                    .tr
                    .messageRecordVisitDiscussionMeetingDetailsOrPastoral,
                hintStyle: TextStyle(fontSize: 13.sp),
                prefixIcon: Icon(
                  Icons.edit_note_rounded,
                  color: AppColors.accentIndigo,
                  size: 22.sp,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF131D31)
                    : const Color(0xFFF8FAFC),
              ),
            ),
            SizedBox(height: 20.h),

            if (_submittedVisit != null)
              Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Text(
                  context.tr.messageFieldsAreLockedUntilConfirmationRetryTo631,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textMuted,
                  ),
                ),
              ),

            // Save button
            ElevatedButton(
              onPressed: _isSaving || _isLoadingDraft || _draftLoadError != null
                  ? null
                  : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                padding: EdgeInsets.symmetric(vertical: 15.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: _isSaving
                  ? SizedBox(
                      width: 22.r,
                      height: 22.r,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.2,
                      ),
                    )
                  : Text(
                      context.tr.saveVisitBtn,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
