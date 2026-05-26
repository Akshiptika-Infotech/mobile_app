import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/app_config.dart';
import 'package:mobile_app/features/auth/providers/auth_provider.dart';
import 'package:mobile_app/features/parent/providers/parent_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class ParentProfileScreen extends ConsumerWidget {
  const ParentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final brand = AppConfigScope.of(context).primaryColor;
    final profileAsync = ref.watch(parentProfileProvider);
    final childrenAsync = ref.watch(childrenProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(title: const Text('Profile'), centerTitle: false),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) => DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                color: brand,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.family_restroom_rounded,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.userName.isNotEmpty
                                    ? profile.userName
                                    : (profile.fatherName ??
                                        profile.motherName ??
                                        'Parent'),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800),
                              ),
                              if (profile.userEmail.isNotEmpty)
                                Text(profile.userEmail,
                                    style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.85),
                                        fontSize: 12)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text('PARENT',
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
                    const SizedBox(height: 12),
                    TabBar(
                      isScrollable: false,
                      tabs: const [
                        Tab(text: 'Father'),
                        Tab(text: 'Mother'),
                      ],
                      labelColor: Colors.white,
                      unselectedLabelColor:
                          Colors.white.withValues(alpha: 0.7),
                      indicatorColor: Colors.white,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _ParentDetailsTab(
                      name: profile.fatherName,
                      contact: profile.fatherContact,
                      email: profile.fatherEmail,
                      occupation: profile.fatherOccupation,
                      address: profile.fatherAddress,
                    ),
                    _ParentDetailsTab(
                      name: profile.motherName,
                      contact: profile.motherContact,
                      email: profile.motherEmail,
                      occupation: profile.motherOccupation,
                      address: profile.motherAddress,
                    ),
                  ],
                ),
              ),
              _ChildrenStrip(childrenAsync: childrenAsync),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _logout(context, ref),
                      icon: const Icon(Icons.logout_rounded,
                          color: Colors.red),
                      label: const Text('Logout',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dlg) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will be signed out.'),
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

class _ParentDetailsTab extends StatelessWidget {
  const _ParentDetailsTab({
    required this.name,
    required this.contact,
    required this.email,
    required this.occupation,
    required this.address,
  });

  final String? name;
  final String? contact;
  final String? email;
  final String? occupation;
  final String? address;

  bool get _isEmpty =>
      (name == null || name!.isEmpty) &&
      (contact == null || contact!.isEmpty) &&
      (email == null || email!.isEmpty) &&
      (occupation == null || occupation!.isEmpty) &&
      (address == null || address!.isEmpty);

  Future<void> _dial(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('No details on file.',
              style: TextStyle(color: cs.onSurfaceVariant)),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      children: [
        if ((name ?? '').isNotEmpty)
          _Row(icon: Icons.person_outline_rounded, label: 'Name', value: name!),
        if ((contact ?? '').isNotEmpty)
          _Row(
            icon: Icons.phone_rounded,
            label: 'Contact',
            value: contact!,
            trailing: IconButton(
              icon: Icon(Icons.call_rounded, color: cs.primary, size: 20),
              onPressed: () => _dial(contact!),
            ),
          ),
        if ((email ?? '').isNotEmpty)
          _Row(
              icon: Icons.alternate_email_rounded,
              label: 'Email',
              value: email!),
        if ((occupation ?? '').isNotEmpty)
          _Row(
              icon: Icons.work_outline_rounded,
              label: 'Occupation',
              value: occupation!),
        if ((address ?? '').isNotEmpty)
          _Row(
              icon: Icons.home_outlined,
              label: 'Address',
              value: address!),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _ChildrenStrip extends StatelessWidget {
  const _ChildrenStrip({required this.childrenAsync});
  final AsyncValue childrenAsync;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final children = (childrenAsync.value as List?) ?? const [];
    if (children.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Children',
              style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4)),
          const SizedBox(height: 6),
          Text(
            children
                .map<String>((c) =>
                    '${c.name}${c.className != null ? ' (${c.className})' : ''}')
                .join(' · '),
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
