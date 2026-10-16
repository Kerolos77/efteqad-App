import 'package:efteqad/core/errors/app_failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/router/router_services.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../common/widgets/record_visit_sheet.dart';
import 'add_edit_makhdom_dialog.dart';
import 'assign_makhdomeen_modal.dart';
import 'grade_makhdomeen_filter_bar.dart';
import 'makhdom_card.dart';
import 'servant_assignment_banner.dart';

class GradeMakhdomeenTab extends StatefulWidget {
  final String grade;
  final List<MakhdomModel> allMakhdomeen;
  final List<KhademModel> khodamList;
  final VoidCallback? onRefresh;

  const GradeMakhdomeenTab({
    super.key,
    required this.grade,
    required this.allMakhdomeen,
    required this.khodamList,
    this.onRefresh,
  });

  @override
  State<GradeMakhdomeenTab> createState() => _GradeMakhdomeenTabState();
}

class _GradeMakhdomeenTabState extends State<GradeMakhdomeenTab> {
  final FirestoreService _firestoreService = FirestoreService();

  String? _selectedKhademFilterId;
  String? _selectedClassFilterId;
  String _searchQuery = '';

  void _openAddMakhdomDialog([MakhdomModel? makhdom]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddEditMakhdomDialog(
        khodamList: widget.khodamList,
        initialMakhdom:
            makhdom ??
            MakhdomModel(
              id: '',
              fullName: '',
              phone: '',
              grade: widget.grade,
              createdAt: DateTime.now(),
            ),
      ),
    );
  }

  void _handleDeleteMakhdom(MakhdomModel makhdom) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr.deleteMakhdomTitle),
        content: Text(ctx.tr.deleteMakhdomPrompt(makhdom.fullName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.tr.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _firestoreService.deleteMakhdom(makhdom.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.errorColor,
            ),
            child: Text(ctx.tr.delete),
          ),
        ],
      ),
    );
  }

  void _handleUnassignMakhdom(MakhdomModel makhdom) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr.messageUnassignStudent),
        content: Text(
          ctx.tr.messageAreYouSureYouWantToUnassign(
            (makhdom.fullName).toString(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.tr.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _firestoreService.unassignMakhdom(
                  makhdom.id,
                  expectedKhademId: makhdom.assignedKhademId,
                );
              } catch (error) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppFailure.fromException(
                          error,
                        ).localizedMessage(context.tr),
                      ),
                      backgroundColor: AppColors.errorColor,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.errorColor,
            ),
            child: Text(ctx.tr.messageUnassign),
          ),
        ],
      ),
    );
  }

  void _openAssignModalForSelectedKhadem(KhademModel khadem) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AssignMakhdomeenModal(
        targetKhadem: khadem,
        allMakhdomeen: widget.allMakhdomeen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser =
        RouterServices.maybeOf(context)?.session.state.profile ??
        context.read<SessionCubit>().state.profile;
    final myAssignedCount = currentUser == null
        ? 0
        : widget.allMakhdomeen
              .where((m) => m.assignedKhademId == currentUser.id)
              .length;

    final availableClasses = <String, String>{};
    for (final m in widget.allMakhdomeen) {
      if (m.classId != null && m.classId!.isNotEmpty) {
        availableClasses[m.classId!] = m.className ?? 'فصل';
      }
    }

    final filteredList = widget.allMakhdomeen.where((m) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = m.fullName.toLowerCase().contains(q);
        final matchesArea = m.area.toLowerCase().contains(q);
        final matchesPhone = m.phone.contains(q);
        final matchesSchool = m.school.toLowerCase().contains(q);
        if (!matchesName && !matchesArea && !matchesPhone && !matchesSchool) {
          return false;
        }
      }

      if (_selectedClassFilterId != null) {
        if (m.classId != _selectedClassFilterId) return false;
      }

      if (_selectedKhademFilterId == 'unassigned') {
        return !m.isAssigned;
      } else if (_selectedKhademFilterId == 'brethren') {
        return m.isBrethrenOfLord;
      } else if (_selectedKhademFilterId != null) {
        return m.assignedKhademId == _selectedKhademFilterId;
      }

      return true;
    }).toList();

    KhademModel? currentSelectedKhadem;
    if (_selectedKhademFilterId != null &&
        _selectedKhademFilterId != 'unassigned' &&
        _selectedKhademFilterId != 'brethren') {
      try {
        currentSelectedKhadem = widget.khodamList.firstWhere(
          (k) => k.id == _selectedKhademFilterId,
        );
      } catch (_) {}
    }

    return Column(
      children: [
        GradeMakhdomeenFilterBar(
          searchQuery: _searchQuery,
          onSearchChanged: (val) => setState(() => _searchQuery = val.trim()),
          availableClasses: availableClasses,
          selectedClassFilterId: _selectedClassFilterId,
          onClassFilterChanged: (id) => setState(() => _selectedClassFilterId = id),
          selectedKhademFilterId: _selectedKhademFilterId,
          onKhademFilterChanged: (id) => setState(() => _selectedKhademFilterId = id),
          allMakhdomeen: widget.allMakhdomeen,
          khodamList: widget.khodamList,
          currentUser: currentUser,
          myAssignedCount: myAssignedCount,
          isDark: isDark,
        ),
        if (currentSelectedKhadem != null)
          ServantAssignmentBanner(
            khadem: currentSelectedKhadem,
            onAssignPressed: () => _openAssignModalForSelectedKhadem(currentSelectedKhadem!),
          ),
        Expanded(
          child: filteredList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 50.sp,
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        context.tr.noSearchResults,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsetsDirectional.fromSTEB(16.w, 8.h, 16.w, 85.h),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final makhdom = filteredList[index];
                    return MakhdomCard(
                      makhdom: makhdom,
                      onEdit: () => _openAddMakhdomDialog(makhdom),
                      onDelete: () => _handleDeleteMakhdom(makhdom),
                      onUnassign: () => _handleUnassignMakhdom(makhdom),
                      onLogVisit: () {
                        RecordVisitSheet.show(context, makhdom: makhdom);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
