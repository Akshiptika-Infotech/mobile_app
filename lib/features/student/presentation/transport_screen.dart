import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/student/domain/student_portal_model.dart';
import 'package:mobile_app/features/student/providers/student_portal_provider.dart';

class TransportScreen extends ConsumerWidget {
  const TransportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transportAsync = ref.watch(studentTransportProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Transport'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(studentTransportProvider),
          ),
        ],
      ),
      body: transportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off_rounded,
                    size: 48,
                    color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 12),
                const Text('Failed to load transport details',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(e.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant),
                    maxLines: 3),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(studentTransportProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (info) {
          if (info == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (info.routeName.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_bus_outlined,
                      size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No transport assigned',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return _TransportBody(info: info);
        },
      ),
    );
  }
}

class _TransportBody extends StatelessWidget {
  const _TransportBody({required this.info});

  final StudentTransportInfo info;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Route card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Color(0x26009688),
                      child: Icon(Icons.directions_bus, color: Colors.teal),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Route Details',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  icon: Icons.route,
                  label: 'Route Name',
                  value: info.routeName,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // My stoppage card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Color(0x26F59E0B),
                      child: Icon(Icons.location_on,
                          color: Color(0xFFF59E0B)),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'My Stoppage',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFFF59E0B)
                            .withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    info.myStoppage,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD97706),
                        fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ),

        // All stoppages on route
        if (info.stoppages.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Color(0x263B82F6),
                        child: Icon(Icons.format_list_numbered,
                            color: Color(0xFF3B82F6)),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Route Stoppages',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...info.stoppages.map((s) => _StoppageTile(
                        stoppage: s,
                        isMyStop: s.name == info.myStoppage,
                      )),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StoppageTile extends StatelessWidget {
  const _StoppageTile({required this.stoppage, required this.isMyStop});

  final RouteStoppage stoppage;
  final bool isMyStop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isMyStop
                  ? const Color(0xFFF59E0B)
                  : Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${stoppage.order}',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isMyStop
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              stoppage.name,
              style: TextStyle(
                fontWeight:
                    isMyStop ? FontWeight.bold : FontWeight.normal,
                color: isMyStop
                    ? const Color(0xFFD97706)
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          if (isMyStop)
            const Icon(Icons.star_rounded,
                color: Color(0xFFF59E0B), size: 16),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    )),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
