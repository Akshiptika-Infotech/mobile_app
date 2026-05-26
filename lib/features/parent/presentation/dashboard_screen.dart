import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/app_config.dart';
import 'package:mobile_app/features/parent/providers/parent_providers.dart';
import 'package:mobile_app/features/parent/presentation/widgets/child_selector.dart';

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final brand = AppConfigScope.of(context).primaryColor;
    final profileAsync = ref.watch(parentProfileProvider);
    final matrixAsync = ref.watch(feeMatrixProvider);
    final receiptsAsync = ref.watch(receiptsProvider);
    final eventsAsync = ref.watch(calendarEventsProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Parent'),
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/parent/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(childrenProvider);
          ref.invalidate(parentProfileProvider);
          ref.invalidate(feeMatrixProvider);
          ref.invalidate(receiptsProvider);
          ref.invalidate(calendarEventsProvider);
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // Greeting card
            Container(
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
                      children: [
                        Text(
                            DateFormat('EEEE, d MMM').format(DateTime.now()),
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12)),
                        profileAsync.when(
                          data: (p) => Text(
                            p.userName.isNotEmpty
                                ? p.userName
                                : (p.fatherName ?? p.motherName ?? 'Parent'),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700),
                          ),
                          loading: () => const SizedBox(
                              height: 22, child: LinearProgressIndicator()),
                          error: (_, __) => const Text('Parent',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 2),
                        Text('Welcome back',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Child selector
            const ChildSelector(),
            const SizedBox(height: 16),

            // Stats row
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.payments_rounded,
                    label: 'Outstanding',
                    valueWidget: matrixAsync.when(
                      data: (m) => Text(
                        m == null ? '—' : _money(m.totalDue),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      loading: () => const SizedBox(
                          height: 18,
                          width: 40,
                          child: LinearProgressIndicator(minHeight: 2)),
                      error: (_, __) => const Text('—'),
                    ),
                    color: const Color(0xFFEF4444),
                    onTap: () => context.go('/parent/fees'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    icon: Icons.receipt_long_rounded,
                    label: 'Receipts',
                    valueWidget: receiptsAsync.when(
                      data: (p) => Text('${p.total}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      loading: () => const SizedBox(
                          height: 18,
                          width: 40,
                          child: LinearProgressIndicator(minHeight: 2)),
                      error: (_, __) => const Text('—'),
                    ),
                    color: const Color(0xFF10B981),
                    onTap: () => context.go('/parent/receipts'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    icon: Icons.event_rounded,
                    label: 'Events',
                    valueWidget: eventsAsync.when(
                      data: (e) => Text('${e.length}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      loading: () => const SizedBox(
                          height: 18,
                          width: 40,
                          child: LinearProgressIndicator(minHeight: 2)),
                      error: (_, __) => const Text('—'),
                    ),
                    color: const Color(0xFF6366F1),
                    onTap: () => context.go('/parent/calendar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pay fees CTA
            matrixAsync.maybeWhen(
              data: (m) {
                if (m == null || m.totalDue <= 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: FilledButton.icon(
                    onPressed: () => context.go('/parent/fees'),
                    icon: const Icon(Icons.account_balance_wallet_rounded),
                    label: Text('Pay ${_money(m.totalDue)} now'),
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),

            // Upcoming events
            _SectionTitle('Upcoming events',
                onMore: () => context.go('/parent/calendar')),
            eventsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: LinearProgressIndicator(),
              ),
              error: (e, _) =>
                  Padding(padding: const EdgeInsets.all(8), child: Text('$e')),
              data: (events) {
                if (events.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
                    child: Text('No events.',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  );
                }
                return Column(
                  children: events
                      .take(3)
                      .map((e) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: cs.outlineVariant
                                      .withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color:
                                        e.typeColor.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(Icons.event_rounded,
                                      color: e.typeColor, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(e.title,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13)),
                                      if (e.date.isNotEmpty)
                                        Text(
                                          _formatEventDate(e.date),
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: cs.onSurfaceVariant),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _money(double amount) {
    return NumberFormat.currency(
            locale: 'en_IN', symbol: '₹', decimalDigits: 0)
        .format(amount);
  }

  static String _formatEventDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat('d MMM, EEE').format(d);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.valueWidget,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Widget valueWidget;
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            border:
                Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 8),
              valueWidget,
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {required this.onMore});
  final String text;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
          ),
          TextButton(onPressed: onMore, child: const Text('See all')),
        ],
      ),
    );
  }
}
