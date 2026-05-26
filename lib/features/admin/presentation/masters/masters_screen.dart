import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/widgets/app_empty_state.dart';
import 'package:mobile_app/core/widgets/app_error_state.dart';
import 'package:mobile_app/core/widgets/app_skeleton_loader.dart';
import 'package:mobile_app/core/widgets/confirmation_dialog.dart';
import 'package:mobile_app/features/admin/data/masters_repository.dart';
import 'package:mobile_app/core/utils/error_message.dart';
import 'package:mobile_app/features/admin/providers/masters_provider.dart';

class MastersScreen extends ConsumerStatefulWidget {
  const MastersScreen({super.key, required this.model});
  final String model;

  @override
  ConsumerState<MastersScreen> createState() => _MastersScreenState();
}

class _MastersScreenState extends ConsumerState<MastersScreen> {
  final _nameCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String get _title {
    final value = widget.model.replaceAll('-', ' ');
    return value[0].toUpperCase() + value.substring(1);
  }

  Future<void> _add() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(mastersRepositoryProvider).createMaster(widget.model, name);
      _nameCtrl.clear();
      ref.invalidate(mastersProvider(widget.model));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyMessage(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(String id, String name) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete "$name"',
      message: 'This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(mastersRepositoryProvider).deleteMaster(widget.model, id);
      ref.invalidate(mastersProvider(widget.model));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final data = ref.watch(mastersProvider(widget.model));

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(mastersProvider(widget.model)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Add item bar
          Container(
            color: cs.surface,
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Add new ${_title.toLowerCase()}...',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _saving ? null : _add(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _saving ? null : _add,
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Add'),
                ),
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
                onRetry: () => ref.invalidate(mastersProvider(widget.model)),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return AppEmptyState(
                    message: 'No ${_title.toLowerCase()} found',
                    icon: Icons.list_alt_outlined,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final id = (item['id'] ?? item['_id'] ?? '').toString();
                    final name = (item['name'] ?? '').toString();
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: cs.outlineVariant),
                      ),
                      child: ListTile(
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: cs.error),
                          onPressed: () => _delete(id, name),
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
