import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/core/widgets/app_empty_state.dart';
import 'package:mobile_app/core/widgets/app_error_state.dart';
import 'package:mobile_app/core/widgets/app_skeleton_loader.dart';
import 'package:mobile_app/core/widgets/attendance_status_chip.dart';
import 'package:mobile_app/features/admin/data/attendance_repository.dart';
import 'package:mobile_app/features/admin/domain/attendance_model.dart';

// Date-parameterised provider — date string is passed through to the repository.
final _staffAttendanceByDateProvider = FutureProvider.autoDispose
    .family<List<AttendanceRecord>, String>((ref, date) async {
  return ref.watch(attendanceRepositoryProvider).fetchStaffAttendance(date: date);
});

class StaffAttendanceScreen extends ConsumerStatefulWidget {
  const StaffAttendanceScreen({super.key});

  @override
  ConsumerState<StaffAttendanceScreen> createState() => _StaffAttendanceScreenState();
}

class _StaffAttendanceScreenState extends ConsumerState<StaffAttendanceScreen> {
  DateTime _date = DateTime.now();
  final Map<String, String> _overrides = {};
  bool _saving = false;

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_date);

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (!mounted || d == null) return;
    setState(() {
      _date = d;
      _overrides.clear();
    });
  }

  String _statusFor(AttendanceRecord r) => _overrides[r.studentId] ?? r.status;

  void _setAll(String status, List<AttendanceRecord> records) {
    setState(() {
      for (final r in records) {
        _overrides[r.studentId] = status;
      }
    });
  }

  Future<void> _saveAll(List<AttendanceRecord> records) async {
    setState(() => _saving = true);
    try {
      final payload = records
          .map((r) => {'staffId': r.studentId, 'status': _statusFor(r)})
          .toList();
      await ref.read(attendanceRepositoryProvider).submitAttendance(date: _dateStr, records: payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Staff attendance saved')));
      setState(() => _overrides.clear());
      ref.invalidate(_staffAttendanceByDateProvider(_dateStr));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final data = ref.watch(_staffAttendanceByDateProvider(_dateStr));

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Staff Attendance'),
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() => _overrides.clear());
              ref.invalidate(_staffAttendanceByDateProvider(_dateStr));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Date filter bar
          Container(
            color: cs.surface,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE, d MMMM yyyy').format(_date),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const Spacer(),
                TextButton(onPressed: _pickDate, child: const Text('Change Date')),
              ],
            ),
          ),
          Expanded(
            child: data.when(
              loading: () => Padding(
                padding: const EdgeInsets.all(16),
                child: AppSkeletonLoader.list(count: 8),
              ),
              error: (e, _) => AppErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(_staffAttendanceByDateProvider(_dateStr)),
              ),
              data: (records) {
                if (records.isEmpty) {
                  return const AppEmptyState(
                    message: 'No staff attendance records',
                    icon: Icons.badge_outlined,
                  );
                }
                return Column(
                  children: [
                    // Bulk action bar
                    Container(
                      color: cs.surfaceContainerHigh,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Text('Mark all:', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                          const SizedBox(width: 8),
                          AttendanceBulkChip(
                            label: 'Present',
                            status: 'present',
                            onTap: () => _setAll('present', records),
                          ),
                          const SizedBox(width: 6),
                          AttendanceBulkChip(
                            label: 'Absent',
                            status: 'absent',
                            onTap: () => _setAll('absent', records),
                          ),
                          const SizedBox(width: 6),
                          AttendanceBulkChip(
                            label: 'Late',
                            status: 'late',
                            onTap: () => _setAll('late', records),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: records.length,
                        itemBuilder: (_, i) {
                          final r = records[i];
                          final status = _statusFor(r);
                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: cs.outlineVariant),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: cs.secondaryContainer,
                                    child: Text(
                                      r.studentName.isNotEmpty ? r.studentName[0].toUpperCase() : '?',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: cs.onSecondaryContainer,
                                          fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(r.studentName,
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                  Row(
                                    children: ['present', 'absent', 'late'].map((s) {
                                      return Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: AttendanceStatusChip(
                                          status: s,
                                          selected: status == s,
                                          onTap: () => setState(() => _overrides[r.studentId] = s),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (_overrides.isNotEmpty)
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _saving ? null : () => _saveAll(records),
                              child: _saving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2))
                                  : Text('Save Attendance (${_overrides.length} changes)'),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
