import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/features/security/data/security_repository.dart';
import 'package:mobile_app/features/security/domain/security_enums.dart';
import 'package:mobile_app/features/security/domain/security_visitor_model.dart';
import 'package:mobile_app/features/security/providers/security_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class SecurityVisitorsScreen extends ConsumerWidget {
  const SecurityVisitorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final visitorsAsync = ref.watch(visitorsProvider);
    final date = ref.watch(selectedDateProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Visitors'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/security/visitors/new'),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Register'),
      ),
      body: Column(
        children: [
          _DateBar(date: date, ref: ref),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(visitorsProvider);
                await Future.delayed(const Duration(milliseconds: 300));
              },
              child: visitorsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ListView(children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Error: $e', style: TextStyle(color: cs.error)),
                  ),
                ]),
                data: (visitors) {
                  if (visitors.isEmpty) {
                    return ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                          child: Column(
                            children: [
                              Icon(Icons.people_outline_rounded,
                                  size: 64,
                                  color: cs.onSurfaceVariant
                                      .withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              const Text('No visitors today',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(
                                'Tap Register to add a new visitor.',
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    itemCount: visitors.length,
                    itemBuilder: (_, i) => _VisitorCard(visitor: visitors[i]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateBar extends StatelessWidget {
  const _DateBar({required this.date, required this.ref});
  final DateTime date;
  final WidgetRef ref;

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ref.read(selectedDateProvider.notifier).state =
          DateTime(picked.year, picked.month, picked.day);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 18, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              DateFormat('EEEE, d MMMM yyyy').format(date),
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                  fontSize: 14),
            ),
          ),
          TextButton(onPressed: () => _pick(context), child: const Text('Change')),
        ],
      ),
    );
  }
}

class _VisitorCard extends ConsumerStatefulWidget {
  const _VisitorCard({required this.visitor});
  final SecurityVisitor visitor;

  @override
  ConsumerState<_VisitorCard> createState() => _VisitorCardState();
}

class _VisitorCardState extends ConsumerState<_VisitorCard> {
  bool _busy = false;

  Future<void> _checkout() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(securityRepositoryProvider)
          .checkoutVisitor(widget.visitor.id);
      ref.invalidate(visitorsProvider);
      ref.invalidate(entryExitLogsProvider);
      messenger.showSnackBar(
          SnackBar(content: Text('${widget.visitor.fullName} checked out.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Check-out failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final v = widget.visitor;
    final isInside = v.isInside;
    final initial =
        v.fullName.isNotEmpty ? v.fullName[0].toUpperCase() : '?';
    final hasPhoto = (v.imagePath ?? '').isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: cs.primaryContainer,
                  backgroundImage: hasPhoto
                      ? CachedNetworkImageProvider(v.imagePath!)
                      : null,
                  child: !hasPhoto
                      ? Text(initial,
                          style: TextStyle(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 18))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.fullName,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(v.purposeOfVisit,
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                _StatusPill(isInside: isInside),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _Meta(icon: Icons.phone_rounded, label: v.phone),
                if ((v.personToMeet ?? '').isNotEmpty)
                  _Meta(
                      icon: Icons.person_pin_rounded,
                      label: 'To meet: ${v.personToMeet}'),
                if ((v.vehicleNumber ?? '').isNotEmpty)
                  _Meta(
                      icon: Icons.directions_car_rounded,
                      label: v.vehicleNumber!),
                if (v.latestLog != null)
                  _Meta(
                      icon: v.latestLog!.logType == LogType.entry
                          ? Icons.login_rounded
                          : Icons.logout_rounded,
                      label:
                          '${v.latestLog!.logType.label} at ${DateFormat('h:mm a').format(v.latestLog!.loggedAt)}'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _call(v.phone),
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text('Call'),
                  style: _compactStyle,
                ),
                const SizedBox(width: 8),
                if (isInside)
                  FilledButton.icon(
                    onPressed: _busy ? null : _checkout,
                    icon: _busy
                        ? const SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.logout_rounded, size: 16),
                    label: const Text('Check out'),
                    style: _compactStyle,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static final ButtonStyle _compactStyle = ButtonStyle(
    minimumSize: WidgetStateProperty.all(const Size(0, 38)),
    padding: WidgetStateProperty.all(
      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    ),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: cs.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isInside});
  final bool isInside;

  @override
  Widget build(BuildContext context) {
    final color = isInside ? const Color(0xFF10B981) : const Color(0xFF9CA3AF);
    final label = isInside ? 'Inside' : 'Out';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.3)),
    );
  }
}
