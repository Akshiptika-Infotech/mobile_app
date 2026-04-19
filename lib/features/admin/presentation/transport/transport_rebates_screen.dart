import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/core/widgets/app_empty_state.dart';
import 'package:mobile_app/core/widgets/app_error_state.dart';
import 'package:mobile_app/core/widgets/app_skeleton_loader.dart';
import 'package:mobile_app/core/widgets/confirmation_dialog.dart';
import 'package:mobile_app/features/admin/data/transport_repository.dart';
import 'package:mobile_app/features/admin/providers/transport_admin_provider.dart';

class TransportRebatesScreen extends ConsumerStatefulWidget {
  const TransportRebatesScreen({super.key});

  @override
  ConsumerState<TransportRebatesScreen> createState() => _TransportRebatesScreenState();
}

class _TransportRebatesScreenState extends ConsumerState<TransportRebatesScreen> {
  final _studentCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _studentCtrl.dispose();
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_studentCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(transportAdminRepositoryProvider).createRebate({
        'studentName': _studentCtrl.text.trim(),
        'amount': double.tryParse(_amountCtrl.text.trim()) ?? 0,
        'reason': _reasonCtrl.text.trim(),
      });
      _studentCtrl.clear();
      _amountCtrl.clear();
      _reasonCtrl.clear();
      ref.invalidate(transportRebatesProvider);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool?> _confirmDelete(String name) =>
      ConfirmationDialog.show(
        context,
        title: 'Delete rebate for "$name"',
        message: 'This cannot be undone.',
        confirmLabel: 'Delete',
        isDestructive: true,
      );

  Future<void> _delete(String id) async {
    try {
      await ref.read(transportAdminRepositoryProvider).deleteRebate(id);
      ref.invalidate(transportRebatesProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final list = ref.watch(transportRebatesProvider);
    final money = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Transport Rebates'),
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAdd,
        child: const Icon(Icons.add),
      ),
      body: list.when(
        loading: () => Padding(
          padding: const EdgeInsets.all(16),
          child: AppSkeletonLoader.list(count: 6),
        ),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(transportRebatesProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              message: 'No rebates found',
              icon: Icons.money_off_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final r = items[i];
              return Dismissible(
                key: ValueKey(r.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => _confirmDelete(r.studentName),
                onDismissed: (_) => _delete(r.id),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.delete_outline, color: cs.onErrorContainer),
                ),
                child: Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: cs.outlineVariant),
                  ),
                  child: ListTile(
                    title: Text(r.studentName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(r.reason),
                    trailing: Chip(label: Text(money.format(r.amount))),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAdd() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _studentCtrl,
              decoration: const InputDecoration(labelText: 'Student Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonCtrl,
              decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving
                    ? null
                    : () async {
                        await _add();
                        if (!mounted) return;
                        Navigator.pop(context);
                      },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
