import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/admin/domain/attendance_model.dart';
import 'package:mobile_app/features/admin/providers/qr_scan_provider.dart';

class QrLiveScreen extends ConsumerWidget {
  const QrLiveScreen({super.key, required this.params});

  final QrScanParams params;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(qrLiveNotifierProvider(params));

    final subtitle = [
      params.className,
      if (params.sectionName != null) params.sectionName!,
      params.date,
    ].join(' · ');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Live Attendance', style: TextStyle(fontSize: 16)),
            Text(subtitle,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(qrLiveNotifierProvider(params).notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary bar
          if (!state.isLoading && state.students.isNotEmpty)
            _SummaryBar(
              total: state.students.length,
              marked: state.markedCount,
              present: state.presentCount,
            ),

          // List
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null && state.students.isEmpty
                    ? _ErrorView(
                        message: state.error!,
                        onRetry: () => ref
                            .read(qrLiveNotifierProvider(params).notifier)
                            .refresh(),
                      )
                    : state.students.isEmpty
                        ? const _EmptyView()
                        : RefreshIndicator(
                            onRefresh: () => ref
                                .read(qrLiveNotifierProvider(params).notifier)
                                .refresh(),
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: state.students.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1, indent: 72),
                              itemBuilder: (context, i) =>
                                  _StudentTile(student: state.students[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Summary bar ───────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.total,
    required this.marked,
    required this.present,
  });

  final int total;
  final int marked;
  final int present;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final absent = marked - present;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: cs.surfaceContainerLow,
      child: Row(
        children: [
          _Stat(label: 'Total', value: total, color: cs.onSurface),
          const SizedBox(width: 16),
          _Stat(label: 'Marked', value: marked, color: cs.primary),
          const SizedBox(width: 16),
          _Stat(label: 'Present', value: present, color: Colors.green.shade700),
          const SizedBox(width: 16),
          _Stat(label: 'Absent', value: absent, color: cs.error),
          const Spacer(),
          SizedBox(
            width: 80,
            child: LinearProgressIndicator(
              value: total > 0 ? marked / total : 0,
              backgroundColor: cs.surfaceContainerHigh,
              color: cs.primary,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, color: color),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7)),
        ),
      ],
    );
  }
}

// ── Student tile ──────────────────────────────────────────────────────────────

class _StudentTile extends StatelessWidget {
  const _StudentTile({required this.student});

  final LiveAttendanceStudent student;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    if (student.isPresent) {
      statusColor = Colors.green.shade700;
      statusIcon = Icons.check_circle_rounded;
      statusLabel = 'Present';
    } else if (student.isMarked) {
      statusColor = cs.error;
      statusIcon = Icons.cancel_rounded;
      statusLabel = student.attendanceStatus ?? 'Absent';
    } else {
      statusColor = cs.onSurfaceVariant;
      statusIcon = Icons.radio_button_unchecked_rounded;
      statusLabel = 'Not marked';
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withValues(alpha: 0.15),
        child: Text(
          student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
          style: TextStyle(
              color: statusColor, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        student.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        student.admissionNumber,
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 18),
          const SizedBox(width: 4),
          Text(
            statusLabel,
            style: TextStyle(color: statusColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Empty / error states ──────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          const Text('No students found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('Try scanning some QR codes first',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
