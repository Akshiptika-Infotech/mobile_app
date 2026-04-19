import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/core/widgets/app_empty_state.dart';
import 'package:mobile_app/core/widgets/app_error_state.dart';
import 'package:mobile_app/core/widgets/app_skeleton_loader.dart';
import 'package:mobile_app/core/widgets/attendance_status_chip.dart';
import 'package:mobile_app/features/admin/data/attendance_repository.dart';
import 'package:mobile_app/features/admin/domain/attendance_model.dart';
import 'package:mobile_app/features/admin/providers/attendance_provider.dart';

class StudentAttendanceScreen extends ConsumerStatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  ConsumerState<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends ConsumerState<StudentAttendanceScreen> {
  final _classCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  // overrides: studentId -> status (for live marking before save)
  final Map<String, String> _overrides = {};
  bool _saving = false;

  @override
  void dispose() {
    _classCtrl.dispose();
    super.dispose();
  }

  ({String? className, String date}) get _query => (
        className: _classCtrl.text.trim().isEmpty
            ? null
            : _classCtrl.text.trim(),
        date: DateFormat('yyyy-MM-dd').format(_date),
      );

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

  void _setAll(String status, List<AttendanceRecord> records) {
    setState(() {
      for (final r in records) {
        _overrides[r.studentId] = status;
      }
    });
  }

  String _statusFor(AttendanceRecord r) => _overrides[r.studentId] ?? r.status;

  Future<void> _saveAll(List<AttendanceRecord> records) async {
    setState(() => _saving = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_date);
      final payload = records
          .map((r) => {'studentId': r.studentId, 'status': _statusFor(r)})
          .toList();
      await ref.read(attendanceRepositoryProvider).submitAttendance(date: dateStr, records: payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Attendance saved')));
      setState(() => _overrides.clear());
      ref.invalidate(studentAttendanceProvider(_query));
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
    final data = ref.watch(studentAttendanceProvider(_query));

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Student Attendance'),
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
      ),
      body: Column(
        children: [
          // Filters
          Container(
            color: cs.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _classCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Class',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => setState(() => _overrides.clear()),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: Text(DateFormat('dd MMM').format(_date)),
                ),
              ],
            ),
          ),
          // Body
          Expanded(
            child: data.when(
              loading: () => Padding(
                padding: const EdgeInsets.all(16),
                child: AppSkeletonLoader.list(count: 8),
              ),
              error: (e, _) => AppErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(studentAttendanceProvider(_query)),
              ),
              data: (records) {
                if (records.isEmpty) {
                  return const AppEmptyState(
                    message: 'No records found.\nEnter a class name and try again.',
                    icon: Icons.people_outline,
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
                          const Spacer(),
                          if (_overrides.isNotEmpty)
                            FilledButton(
                              onPressed: _saving ? null : () => _saveAll(records),
                              child: _saving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Save'),
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
                                    backgroundColor: cs.primaryContainer,
                                    child: Text(
                                      r.studentName.isNotEmpty ? r.studentName[0].toUpperCase() : '?',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: cs.onPrimaryContainer, fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(r.studentName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        Text(r.date, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                                      ],
                                    ),
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
                    // Save button at bottom when overrides exist
                    if (_overrides.isNotEmpty)
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _saving ? null : () => _saveAll(records),
                              child: _saving
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
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
