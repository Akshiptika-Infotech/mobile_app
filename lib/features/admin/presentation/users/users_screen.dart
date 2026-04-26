import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/admin/domain/user_staff_model.dart';
import 'package:mobile_app/core/utils/error_message.dart';
import 'package:mobile_app/features/admin/providers/staff_provider.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(title: const Text('Staff Users')),
      body: const _UsersBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.person_add_outlined),
      ),
    );
  }

  static void _showAddSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _StaffFormSheet(),
    );
  }
}

// ── Body ───────────────────────────────────────────────────────────────────────

class _UsersBody extends ConsumerStatefulWidget {
  const _UsersBody();

  @override
  ConsumerState<_UsersBody> createState() => _UsersBodyState();
}

class _UsersBodyState extends ConsumerState<_UsersBody> {
  final _searchCtrl = TextEditingController();
  String _roleFilter = 'All';

  // Filter chips. Each entry is (label shown to user, exact role enum
  // returned by /api/admin/users). The enum values must match the backend
  // Role enum exactly — uppercase + underscore — or the equality test
  // below will silently filter everything out.
  static const _roles = <(String, String)>[
    ('All',           'All'),
    ('Admin',         'ADMIN'),
    ('Super Admin',   'SUPER_ADMIN'),
    ('Teacher',       'TEACHER'),
    ('Clerk',         'CLERK'),
    ('Receptionist',  'RECEPTIONIST'),
    ('Driver',        'DRIVER'),
    ('Security',      'SECURITY_GUARD'),
    ('Web Admin',     'WEB_ADMIN'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(staffNotifierProvider);

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 56, color: cs.error),
              const SizedBox(height: 16),
              Text(e.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(staffNotifierProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (users) {
        final q = _searchCtrl.text.toLowerCase();
        final filtered = users.where((u) {
          final matchRole =
              _roleFilter == 'All' || u.role == _roleFilter;
          final matchQ = q.isEmpty ||
              u.name.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q);
          return matchRole && matchQ;
        }).toList();

        return Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search by name or email',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear',
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 0, horizontal: 16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _roles.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final (label, value) = _roles[i];
                  final selected = _roleFilter == value;
                  return FilterChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _roleFilter = value),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            if (filtered.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 64,
                          color: cs.onSurfaceVariant
                              .withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text('No staff found.',
                          style: TextStyle(
                              color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(staffNotifierProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                        16, 8, 16, 96),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (ctx, i) =>
                        _StaffTile(user: filtered[i]),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Staff Tile ─────────────────────────────────────────────────────────────────

class _StaffTile extends ConsumerWidget {
  const _StaffTile({required this.user});
  final StaffUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(user.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: cs.onErrorContainer),
      ),
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Staff'),
            content: Text('Delete ${user.name}? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: cs.error),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed != true) return false;
        try {
          await ref.read(staffNotifierProvider.notifier).delete(user.id);
          return true;
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Delete failed: ${e.toString()}')),
            );
          }
          return false;
        }
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.outlineVariant),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: cs.primaryContainer,
            backgroundImage: (user.image != null && user.image!.isNotEmpty)
                ? NetworkImage(user.image!)
                : null,
            child: (user.image == null || user.image!.isEmpty)
                ? Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          title: Text(user.name,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${user.role} · ${user.email}',
              style: TextStyle(
                  fontSize: 12, color: cs.onSurfaceVariant)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.lock_reset_outlined),
                tooltip: 'Reset password',
                onPressed: () => _confirmResetPassword(context, ref),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit',
                onPressed: () =>
                    _showEditSheet(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmResetPassword(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text('Reset password for ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final newPwd = await ref
                    .read(staffNotifierProvider.notifier)
                    .resetPassword(user.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Password reset to "$newPwd" — share with the user.'),
                      duration: const Duration(seconds: 6),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Reset failed: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _StaffFormSheet(existing: user),
    );
  }
}

// ── Staff Form Sheet ───────────────────────────────────────────────────────────

class _StaffFormSheet extends ConsumerStatefulWidget {
  const _StaffFormSheet({this.existing});
  final StaffUser? existing;

  @override
  ConsumerState<_StaffFormSheet> createState() => _StaffFormSheetState();
}

class _StaffFormSheetState extends ConsumerState<_StaffFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(
      text: widget.existing?.name ?? '');
  late final _emailCtrl = TextEditingController(
      text: widget.existing?.email ?? '');
  late final _phoneCtrl = TextEditingController(
      text: widget.existing?.phone ?? '');
  String _role = 'TEACHER';
  bool _isSubmitting = false;

  // (display label, role enum). Must match the Prisma Role enum exactly.
  static const _roles = <(String, String)>[
    ('Admin',         'ADMIN'),
    ('Teacher',       'TEACHER'),
    ('Clerk',         'CLERK'),
    ('Receptionist',  'RECEPTIONIST'),
    ('Driver',        'DRIVER'),
    ('Security',      'SECURITY_GUARD'),
    ('Web Admin',     'WEB_ADMIN'),
  ];

  @override
  void initState() {
    super.initState();
    _role = widget.existing?.role ?? 'TEACHER';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return PopScope(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Edit Staff' : 'Add Staff',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]{2,}$').hasMatch(v.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(
                    labelText: 'Role', border: OutlineInputBorder()),
                items: _roles
                    .map((entry) => DropdownMenuItem(
                          value: entry.$2,
                          child: Text(entry.$1),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _role = v ?? _role),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEdit ? 'Save Changes' : 'Add Staff'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final data = {
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'role': _role,
      if (_phoneCtrl.text.isNotEmpty) 'phone': _phoneCtrl.text.trim(),
    };
    try {
      final notifier = ref.read(staffNotifierProvider.notifier);
      if (widget.existing != null) {
        await notifier.update(widget.existing!.id, data);
      } else {
        await notifier.create(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyMessage(e))),
        );
      }
    }
  }
}
