import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/core/widgets/app_empty_state.dart';
import 'package:mobile_app/core/widgets/app_error_state.dart';
import 'package:mobile_app/core/widgets/app_skeleton_loader.dart';
import 'package:mobile_app/core/widgets/confirmation_dialog.dart';
import 'package:mobile_app/features/admin/data/fee_master_repository.dart';
import 'package:mobile_app/core/utils/error_message.dart';
import 'package:mobile_app/features/admin/providers/fee_master_provider.dart';

class ConcessionsScreen extends ConsumerStatefulWidget {
  const ConcessionsScreen({super.key});

  @override
  ConsumerState<ConcessionsScreen> createState() => _ConcessionsScreenState();
}

class _ConcessionsScreenState extends ConsumerState<ConcessionsScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  String _discountType = 'fixed';
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(feeMasterRepositoryProvider).createConcession({
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'discountType': _discountType,
        'discountValue': double.tryParse(_valueCtrl.text.trim()) ?? 0,
      });
      _nameCtrl.clear();
      _descCtrl.clear();
      _valueCtrl.clear();
      ref.invalidate(concessionsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyMessage(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool?> _confirmDelete(String name) =>
      ConfirmationDialog.show(
        context,
        title: 'Delete "$name"',
        message: 'This cannot be undone.',
        confirmLabel: 'Delete',
        isDestructive: true,
      );

  Future<void> _delete(String id) async {
    try {
      await ref.read(feeMasterRepositoryProvider).deleteConcession(id);
      ref.invalidate(concessionsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final list = ref.watch(concessionsProvider);
    final money = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Concessions'),
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _discountType,
                        decoration: const InputDecoration(labelText: 'Discount Type', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'fixed', child: Text('fixed')),
                          DropdownMenuItem(value: 'percent', child: Text('percent')),
                        ],
                        onChanged: (v) => setState(() => _discountType = v ?? _discountType),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _valueCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Value', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _add,
                    child: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Add Concession'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: list.when(
              loading: () => Padding(
                padding: const EdgeInsets.all(16),
                child: AppSkeletonLoader.list(count: 6),
              ),
              error: (e, _) => AppErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(concessionsProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const AppEmptyState(
                    message: 'No concessions found',
                    icon: Icons.discount_outlined,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final c = items[i];
                    final value = c.discountType == 'percent'
                        ? '${c.discountValue.toStringAsFixed(0)}%'
                        : money.format(c.discountValue);
                    return Dismissible(
                      key: ValueKey(c.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) { HapticFeedback.mediumImpact(); return _confirmDelete(c.name); },
                      onDismissed: (_) => _delete(c.id),
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
                          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(c.description),
                          trailing: Chip(label: Text(value)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
