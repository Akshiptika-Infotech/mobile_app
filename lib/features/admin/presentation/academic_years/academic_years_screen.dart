import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/core/widgets/app_empty_state.dart';
import 'package:mobile_app/core/widgets/app_error_state.dart';
import 'package:mobile_app/core/widgets/app_skeleton_loader.dart';
import 'package:mobile_app/core/utils/error_message.dart';
import 'package:mobile_app/features/admin/providers/academic_year_provider.dart';

class AcademicYearsScreen extends ConsumerWidget {
  const AcademicYearsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(academicYearNotifierProvider);
    final notifier = ref.read(academicYearNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Academic Years'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: notifier.load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, notifier),
        icon: const Icon(Icons.add),
        label: const Text('Add Year'),
      ),
      body: Builder(builder: (context) {
        if (state.isLoading) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: AppSkeletonLoader.list(count: 6),
          );
        }
        if (state.error != null) {
          return AppErrorState(message: state.error!, onRetry: notifier.load);
        }
        if (state.years.isEmpty) {
          return const AppEmptyState(
            message: 'No academic years found',
            icon: Icons.calendar_month_outlined,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          itemCount: state.years.length,
          itemBuilder: (_, i) {
            final year = state.years[i];
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: year.isActive ? cs.primary : cs.outlineVariant,
                  width: year.isActive ? 2 : 1,
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      year.isActive ? cs.primaryContainer : cs.surfaceContainerHigh,
                  child: Icon(
                    Icons.calendar_month_outlined,
                    color: year.isActive ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                title: Text(
                  year.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: year.isActive ? cs.primary : cs.onSurface,
                  ),
                ),
                subtitle: Text(
                  '${year.startDate} to ${year.endDate}',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                trailing: year.isActive
                    ? Chip(
                        label: Text('Active',
                            style: TextStyle(fontSize: 11, color: cs.onPrimaryContainer)),
                        backgroundColor: cs.primaryContainer,
                        padding: EdgeInsets.zero,
                      )
                    : state.isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : TextButton(
                            onPressed: () => notifier.activate(year.id),
                            child: const Text('Set Active'),
                          ),
              ),
            );
          },
        );
      }),
    );
  }

  void _showAddSheet(BuildContext context, AcademicYearNotifier notifier) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddYearSheet(notifier: notifier),
    );
  }
}

// ── Add Year Sheet ────────────────────────────────────────────────────────────

class _AddYearSheet extends StatefulWidget {
  const _AddYearSheet({required this.notifier});
  final AcademicYearNotifier notifier;

  @override
  State<_AddYearSheet> createState() => _AddYearSheetState();
}

class _AddYearSheetState extends State<_AddYearSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  DateTime? _start;
  DateTime? _end;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _start ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (!mounted || d == null) return;
    setState(() => _start = d);
  }

  Future<void> _pickEnd() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _end ?? (_start ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (!mounted || d == null) return;
    setState(() => _end = d);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_start == null || _end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select start and end dates')));
      return;
    }
    setState(() => _saving = true);
    try {
      final fmt = DateFormat('yyyy-MM-dd');
      await widget.notifier.create(
        name: _nameCtrl.text.trim(),
        startDate: fmt.format(_start!),
        endDate: fmt.format(_end!),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyMessage(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Academic Year', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Year Name (e.g. 2024-25)',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickStart,
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: Text(_start == null ? 'Start Date' : fmt.format(_start!)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickEnd,
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: Text(_end == null ? 'End Date' : fmt.format(_end!)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Add Academic Year'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
