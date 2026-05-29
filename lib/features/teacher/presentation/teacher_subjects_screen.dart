import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/admin/domain/exam_model.dart';
import 'package:mobile_app/features/teacher/providers/teacher_subject_provider.dart';

class TeacherSubjectsScreen extends ConsumerWidget {
  const TeacherSubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final subjectsAsync = ref.watch(teacherSubjectsProvider);
    final actionState = ref.watch(teacherSubjectNotifierProvider);
    final actionNotifier = ref.read(teacherSubjectNotifierProvider.notifier);

    ref.listen(teacherSubjectNotifierProvider, (prev, next) {
      if (next.success && prev?.success != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        actionNotifier.reset();
        ref.invalidate(teacherSubjectsProvider);
      }
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: cs.error,
          ),
        );
        actionNotifier.reset();
      }
    });

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Manage Subjects'),
        centerTitle: false,
      ),
      body: subjectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(teacherSubjectsProvider),
        ),
        data: (subjects) {
          if (subjects.isEmpty) {
            return _EmptyState(onAdd: () => _showForm(context, ref));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: subjects.length,
            itemBuilder: (context, i) {
              final s = subjects[i];
              return _SubjectCard(
                subject: s,
                onEdit: () => _showForm(context, ref, subject: s),
                onDelete: () => _confirmDelete(context, ref, s),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: actionState.isLoading ? null : () => _showForm(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Subject'),
      ),
    );
  }

  void _showForm(
    BuildContext context,
    WidgetRef ref, {
    TeacherExamSubject? subject,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _SubjectFormSheet(
          subject: subject,
          onSave: (name, code, isGraded) async {
            final notifier = ref.read(teacherSubjectNotifierProvider.notifier);
            if (subject == null) {
              await notifier.create(
                name: name,
                code: code,
                isGraded: isGraded,
              );
            } else {
              await notifier.update(
                subject.id,
                name: name,
                code: code,
                isGraded: isGraded,
              );
            }
          },
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    TeacherExamSubject subject,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject?'),
        content: Text('"${subject.name}" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(teacherSubjectNotifierProvider.notifier)
                  .delete(subject.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Subject card ──────────────────────────────────────────────────────────────

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.subject,
    required this.onEdit,
    required this.onDelete,
  });

  final TeacherExamSubject subject;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Row(
          children: [
            Expanded(
              child: Text(
                subject.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (subject.isGraded)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'GRADED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: cs.onSecondaryContainer,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          'Code: ${subject.code}',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete_rounded,
                  size: 20, color: cs.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Subject form sheet ────────────────────────────────────────────────────────

class _SubjectFormSheet extends StatefulWidget {
  const _SubjectFormSheet({this.subject, required this.onSave});

  final TeacherExamSubject? subject;
  final Future<void> Function(String name, String code, bool isGraded) onSave;

  @override
  State<_SubjectFormSheet> createState() => _SubjectFormSheetState();
}

class _SubjectFormSheetState extends State<_SubjectFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late bool _isGraded;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.subject?.name ?? '');
    _codeCtrl = TextEditingController(text: widget.subject?.code ?? '');
    _isGraded = widget.subject?.isGraded ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    if (name.isEmpty || code.isEmpty) return;

    setState(() => _isSaving = true);
    await widget.onSave(name, code, _isGraded);
    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.subject != null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Edit Subject' : 'Add Subject',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Subject Name',
                prefixIcon: const Icon(Icons.book_rounded),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeCtrl,
              decoration: InputDecoration(
                labelText: 'Subject Code',
                prefixIcon: const Icon(Icons.code_rounded),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Graded subject (letter grades)'),
              value: _isGraded,
              onChanged: (v) => setState(() => _isGraded = v),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(isEdit ? 'Update' : 'Create'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_rounded,
              size: 64,
              color: cs.onSurfaceVariant.withValues(alpha: 0.35)),
          const SizedBox(height: 16),
          Text(
            'No exam subjects yet',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add your first subject'),
          ),
        ],
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: cs.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load subjects',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(message,
                style: TextStyle(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
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
