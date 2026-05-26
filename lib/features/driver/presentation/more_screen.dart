import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_app/app_config.dart';
import 'package:mobile_app/features/auth/providers/auth_provider.dart';
import 'package:mobile_app/features/driver/data/driver_repository.dart';
import 'package:mobile_app/features/driver/providers/driver_providers.dart';
import 'package:mobile_app/features/driver/services/driver_location_service.dart';

class DriverMoreScreen extends ConsumerWidget {
  const DriverMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final brand = AppConfigScope.of(context).primaryColor;
    final profileAsync = ref.watch(driverProfileProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(title: const Text('More')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _ProfileHeader(profile: profile, brand: brand),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.camera_alt_outlined, color: cs.primary),
                    title: const Text('Change profile photo'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _pickPhoto(context, ref),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.lock_outline_rounded, color: cs.primary),
                    title: const Text('Change password'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showChangePassword(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.info_outline_rounded, color: cs.primary),
                    title: const Text('About'),
                    subtitle:
                        Text(AppConfigScope.of(context).appName),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: Colors.red),
                    title: const Text('Logout',
                        style: TextStyle(color: Colors.red)),
                    onTap: () => _logout(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final messenger = ScaffoldMessenger.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Take photo'),
              onTap: () =>
                  Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () =>
                  Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1024,
    );
    if (picked == null) return;
    final repo = ref.read(driverRepositoryProvider);
    try {
      messenger.showSnackBar(const SnackBar(
          content: Text('Uploading photo…'),
          duration: Duration(seconds: 2)));
      final url = await repo.uploadProfilePhoto(picked.path);
      await repo.updateProfilePhoto(url);
      ref.invalidate(driverProfileProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Photo updated.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  Future<void> _showChangePassword(
      BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
            'You will be signed out and tracking will be stopped.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Sign out')),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(driverLocationServiceProvider).stop();
    await ref.read(authProvider.notifier).logout();
    if (context.mounted) context.go('/login');
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.brand});
  final dynamic profile; // DriverProfile (avoid extra import here)
  final Color brand;

  @override
  Widget build(BuildContext context) {
    final initial = (profile.name as String).isNotEmpty
        ? (profile.name as String)[0].toUpperCase()
        : '?';
    final hasPhoto =
        profile.imageUrl != null && (profile.imageUrl as String).isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: brand,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white24,
            backgroundImage: hasPhoto
                ? CachedNetworkImageProvider(profile.imageUrl as String)
                : null,
            child: hasPhoto
                ? null
                : Text(initial,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.name as String,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(profile.email as String,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text('DRIVER',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();
  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState
    extends ConsumerState<_ChangePasswordDialog> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_newCtrl.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'New passwords do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(driverRepositoryProvider).changePassword(
            currentPassword: _currentCtrl.text,
            newPassword: _newCtrl.text,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password changed.')));
      }
    } catch (e) {
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
              controller: _currentCtrl,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Current password')),
          const SizedBox(height: 8),
          TextField(
              controller: _newCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password')),
          const SizedBox(height: 8),
          TextField(
              controller: _confirmCtrl,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Confirm new password')),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Change')),
      ],
    );
  }
}
