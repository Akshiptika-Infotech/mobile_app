import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/widgets/app_empty_state.dart';
import 'package:mobile_app/core/widgets/app_error_state.dart';
import 'package:mobile_app/core/widgets/app_skeleton_loader.dart';
import 'package:mobile_app/features/admin/data/admin_views_repository.dart';
import 'package:mobile_app/features/admin/data/settings_repository.dart';
import 'package:mobile_app/features/admin/providers/settings_provider.dart';

// ── Providers for extra tabs ──────────────────────────────────────────────────

final _signaturesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminViewsRepositoryProvider).fetchList('/api/admin/settings/signatures');
});

final _shiftsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminViewsRepositoryProvider).fetchList('/api/admin/attendance/shifts');
});

// ── Main Screen ───────────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'School Info'),
              Tab(text: 'Signatures'),
              Tab(text: 'Shifts'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _SchoolInfoTab(),
            _SignaturesTab(),
            _ShiftsTab(),
          ],
        ),
      ),
    );
  }
}

// ── School Info Tab ───────────────────────────────────────────────────────────

class _SchoolInfoTab extends ConsumerStatefulWidget {
  const _SchoolInfoTab();

  @override
  ConsumerState<_SchoolInfoTab> createState() => _SchoolInfoTabState();
}

class _SchoolInfoTabState extends ConsumerState<_SchoolInfoTab> {
  final _schoolNameCtrl = TextEditingController();
  final _logoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _schoolNameCtrl.dispose();
    _logoCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(settingsRepositoryProvider).updateSettings({
        'schoolName': _schoolNameCtrl.text.trim(),
        'logoUrl': _logoCtrl.text.trim(),
        'contactEmail': _emailCtrl.text.trim(),
        'contactPhone': _phoneCtrl.text.trim(),
        'activeAcademicYear': _yearCtrl.text.trim(),
      });
      ref.invalidate(settingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Settings saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return settings.when(
      loading: () => Padding(
        padding: const EdgeInsets.all(16),
        child: AppSkeletonLoader.list(count: 6),
      ),
      error: (e, _) => AppErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(settingsProvider),
      ),
      data: (item) {
        if (!_loaded) {
          _schoolNameCtrl.text = item.schoolName;
          _logoCtrl.text = item.logoUrl;
          _emailCtrl.text = item.contactEmail;
          _phoneCtrl.text = item.contactPhone;
          _yearCtrl.text = item.activeAcademicYear;
          _loaded = true;
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('School Info', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextFormField(
                controller: _schoolNameCtrl,
                decoration: const InputDecoration(labelText: 'School Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _logoCtrl,
                      decoration: const InputDecoration(labelText: 'Logo URL', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Image upload requires device package (Phase M9)')));
                    },
                    icon: const Icon(Icons.upload_outlined, size: 18),
                    label: const Text('Upload'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Contact', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Contact Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Contact Phone', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Text('Academic Year', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: _yearCtrl,
                decoration: const InputDecoration(labelText: 'Active Academic Year', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save Settings'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Signatures Tab ────────────────────────────────────────────────────────────

class _SignaturesTab extends ConsumerWidget {
  const _SignaturesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final data = ref.watch(_signaturesProvider);

    return data.when(
      loading: () => Padding(
        padding: const EdgeInsets.all(16),
        child: AppSkeletonLoader.list(count: 5),
      ),
      error: (e, _) => AppErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(_signaturesProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppEmptyState(
                message: 'No signatories configured',
                icon: Icons.draw_outlined,
              ),
              FilledButton.icon(
                onPressed: () => _showAddSignatureSheet(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Signatory'),
              ),
            ],
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length + 1,
          itemBuilder: (_, i) {
            if (i == items.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  onPressed: () => _showAddSignatureSheet(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Signatory'),
                ),
              );
            }
            final sig = items[i];
            final name = (sig['name'] ?? '').toString();
            final role = (sig['role'] ?? sig['designation'] ?? '').toString();
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: cs.outlineVariant),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: cs.secondaryContainer,
                  child: Icon(Icons.draw_outlined, color: cs.onSecondaryContainer, size: 18),
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(role),
                trailing: IconButton(
                  onPressed: () async {
                    final id = (sig['id'] ?? '').toString();
                    if (id.isEmpty) return;
                    try {
                      await ref
                          .read(adminViewsRepositoryProvider)
                          .patch('/api/admin/settings/signatures/$id/delete', {});
                      ref.invalidate(_signaturesProvider);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  },
                  icon: Icon(Icons.delete_outline, color: cs.error),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddSignatureSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddSignatorySheet(onAdded: () => ref.invalidate(_signaturesProvider)),
    );
  }
}

class _AddSignatorySheet extends ConsumerStatefulWidget {
  const _AddSignatorySheet({required this.onAdded});
  final VoidCallback onAdded;

  @override
  ConsumerState<_AddSignatorySheet> createState() => _AddSignatorySheetState();
}

class _AddSignatorySheetState extends ConsumerState<_AddSignatorySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roleCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(adminViewsRepositoryProvider).patch(
        '/api/admin/settings/signatures',
        {
          'name': _nameCtrl.text.trim(),
          'role': _roleCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signatory added')));
      widget.onAdded();
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
            Text('Add Signatory', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _roleCtrl,
              decoration: const InputDecoration(labelText: 'Role / Designation', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Add Signatory'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Attendance Shifts Tab ─────────────────────────────────────────────────────

class _ShiftsTab extends ConsumerWidget {
  const _ShiftsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final data = ref.watch(_shiftsProvider);

    return data.when(
      loading: () => Padding(
        padding: const EdgeInsets.all(16),
        child: AppSkeletonLoader.list(count: 5),
      ),
      error: (e, _) => AppErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(_shiftsProvider),
      ),
      data: (items) {
        return Stack(
          children: [
            items.isEmpty
                ? const AppEmptyState(
                    message: 'No shifts configured',
                    icon: Icons.schedule_outlined,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final shift = items[i];
                      final name = (shift['name'] ?? shift['shiftName'] ?? '').toString();
                      final start = (shift['startTime'] ?? shift['start'] ?? '').toString();
                      final end = (shift['endTime'] ?? shift['end'] ?? '').toString();
                      final grace = (shift['graceMinutes'] ?? shift['grace'] ?? 0).toString();
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: cs.outlineVariant),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: cs.primaryContainer,
                            child: Icon(Icons.schedule_outlined,
                                color: cs.onPrimaryContainer, size: 18),
                          ),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('$start – $end  •  Grace: $grace min'),
                          trailing: IconButton(
                            onPressed: () => _showEditSheet(context, ref, shift),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ),
                      );
                    },
                  ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: FilledButton.icon(
                onPressed: () => _showEditSheet(context, ref, null),
                icon: const Icon(Icons.add),
                label: const Text('Add Shift'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, Map<String, dynamic>? shift) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ShiftFormSheet(
        shift: shift,
        onSaved: () => ref.invalidate(_shiftsProvider),
      ),
    );
  }
}

class _ShiftFormSheet extends ConsumerStatefulWidget {
  const _ShiftFormSheet({this.shift, required this.onSaved});
  final Map<String, dynamic>? shift;
  final VoidCallback onSaved;

  @override
  ConsumerState<_ShiftFormSheet> createState() => _ShiftFormSheetState();
}

class _ShiftFormSheetState extends ConsumerState<_ShiftFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _startCtrl;
  late final TextEditingController _endCtrl;
  late final TextEditingController _graceCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.shift;
    _nameCtrl = TextEditingController(text: (s?['name'] ?? s?['shiftName'] ?? '').toString());
    _startCtrl = TextEditingController(text: (s?['startTime'] ?? s?['start'] ?? '').toString());
    _endCtrl = TextEditingController(text: (s?['endTime'] ?? s?['end'] ?? '').toString());
    _graceCtrl = TextEditingController(text: (s?['graceMinutes'] ?? s?['grace'] ?? '').toString());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    _graceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final isEdit = widget.shift != null;
      final id = (widget.shift?['id'] ?? '').toString();
      final endpoint = isEdit
          ? '/api/admin/attendance/shifts/$id'
          : '/api/admin/attendance/shifts';
      final body = {
        'name': _nameCtrl.text.trim(),
        'startTime': _startCtrl.text.trim(),
        'endTime': _endCtrl.text.trim(),
        'graceMinutes': int.tryParse(_graceCtrl.text.trim()) ?? 0,
      };
      if (isEdit) {
        await ref.read(adminViewsRepositoryProvider).patch(endpoint, body);
      } else {
        await ref.read(adminViewsRepositoryProvider).post(endpoint, body);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(isEdit ? 'Shift updated' : 'Shift added')));
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
    final isEdit = widget.shift != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEdit ? 'Edit Shift' : 'Add Shift', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Shift Name', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startCtrl,
                    decoration: const InputDecoration(labelText: 'Start Time (HH:mm)', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _endCtrl,
                    decoration: const InputDecoration(labelText: 'End Time (HH:mm)', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _graceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Grace Minutes', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(isEdit ? 'Save Changes' : 'Add Shift'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
