import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/app_config.dart';
import 'package:mobile_app/features/auth/providers/auth_provider.dart';
import 'package:mobile_app/features/parent/providers/parent_providers.dart';

/// "More" tab for the parent shell — a grid of secondary destinations
/// (Receipts, Calendar, Timetable, Profile) plus About + Logout.
class ParentMoreScreen extends ConsumerWidget {
  const ParentMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final brand = AppConfigScope.of(context).primaryColor;
    final profileAsync = ref.watch(parentProfileProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          profileAsync.when(
            loading: () => const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox.shrink(),
            data: (p) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: brand,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.family_restroom_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                            p.userName.isNotEmpty
                                ? p.userName
                                : (p.fatherName ?? p.motherName ?? 'Parent'),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold)),
                        if (p.userEmail.isNotEmpty)
                          Text(p.userEmail,
                              style: TextStyle(
                                  color:
                                      Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.95,
            children: [
              _Tile(
                icon: Icons.receipt_long_rounded,
                label: 'Receipts',
                color: const Color(0xFF10B981),
                onTap: () => context.push('/parent/receipts'),
              ),
              _Tile(
                icon: Icons.event_rounded,
                label: 'Calendar',
                color: const Color(0xFF6366F1),
                onTap: () => context.push('/parent/calendar'),
              ),
              _Tile(
                icon: Icons.schedule_rounded,
                label: 'Timetable',
                color: const Color(0xFFF59E0B),
                onTap: () => context.push('/parent/timetable'),
              ),
              _Tile(
                icon: Icons.person_rounded,
                label: 'Profile',
                color: const Color(0xFF8B5CF6),
                onTap: () => context.push('/parent/profile'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline_rounded,
                      color: cs.primary),
                  title: const Text('About'),
                  subtitle: Text(AppConfigScope.of(context).appName),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded,
                      color: Colors.red),
                  title: const Text('Logout',
                      style: TextStyle(color: Colors.red)),
                  onTap: () => _logout(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dlg) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will be signed out of this account.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dlg, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(dlg, true),
              child: const Text('Sign out')),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(authProvider.notifier).logout();
    if (context.mounted) context.go('/login');
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border:
                Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
