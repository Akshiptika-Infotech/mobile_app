import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/features/auth/providers/auth_provider.dart';
import 'package:mobile_app/features/web_admin/presentation/mandatory_disclosure_screen.dart';
import 'package:mobile_app/features/web_admin/presentation/pages_screen.dart';
import 'package:mobile_app/features/web_admin/presentation/website_settings_screen.dart';

class WebAdminMoreScreen extends ConsumerWidget {
  const WebAdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: cs.primary,
                  child: Text(
                    (user?.name.isNotEmpty == true)
                        ? user!.name[0].toUpperCase()
                        : 'W',
                    style: TextStyle(
                        color: cs.onPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Web Admin',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: cs.onPrimaryContainer),
                      ),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onPrimaryContainer
                                .withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Content management
          const _SectionLabel('Content Management'),
          _MenuTile(
            icon: Icons.web_outlined,
            label: 'Web Pages',
            subtitle: 'Manage custom website pages',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PagesScreen()),
            ),
          ),
          _MenuTile(
            icon: Icons.description_outlined,
            label: 'Mandatory Disclosure',
            subtitle: 'General info, staff, infrastructure & results',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const MandatoryDisclosureScreen()),
            ),
          ),
          _MenuTile(
            icon: Icons.settings_outlined,
            label: 'Website Settings',
            subtitle: 'School info, contact & social links',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const WebsiteSettingsScreen()),
            ),
          ),
          const SizedBox(height: 8),

          // Account
          const _SectionLabel('Account'),
          _MenuTile(
            icon: Icons.person_outlined,
            label: 'Profile',
            subtitle: 'View and edit your profile',
            onTap: () => context.go('/web-admin/profile'),
          ),
          _MenuTile(
            icon: Icons.logout_outlined,
            label: 'Sign Out',
            subtitle: 'Log out of the app',
            iconColor: cs.error,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              }
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      elevation: 0,
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? cs.primary),
        title: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: subtitle != null
            ? Text(subtitle!,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant))
            : null,
        trailing:
            const Icon(Icons.chevron_right_outlined, size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
