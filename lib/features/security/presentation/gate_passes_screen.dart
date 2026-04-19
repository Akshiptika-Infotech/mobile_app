import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/security/data/security_repository.dart';
import 'package:mobile_app/features/security/domain/security_model.dart';
import 'package:mobile_app/features/security/providers/security_provider.dart';

class GatePassesScreen extends ConsumerWidget {
  const GatePassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final passesAsync = ref.watch(gatePassesProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Gate Passes'),
        centerTitle: false,
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(gatePassesProvider),
          ),
        ],
      ),
      body: passesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off_rounded, size: 48, color: cs.error),
                const SizedBox(height: 12),
                Text(e.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurfaceVariant),
                    maxLines: 3),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(gatePassesProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (passes) {
          final approved =
              passes.where((p) => p.status == 'approved').toList();
          final used = passes.where((p) => p.status == 'used').toList();

          if (passes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.badge_outlined,
                      size: 64,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.35)),
                  const SizedBox(height: 16),
                  Text('No gate passes found',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              if (approved.isNotEmpty) ...[
                _SectionLabel(
                    label: 'Approved (${approved.length})',
                    color: const Color(0xFF10B981)),
                const SizedBox(height: 8),
                ...approved.map((p) => _PassCard(
                      pass: p,
                      onMarkUsed: () => _markUsed(context, ref, p),
                    )),
                const SizedBox(height: 16),
              ],
              if (used.isNotEmpty) ...[
                _SectionLabel(
                    label: 'Used (${used.length})',
                    color: const Color(0xFF6B7280)),
                const SizedBox(height: 8),
                ...used.map((p) => _PassCard(pass: p)),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _markUsed(
      BuildContext context, WidgetRef ref, GatePass pass) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mark as Used'),
        content: Text(
            'Mark gate pass for ${pass.studentName} as used?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Mark Used')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(securityRepositoryProvider).markPassUsed(pass.id);
      ref.invalidate(gatePassesProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }
}

class _PassCard extends StatelessWidget {
  const _PassCard({required this.pass, this.onMarkUsed});
  final GatePass pass;
  final VoidCallback? onMarkUsed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isApproved = pass.status == 'approved';
    final statusColor =
        isApproved ? const Color(0xFF10B981) : const Color(0xFF6B7280);
    final typeColor = pass.type == 'permanent'
        ? const Color(0xFF8B5CF6)
        : const Color(0xFF3B82F6);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: cs.shadow.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: statusColor.withValues(alpha: 0.12),
                child: Text(
                  pass.studentName.isNotEmpty
                      ? pass.studentName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pass.studentName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(
                      '${pass.className} ${pass.section}',
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      pass.type[0].toUpperCase() + pass.type.substring(1),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: typeColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      pass.status[0].toUpperCase() +
                          pass.status.substring(1),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (pass.purpose.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.info_outline_rounded,
                  size: 12, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(pass.purpose,
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant)),
              ),
            ]),
          ],
          if (pass.validDate.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.calendar_today_rounded,
                  size: 12, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(pass.validDate,
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurfaceVariant)),
            ]),
          ],
          if (isApproved && onMarkUsed != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onMarkUsed,
                icon: const Icon(Icons.check_circle_outline_rounded,
                    size: 16),
                label: const Text('Mark as Used'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF10B981),
                  side: const BorderSide(color: Color(0xFF10B981)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
