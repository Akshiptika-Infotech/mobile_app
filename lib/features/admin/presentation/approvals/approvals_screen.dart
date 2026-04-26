import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/features/admin/data/approvals_repository.dart';
import 'package:mobile_app/features/admin/domain/approval_models.dart';
import 'package:mobile_app/features/admin/providers/approvals_provider.dart';

class ApprovalsScreen extends ConsumerWidget {
  const ApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Approvals'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Gate Passes'),
              Tab(text: 'Permanent'),
              Tab(text: 'Leaves'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GatePassList(),
            _PermanentPassList(),
            _LeaveList(),
          ],
        ),
      ),
    );
  }
}

// ── Gate pass list ───────────────────────────────────────────────────────────

class _GatePassList extends ConsumerWidget {
  const _GatePassList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingGatePassesProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(pendingGatePassesProvider),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(message: e.toString(),
            onRetry: () => ref.invalidate(pendingGatePassesProvider)),
        data: (items) {
          if (items.isEmpty) return const _EmptyView(text: 'No pending gate passes');
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (_, i) => _GatePassCard(item: items[i]),
          );
        },
      ),
    );
  }
}

class _GatePassCard extends ConsumerWidget {
  const _GatePassCard({required this.item});
  final GatePassApproval item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(item.passType,
                      style: TextStyle(color: cs.onPrimaryContainer, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
                const Spacer(),
                Text(_relTime(item.createdAt),
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            if (item.subtitle.isNotEmpty)
              Text(item.subtitle, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 6),
            Text('Reason: ${item.reason}', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text('Valid: ${_short(item.validFrom)} → ${_short(item.validUntil)}',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            const SizedBox(height: 12),
            _ActionRow(
              onApprove: () async {
                await ref.read(approvalsRepositoryProvider).approveGatePass(item.id);
                ref.invalidate(pendingGatePassesProvider);
              },
              onReject: (reason) async {
                await ref.read(approvalsRepositoryProvider).rejectGatePass(item.id, reason);
                ref.invalidate(pendingGatePassesProvider);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Permanent pass list ──────────────────────────────────────────────────────

class _PermanentPassList extends ConsumerWidget {
  const _PermanentPassList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingPermanentPassesProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(pendingPermanentPassesProvider),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(message: e.toString(),
            onRetry: () => ref.invalidate(pendingPermanentPassesProvider)),
        data: (items) {
          if (items.isEmpty) return const _EmptyView(text: 'No pending permanent passes');
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (_, i) => _PermanentPassCard(item: items[i]),
          );
        },
      ),
    );
  }
}

class _PermanentPassCard extends ConsumerWidget {
  const _PermanentPassCard({required this.item});
  final PermanentPassApproval item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.visitorName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            Text(item.visitorPhone, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 6),
            Text('Purpose: ${item.purpose}', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text('Valid from: ${_short(item.validFrom)}'
                '${item.validUntil != null ? ' → ${_short(item.validUntil!)}' : ' · indefinite'}',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            const SizedBox(height: 12),
            _ActionRow(
              onApprove: () async {
                await ref.read(approvalsRepositoryProvider).approvePermanentPass(item.id);
                ref.invalidate(pendingPermanentPassesProvider);
              },
              onReject: (reason) async {
                await ref.read(approvalsRepositoryProvider).rejectPermanentPass(item.id, reason);
                ref.invalidate(pendingPermanentPassesProvider);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Leave request list ───────────────────────────────────────────────────────

class _LeaveList extends ConsumerWidget {
  const _LeaveList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingLeavesProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(pendingLeavesProvider),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(message: e.toString(),
            onRetry: () => ref.invalidate(pendingLeavesProvider)),
        data: (items) {
          if (items.isEmpty) return const _EmptyView(text: 'No pending leave requests');
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (_, i) => _LeaveCard(item: items[i]),
          );
        },
      ),
    );
  }
}

class _LeaveCard extends ConsumerWidget {
  const _LeaveCard({required this.item});
  final LeaveApproval item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(item.staffName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('${item.daysCount}d',
                      style: TextStyle(color: cs.onPrimaryContainer, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            Text(item.leaveType, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 6),
            Text('${_short(item.fromDate)} → ${_short(item.toDate)}',
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text(item.reason, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            _ActionRow(
              onApprove: () async {
                await ref.read(approvalsRepositoryProvider).approveLeave(item.id);
                ref.invalidate(pendingLeavesProvider);
              },
              onReject: (reason) async {
                await ref.read(approvalsRepositoryProvider).rejectLeave(item.id, note: reason);
                ref.invalidate(pendingLeavesProvider);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared bits ──────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.onApprove, required this.onReject});
  final Future<void> Function() onApprove;
  final Future<void> Function(String reason) onReject;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.error,
              side: BorderSide(color: cs.error.withValues(alpha: 0.4)),
            ),
            onPressed: () async {
              final reason = await _askReason(context);
              if (reason == null) return;
              await onReject(reason);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rejected')),
                );
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Approve'),
            onPressed: () async {
              await onApprove();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Approved')),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

Future<String?> _askReason(BuildContext context) async {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Reason for rejection'),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Enter reason'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
          child: const Text('Reject'),
        ),
      ],
    ),
  );
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(Icons.check_circle_outline, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
        const SizedBox(height: 12),
        Center(
          child: Text(text, style: TextStyle(color: cs.onSurfaceVariant)),
        ),
      ],
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

String _short(String iso) {
  if (iso.isEmpty) return '—';
  try {
    return DateFormat('d MMM, h:mm a').format(DateTime.parse(iso));
  } catch (_) {
    return iso;
  }
}

String _relTime(String iso) {
  if (iso.isEmpty) return '';
  try {
    final t = DateTime.parse(iso);
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  } catch (_) {
    return '';
  }
}
