import 'package:flutter/material.dart';
import '../../../../core/models/attendance_session_model.dart';
import '../../../../core/services/attendance_roster_repository.dart';
import '../../application/attendance_cubit.dart';
import 'attendance_roster_list_view.dart';
import 'attendance_search_and_filters.dart';
import 'attendance_status_banners.dart';
import 'attendance_top_summary_bar.dart';

class AttendanceRosterContent extends StatefulWidget {
  final List<AttendanceRosterRow> allMakhdomeen;
  final AttendanceState attendanceState;
  final bool isLockedByOther;
  final bool canEdit;
  final bool isAuthorized;
  final bool isAdmin;
  final bool isDark;
  final String sessionType;
  final String Function(String) getGradeLabel;
  final String Function(String) getGradeShortLabel;
  final void Function(AttendanceRosterRow, bool) onToggleAttendance;
  final void Function(AttendanceRosterRow, AttendanceExcuse?) onExcuseTap;
  final VoidCallback onTakeOverLock;
  final VoidCallback onFinalizeAttendance;

  const AttendanceRosterContent({
    super.key,
    required this.allMakhdomeen,
    required this.attendanceState,
    required this.isLockedByOther,
    required this.canEdit,
    required this.isAuthorized,
    required this.isAdmin,
    required this.isDark,
    required this.sessionType,
    required this.getGradeLabel,
    required this.getGradeShortLabel,
    required this.onToggleAttendance,
    required this.onExcuseTap,
    required this.onTakeOverLock,
    required this.onFinalizeAttendance,
  });

  @override
  State<AttendanceRosterContent> createState() =>
      _AttendanceRosterContentState();
}

class _AttendanceRosterContentState extends State<AttendanceRosterContent> {
  String _searchQuery = '';
  String _statusFilter = 'all';
  String? _selectedClassFilter;

  @override
  Widget build(BuildContext context) {
    final attendedList = widget.allMakhdomeen
        .where((m) => widget.attendanceState.isAttended(m.id))
        .toList();
    final excusedList = widget.allMakhdomeen
        .where((m) => widget.attendanceState.isExcused(m.id))
        .toList();
    final absentCount = (widget.allMakhdomeen.length -
            attendedList.length -
            excusedList.length)
        .clamp(0, widget.allMakhdomeen.length);

    final availableClasses = <String, String>{};
    final classCounts = <String, int>{};
    for (final m in widget.allMakhdomeen) {
      if (m.classId != null && m.classId!.isNotEmpty) {
        availableClasses[m.classId!] = m.className ?? 'فصل';
        classCounts[m.classId!] = (classCounts[m.classId!] ?? 0) + 1;
      }
    }

    final filteredList = widget.allMakhdomeen.where((m) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!m.fullName.toLowerCase().contains(q)) return false;
      }
      if (_selectedClassFilter != null) {
        if (m.classId != _selectedClassFilter) return false;
      }
      if (_statusFilter == 'present') {
        return widget.attendanceState.isAttended(m.id);
      }
      if (_statusFilter == 'excused') {
        return widget.attendanceState.isExcused(m.id);
      }
      if (_statusFilter == 'absent') {
        return !widget.attendanceState.isAttended(m.id) &&
            !widget.attendanceState.isExcused(m.id);
      }
      return true;
    }).toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Column(
          children: [
            AttendanceStatusBanners(
              isLockedByOther: widget.isLockedByOther,
              lockedByKhademName: widget.attendanceState.lockedByKhademName,
              isAdmin: widget.isAdmin,
              onTakeOverLock: widget.onTakeOverLock,
              isAuthorized: widget.isAuthorized,
              isFinalized: widget.attendanceState.isFinalized,
            ),
            AttendanceTopSummaryBar(
              attendedList: attendedList,
              excusedCount: excusedList.length,
              absentCount: absentCount,
              totalCount: widget.allMakhdomeen.length,
              isDark: widget.isDark,
              isAuthorized: widget.canEdit,
              sessionType: widget.sessionType,
              getGradeShortLabel: widget.getGradeShortLabel,
              onRemoveAttendance: (m) => widget.onToggleAttendance(m, false),
            ),
            AttendanceSearchAndFilters(
              searchQuery: _searchQuery,
              onSearchChanged: (val) =>
                  setState(() => _searchQuery = val.trim()),
              onClearSearch: () => setState(() => _searchQuery = ''),
              availableClasses: availableClasses,
              classCounts: classCounts,
              selectedClassFilter: _selectedClassFilter,
              onClassFilterSelected: (key) =>
                  setState(() => _selectedClassFilter = key),
              statusFilter: _statusFilter,
              onStatusFilterSelected: (key) =>
                  setState(() => _statusFilter = key),
              totalCount: widget.allMakhdomeen.length,
              absentCount: absentCount,
              attendedCount: attendedList.length,
              excusedCount: excusedList.length,
              isDark: widget.isDark,
            ),
            Expanded(
              child: AttendanceRosterListView(
                filteredList: filteredList,
                attendanceState: widget.attendanceState,
                canEdit: widget.canEdit,
                sessionType: widget.sessionType,
                getGradeLabel: widget.getGradeLabel,
                onToggleAttendance: widget.onToggleAttendance,
                onExcuseTap: widget.onExcuseTap,
                isDark: widget.isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
