import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/widgets/app_empty_state.dart';
import 'package:mobile_app/core/widgets/app_error_state.dart';
import 'package:mobile_app/core/widgets/app_skeleton_loader.dart';
import 'package:mobile_app/core/widgets/confirmation_dialog.dart';
import 'package:mobile_app/features/admin/data/fee_master_repository.dart';
import 'package:mobile_app/core/utils/error_message.dart';
import 'package:mobile_app/features/admin/providers/fee_master_provider.dart';

class FeeTypesScreen extends ConsumerStatefulWidget {
  const FeeTypesScreen({super.key});

  @override
  ConsumerState<FeeTypesScreen> createState() => _FeeTypesScreenState();
}

class _FeeTypesScreenState extends ConsumerState<FeeTypesScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _optional = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(feeMasterRepositoryProvider).createFeeType(
            _nameCtrl.text.trim(),
            _descCtrl.text.trim(),
            _optional,
          );
      _nameCtrl.clear();
      _descCtrl.clear();
      setState(() => _optional = false);
      ref.invalidate(feeTypesProvider);
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
      await ref.read(feeMasterRepositoryProvider).deleteFeeType(id);
      ref.invalidate(feeTypesProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final list = ref.watch(feeTypesProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Fee Types'),
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
                Row(
                  children: [
                    Checkbox(
                      value: _optional,
                      onChanged: (v) => setState(() => _optional = v ?? false),
                    ),
                    const Text('Optional Fee Type'),
                  ],
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _add,
                    child: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Add Fee Type'),
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
                onRetry: () => ref.invalidate(feeTypesProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const AppEmptyState(
                    message: 'No fee types found',
                    icon: Icons.receipt_long_outlined,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final type = items[i];
                    return Dismissible(
                      key: ValueKey(type.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) { HapticFeedback.mediumImpact(); return _confirmDelete(type.name); },
                      onDismissed: (_) => _delete(type.id),
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
                          title: Text(type.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(type.description),
                          trailing: type.isOptional ? const Chip(label: Text('Optional')) : null,
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
