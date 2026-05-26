import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile_app/features/driver/domain/driver_route_model.dart';
import 'package:mobile_app/features/driver/providers/driver_providers.dart';

class DriverRouteScreen extends ConsumerWidget {
  const DriverRouteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final routeAsync = ref.watch(driverRouteProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(title: const Text('My Route')),
      body: routeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to load route\n$e',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.error)),
          ),
        ),
        data: (route) {
          if (route == null) return const _EmptyRoute();
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(driverRouteProvider);
              await Future.delayed(const Duration(milliseconds: 300));
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _Header(route: route),
                const SizedBox(height: 16),
                ...route.stoppages.map((s) => _StoppageCard(stoppage: s)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyRoute extends StatelessWidget {
  const _EmptyRoute();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.alt_route_rounded,
                size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text('No route assigned yet',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Please contact the school office to be assigned to a route.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.route});
  final DriverRoute route;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasConductor = (route.conductorName ?? '').isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_bus_rounded, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(route.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            if ((route.description ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(route.description!,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _Stat(
                    icon: Icons.place_outlined,
                    label: '${route.stoppages.length} stops'),
                _Stat(
                    icon: Icons.groups_outlined,
                    label: '${route.totalStudents} students'),
              ],
            ),
            if (hasConductor) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.person_outline_rounded, color: cs.onSurfaceVariant, size: 18),
                  const SizedBox(width: 8),
                  Text('Conductor:',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(route.conductorName!,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  if ((route.conductorContact ?? '').isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.phone_rounded, color: cs.primary),
                      onPressed: () => _dial(route.conductorContact!),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Future<void> _dial(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onPrimaryContainer),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: cs.onPrimaryContainer,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StoppageCard extends StatefulWidget {
  const _StoppageCard({required this.stoppage});
  final DriverStoppage stoppage;

  @override
  State<_StoppageCard> createState() => _StoppageCardState();
}

class _StoppageCardState extends State<_StoppageCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = widget.stoppage;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: cs.primary,
                      child: Text('${s.order}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                          Text('${s.students.length} students',
                              style: TextStyle(
                                  fontSize: 12, color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Icon(_expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded),
                  ],
                ),
              ),
            ),
            if (_expanded) ...[
              const Divider(),
              ...s.students.map((st) => _StudentTile(student: st)),
            ],
          ],
        ),
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({required this.student});
  final DriverRouteStudent student;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initial = student.name.isNotEmpty
        ? student.name[0].toUpperCase()
        : '?';
    final hasPhoto =
        student.photoUrl != null && student.photoUrl!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: cs.primaryContainer,
            backgroundImage:
                hasPhoto ? CachedNetworkImageProvider(student.photoUrl!) : null,
            child: !hasPhoto
                ? Text(initial,
                    style: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 12))
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(
                  '${student.admissionNumber}'
                  '${student.className != null ? ' · ${student.className} ${student.section ?? ''}' : ''}',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
