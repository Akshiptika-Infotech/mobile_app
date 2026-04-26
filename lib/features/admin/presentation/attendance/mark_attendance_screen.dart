import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/app_config.dart' show AppConfigScope;
import 'package:mobile_app/features/admin/domain/attendance_model.dart';
import 'package:mobile_app/features/admin/providers/attendance_provider.dart';
import 'package:mobile_app/features/admin/providers/class_provider.dart';

class MarkAttendanceScreen extends ConsumerWidget {
  const MarkAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(myClassAttendanceProvider);
    final notifier = ref.read(myClassAttendanceProvider.notifier);
    final yearsAsync = ref.watch(academicYearsProvider);
    final classesAsync = ref.watch(classesProvider);
    final dateStr = DateFormat('yyyy-MM-dd').format(state.date);

    void openQrScanner() {
      final years = yearsAsync.valueOrNull ?? [];
      final classes = classesAsync.valueOrNull ?? [];
      if (years.isEmpty || classes.isEmpty) {
        context.push('/admin/attendance/qr-setup');
        return;
      }
      final year = years.firstWhere((y) => y.isActive, orElse: () => years.first);
      final cls = classes.first;
      context.push('/admin/attendance/qr-scan', extra: QrScanParams(
        classId: cls.id,
        className: cls.name,
        academicYearId: year.id,
        date: dateStr,
      ));
    }

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Mark Attendance'),
        centerTitle: false,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        surfaceTintColor: cs.surfaceTint,
        actions: [
          if (!state.submitted && !state.locked && state.students.isNotEmpty)
            TextButton.icon(
              onPressed: notifier.markAllPresent,
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('All Present'),
            ),
          if (state.locked)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.lock_rounded, size: 20),
            )
          else
            IconButton(
              icon: const Icon(Icons.qr_code_scanner_rounded),

              tooltip: 'QR Attendance',
              onPressed: openQrScanner,
            ),
        ],
      ),
      body: Column(
        children: [
          _DatePickerBar(state: state, notifier: notifier),
          Expanded(child: _Body(state: state, notifier: notifier)),
        ],
      ),
      bottomNavigationBar: _SubmitBar(state: state, notifier: notifier),
    );
  }
}

// ── Date picker bar ───────────────────────────────────────────────────────────

class _DatePickerBar extends StatelessWidget {
  const _DatePickerBar({required this.state, required this.notifier});
  final MyClassAttendanceState state;
  final MyClassAttendanceNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final formatted = DateFormat('EEEE, d MMMM yyyy').format(state.date);
    return Container(
      color: cs.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 18, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              formatted,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: state.date,
                firstDate: DateTime.now().subtract(const Duration(days: 90)),
                lastDate: DateTime.now(),
              );
              if (picked != null) notifier.setDate(picked);
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.notifier});
  final MyClassAttendanceState state;
  final MyClassAttendanceNotifier notifier;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(state.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center),
        ),
      );
    }
    if (state.students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('No students found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: state.students.length,
      itemBuilder: (context, i) => _StudentRow(
        student: state.students[i],
        submitted: state.submitted,
        onChanged: (status) =>
            notifier.setStatus(state.students[i].id, status),
      ),
    );
  }
}

// ── Student row ───────────────────────────────────────────────────────────────

class _StudentRow extends StatelessWidget {
  const _StudentRow({
    required this.student,
    required this.submitted,
    required this.onChanged,
  });
  final AttendanceStudent student;
  final bool submitted;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final baseUrl = AppConfigScope.of(context).baseUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _Avatar(
            name: student.name,
            photoPath: student.photoPath,
            baseUrl: baseUrl,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name.isNotEmpty ? student.name : '—',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  student.rollNumber.isNotEmpty
                      ? 'Roll: ${student.rollNumber}'
                      : student.admissionNumber.isNotEmpty
                          ? student.admissionNumber
                          : '—',
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (submitted)
            _StatusChip(status: student.status, interactive: false)
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: ['present', 'absent', 'leave', 'medical'].map((s) {
                final selected = student.status == s;
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: _StatusChip(
                    status: s,
                    interactive: true,
                    selected: selected,
                    onTap: () => onChanged(s),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// ── Avatar with optional photo ────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.name,
    required this.photoPath,
    required this.baseUrl,
  });

  final String name;
  final String? photoPath;
  final String baseUrl;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initial =
        name.isNotEmpty ? name.trim().split(' ').first[0].toUpperCase() : '?';

    if (photoPath != null && photoPath!.isNotEmpty) {
      final url = photoPath!.startsWith('http')
          ? photoPath!
          : '$baseUrl$photoPath';
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          placeholder: (_, __) => CircleAvatar(
            radius: 20,
            backgroundColor: cs.primaryContainer,
            child: Text(initial,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer)),
          ),
          errorWidget: (_, __, ___) => CircleAvatar(
            radius: 20,
            backgroundColor: cs.primaryContainer,
            child: Text(initial,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer)),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: cs.primaryContainer,
      child: Text(initial,
          style: TextStyle(
              fontWeight: FontWeight.bold, color: cs.onPrimaryContainer)),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
    required this.interactive,
    this.selected = true,
    this.onTap,
  });
  final String status;
  final bool interactive;
  final bool selected;
  final VoidCallback? onTap;

  static const _colors = {
    'present': Color(0xFF10B981),
    'absent': Color(0xFFEF4444),
    'late': Color(0xFFF59E0B),
    'leave': Color(0xFF6366F1),
    'medical': Color(0xFF0EA5E9),
  };
  static const _labels = {
    'present': 'P',
    'absent': 'A',
    'late': 'L',
    'leave': 'LV',
    'medical': 'M',
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[status] ?? Colors.grey;
    final label = _labels[status] ?? status;
    final active = !interactive || selected;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: interactive ? 30 : null,
        padding: interactive
            ? null
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? color : color.withValues(alpha: 0.3),
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active ? color : color.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

// ── Submit bar ────────────────────────────────────────────────────────────────

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({required this.state, required this.notifier});
  final MyClassAttendanceState state;
  final MyClassAttendanceNotifier notifier;

  @override
  Widget build(BuildContext context) {
    if (state.students.isEmpty || state.isLoading) return const SizedBox();
    final cs = Theme.of(context).colorScheme;

    if (state.locked) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        color: cs.surfaceContainerHighest,
        child: Row(
          children: [
            Icon(Icons.lock_rounded, color: cs.onSurfaceVariant, size: 18),
            const SizedBox(width: 8),
            Text(
              'Attendance is locked',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (state.submitted) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        color: cs.surface,
        child: const Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: Color(0xFF10B981), size: 20),
            SizedBox(width: 8),
            Text('Attendance submitted',
                style: TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    final presentCount =
        state.students.where((s) => s.status == 'present').length;
    final absentCount =
        state.students.where((s) => s.status == 'absent').length;
    final leaveCount =
        state.students.where((s) => s.status == 'leave' || s.status == 'medical').length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      color: cs.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _countBadge('Present', presentCount, const Color(0xFF10B981)),
              const SizedBox(width: 16),
              _countBadge('Absent', absentCount, const Color(0xFFEF4444)),
              const SizedBox(width: 16),
              _countBadge('Leave/Med', leaveCount, const Color(0xFF6366F1)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: state.isSubmitting ? null : notifier.submit,
              child: state.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Attendance'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _countBadge(String label, int count, Color color) {
    return Column(
      children: [
        Text('$count',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
