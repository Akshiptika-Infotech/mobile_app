import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/widgets/app_empty_state.dart';
import 'package:mobile_app/core/widgets/app_error_state.dart';
import 'package:mobile_app/core/widgets/app_skeleton_loader.dart';
import 'package:mobile_app/core/widgets/confirmation_dialog.dart';
import 'package:mobile_app/features/admin/data/admin_views_repository.dart';
import 'package:mobile_app/features/admin/data/class_repository.dart';
import 'package:mobile_app/features/admin/domain/class_model.dart';
import 'package:mobile_app/features/admin/providers/class_provider.dart';

class ClassesScreen extends ConsumerWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final classes = ref.watch(classesProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Classes'),
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(classesProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showClassSheet(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Add Class'),
      ),
      body: classes.when(
        loading: () => Padding(
          padding: const EdgeInsets.all(16),
          child: AppSkeletonLoader.list(count: 6),
        ),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(classesProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              message: 'No classes found. Tap + to add.',
              icon: Icons.school_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final c = items[i];
              return Dismissible(
                key: ValueKey(c.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => _confirmDelete(context),
                onDismissed: (_) => _delete(context, ref, c.id),
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
                    leading: CircleAvatar(
                      backgroundColor: cs.primaryContainer,
                      child: Text(
                        c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C',
                        style: TextStyle(fontWeight: FontWeight.bold, color: cs.onPrimaryContainer),
                      ),
                    ),
                    title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      'Year: ${c.academicYear}${c.sections.isNotEmpty ? '  •  Sections: ${c.sections.join(', ')}' : ''}',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showClassSheet(context, ref, c),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return ConfirmationDialog.show(
      context,
      title: 'Delete Class',
      message: 'Are you sure you want to delete this class?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, String id) async {
    try {
      await ref.read(classRepositoryProvider).deleteClass(id);
      ref.invalidate(classesProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      ref.invalidate(classesProvider);
    }
  }

  void _showClassSheet(BuildContext context, WidgetRef ref, SchoolClass? existing) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ClassFormSheet(
        existing: existing,
        onSaved: () => ref.invalidate(classesProvider),
      ),
    );
  }
}

// ── Class form sheet ──────────────────────────────────────────────────────────

class _ClassFormSheet extends ConsumerStatefulWidget {
  const _ClassFormSheet({this.existing, required this.onSaved});
  final SchoolClass? existing;
  final VoidCallback onSaved;

  @override
  ConsumerState<_ClassFormSheet> createState() => _ClassFormSheetState();
}

class _ClassFormSheetState extends ConsumerState<_ClassFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _sectionsCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _yearCtrl = TextEditingController(text: e?.academicYear ?? '');
    _sectionsCtrl = TextEditingController(text: e?.sections.join(', ') ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _yearCtrl.dispose();
    _sectionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final sections = _sectionsCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (widget.existing != null) {
        // Update via patch
        await ref.read(adminViewsRepositoryProvider).patch(
            '/api/admin/classes/${widget.existing!.id}', {
          'name': _nameCtrl.text.trim(),
          'academicYear': _yearCtrl.text.trim(),
          'sections': sections,
        });
      } else {
        await ref
            .read(classRepositoryProvider)
            .createClass(_nameCtrl.text.trim(), _yearCtrl.text.trim(), sections);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.existing != null ? 'Class updated' : 'Class added')),
      );
      widget.onSaved();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing != null ? 'Edit Class' : 'Add Class',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Class Name', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _yearCtrl,
              decoration: const InputDecoration(
                labelText: 'Academic Year (e.g. 2024-25)',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _sectionsCtrl,
              decoration: const InputDecoration(
                labelText: 'Sections (comma-separated, e.g. A, B, C)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(widget.existing != null ? 'Save Changes' : 'Add Class'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

