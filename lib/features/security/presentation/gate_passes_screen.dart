import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/features/security/data/security_repository.dart';
import 'package:mobile_app/features/security/domain/gate_pass_model.dart';
import 'package:mobile_app/features/security/domain/security_enums.dart';
import 'package:mobile_app/features/security/providers/security_providers.dart';

class GatePassesScreen extends ConsumerWidget {
  const GatePassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final passesAsync = ref.watch(activeGatePassesProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Active Gate Passes'),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeGatePassesProvider);
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: passesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Error: $e', style: TextStyle(color: cs.error)),
            ),
          ]),
          data: (passes) {
            if (passes.isEmpty) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                    child: Column(
                      children: [
                        Icon(Icons.qr_code_2_rounded,
                            size: 64,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        const Text('No active passes',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          'Approved passes will appear here until they\'re used or expire.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: passes.length,
              itemBuilder: (_, i) => _PassCard(pass: passes[i]),
            );
          },
        ),
      ),
    );
  }
}

class _PassCard extends ConsumerStatefulWidget {
  const _PassCard({required this.pass});
  final GatePass pass;

  @override
  ConsumerState<_PassCard> createState() => _PassCardState();
}

class _PassCardState extends ConsumerState<_PassCard> {
  bool _busy = false;

  Future<void> _markUsed() async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dlg) => AlertDialog(
        title: const Text('Mark pass as used?'),
        content: Text(
            'This will log an EXIT entry for ${widget.pass.personName} and close the pass.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dlg, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dlg, true),
              child: const Text('Mark used')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(securityRepositoryProvider)
          .markPassUsed(widget.pass.id);
      ref.invalidate(activeGatePassesProvider);
      ref.invalidate(entryExitLogsProvider);
      ref.invalidate(visitorsProvider);
      messenger.showSnackBar(
          const SnackBar(content: Text('Pass marked used. Exit logged.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = widget.pass;
    final isVisitor = p.passType == PassType.visitor;
    final accent = isVisitor
        ? const Color(0xFF6366F1)
        : const Color(0xFFF59E0B);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isVisitor
                      ? Icons.person_outline_rounded
                      : Icons.school_rounded,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.personName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(p.passType.label,
                        style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text('APPROVED',
                    style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (p.reason.isNotEmpty)
            Text('Reason: ${p.reason}',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(
            'Valid until ${DateFormat('d MMM, h:mm a').format(p.validUntil)}',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          if (p.studentAdmissionNumber != null) ...[
            const SizedBox(height: 4),
            Text('Admission #: ${p.studentAdmissionNumber}',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _busy ? null : _markUsed,
              icon: _busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.logout_rounded, size: 16),
              label: const Text('Mark used / Log exit'),
              style: ButtonStyle(
                minimumSize: WidgetStateProperty.all(const Size(0, 38)),
                padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
