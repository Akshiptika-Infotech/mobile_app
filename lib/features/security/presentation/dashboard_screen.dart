import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/app_config.dart';
import 'package:mobile_app/features/security/domain/entry_exit_log_model.dart';
import 'package:mobile_app/features/security/domain/security_enums.dart';
import 'package:mobile_app/features/security/providers/security_providers.dart';

class SecurityDashboardScreen extends ConsumerWidget {
  const SecurityDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final brand = AppConfigScope.of(context).primaryColor;
    final profileAsync = ref.watch(securityProfileProvider);
    final logsAsync = ref.watch(entryExitLogsProvider);
    final visitorsAsync = ref.watch(visitorsProvider);
    final passesAsync = ref.watch(activeGatePassesProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Security'),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(entryExitLogsProvider);
          ref.invalidate(visitorsProvider);
          ref.invalidate(activeGatePassesProvider);
          ref.invalidate(securityProfileProvider);
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _Greeting(profileAsync: profileAsync, brand: brand),
            const SizedBox(height: 16),
            _StatsRow(
              logsAsync: logsAsync,
              visitorsAsync: visitorsAsync,
            ),
            const SizedBox(height: 16),
            _ActivePassesCard(passesAsync: passesAsync, brand: brand),
            const SizedBox(height: 16),
            _QuickActions(brand: brand),
            const SizedBox(height: 16),
            _RecentActivity(logsAsync: logsAsync),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.profileAsync, required this.brand});
  final AsyncValue profileAsync;
  final Color brand;

  @override
  Widget build(BuildContext context) {
    final greeting = _greetingFor(DateTime.now().hour);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: brand,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          profileAsync.when(
            data: (p) => _GreetingAvatar(imageUrl: p.imageUrl, name: p.name),
            loading: () => const CircleAvatar(
                radius: 26, backgroundColor: Colors.white24),
            error: (_, __) => const CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white24,
              child: Icon(Icons.shield_rounded,
                  color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13)),
                profileAsync.when(
                  data: (p) => Text(p.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  loading: () => const SizedBox(
                      height: 22, child: LinearProgressIndicator()),
                  error: (_, __) => const Text('Guard',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                ),
                Text(DateFormat('EEEE, d MMM').format(DateTime.now()),
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _greetingFor(int h) {
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _GreetingAvatar extends StatelessWidget {
  const _GreetingAvatar({required this.imageUrl, required this.name});
  final String? imageUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = imageUrl != null && imageUrl!.isNotEmpty;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
    return CircleAvatar(
      radius: 26,
      backgroundColor: Colors.white24,
      backgroundImage:
          hasPhoto ? CachedNetworkImageProvider(imageUrl!) : null,
      child: hasPhoto
          ? null
          : Text(initial,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.logsAsync,
    required this.visitorsAsync,
  });
  final AsyncValue<List<EntryExitLog>> logsAsync;
  final AsyncValue visitorsAsync;

  @override
  Widget build(BuildContext context) {
    final logs = logsAsync.valueOrNull ?? const [];
    final visitors = (visitorsAsync.valueOrNull as List?) ?? const [];
    final entries = logs.where((l) => l.logType == LogType.entry).length;
    final exits = logs.where((l) => l.logType == LogType.exit).length;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.people_alt_rounded,
            label: 'Visitors',
            value: '${visitors.length}',
            color: const Color(0xFF6366F1),
            isLoading: visitorsAsync.isLoading,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.login_rounded,
            label: 'Entries',
            value: '$entries',
            color: const Color(0xFF10B981),
            isLoading: logsAsync.isLoading,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.logout_rounded,
            label: 'Exits',
            value: '$exits',
            color: const Color(0xFFEF4444),
            isLoading: logsAsync.isLoading,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isLoading,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          isLoading
              ? const SizedBox(
                  height: 22,
                  width: 30,
                  child: LinearProgressIndicator(minHeight: 2))
              : Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface)),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActivePassesCard extends StatelessWidget {
  const _ActivePassesCard({required this.passesAsync, required this.brand});
  final AsyncValue passesAsync;
  final Color brand;

  @override
  Widget build(BuildContext context) {
    final passes = (passesAsync.valueOrNull as List?) ?? const [];
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.go('/security/gate-passes'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
                color:
                    Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: brand.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.qr_code_2_rounded, color: brand),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Active gate passes',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      passesAsync.isLoading
                          ? 'Loading…'
                          : '${passes.length} currently approved',
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.brand});
  final Color brand;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: Icons.person_add_alt_1_rounded,
            label: 'Register\nvisitor',
            color: brand,
            onTap: () => context.push('/security/visitors/new'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            icon: Icons.swap_horiz_rounded,
            label: 'Log entry\n/ exit',
            color: const Color(0xFF6366F1),
            onTap: () => context.push('/security/entry-exit/new'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Scan gate\npass',
            color: const Color(0xFFF59E0B),
            onTap: () => context.push(
              '/security/entry-exit/new',
              extra: const {'scanFirst': true},
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
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
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            border:
                Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.logsAsync});
  final AsyncValue<List<EntryExitLog>> logsAsync;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final logs = (logsAsync.valueOrNull ?? const [])
        .take(5)
        .toList();
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Recent activity',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                TextButton(
                  onPressed: () => context.go('/security/entry-exit'),
                  child: const Text('See all'),
                ),
              ],
            ),
          ),
          if (logsAsync.isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            )
          else if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text('No activity today.',
                  style: TextStyle(color: cs.onSurfaceVariant)),
            )
          else
            ...logs.map((l) => _LogRow(log: l)),
        ],
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.log});
  final EntryExitLog log;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEntry = log.logType == LogType.entry;
    final color = isEntry ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEntry ? Icons.login_rounded : Icons.logout_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.personName ?? '—',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(
                  '${log.personType.label}'
                  '${log.personDetail != null ? ' · ${log.personDetail}' : ''}',
                  style:
                      TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(DateFormat('h:mm a').format(log.loggedAt),
              style:
                  TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
