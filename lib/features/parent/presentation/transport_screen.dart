import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/features/parent/domain/parent_transport_model.dart';
import 'package:mobile_app/features/parent/providers/parent_providers.dart';
import 'package:mobile_app/features/parent/presentation/widgets/child_selector.dart';
import 'package:url_launcher/url_launcher.dart';

class ParentTransportScreen extends ConsumerWidget {
  const ParentTransportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final async = ref.watch(transportProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(title: const Text('Bus'), centerTitle: false),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(transportProvider);
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 24),
          children: [
            const ChildSelector(),
            const SizedBox(height: 12),
            async.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Text('$e', style: TextStyle(color: cs.error)),
              ),
              data: (transport) {
                if (transport == null || !transport.hasAssignment) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                    child: Column(
                      children: [
                        Icon(Icons.directions_bus_outlined,
                            size: 64,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        const Text('Not assigned to a route',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          'This child does not have a bus assigned. Contact the school office to enable transport.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      if (transport.isLive)
                        _LiveTrackingCard(tripId: transport.activeTripId!)
                      else
                        _NotLiveCard(),
                      const SizedBox(height: 12),
                      _RouteCard(transport: transport),
                      const SizedBox(height: 12),
                      if (transport.route != null)
                        _StoppagesCard(
                          stoppages: transport.route!.stoppages,
                          myStoppageId: transport.stoppage?.id,
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveTrackingCard extends ConsumerStatefulWidget {
  const _LiveTrackingCard({required this.tripId});
  final String tripId;

  @override
  ConsumerState<_LiveTrackingCard> createState() => _LiveTrackingCardState();
}

class _LiveTrackingCardState extends ConsumerState<_LiveTrackingCard> {
  GoogleMapController? _ctrl;

  @override
  void didUpdateWidget(covariant _LiveTrackingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  void _animateTo(LatLng pos) {
    _ctrl?.animateCamera(CameraUpdate.newLatLng(pos));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pingAsync = ref.watch(liveBusPingProvider(widget.tripId));
    final ping = pingAsync.valueOrNull;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            child: Row(
              children: [
                _Pulse(active: ping?.isFresh ?? false),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Live tracking',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                if (ping?.isFresh ?? false)
                  Text(
                      '${((ping!.speed ?? 0) * 3.6).toStringAsFixed(0)} km/h',
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Text(
              ping == null
                  ? 'Waiting for the bus to start the trip…'
                  : ping.isFresh
                      ? 'Updated ${_timeAgo(ping.timestamp)}'
                      : 'Last seen ${_timeAgo(ping.timestamp)} — driver may be offline.',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(14)),
            child: SizedBox(
              height: 220,
              child: ping == null
                  ? Container(
                      color: cs.surfaceContainerHigh,
                      alignment: Alignment.center,
                      child: const Text('Map will appear once the bus is moving.',
                          style: TextStyle(fontSize: 12)),
                    )
                  : Builder(
                      builder: (_) {
                        final pos = LatLng(ping.lat, ping.lng);
                        WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _animateTo(pos));
                        return GoogleMap(
                          initialCameraPosition: CameraPosition(
                              target: pos, zoom: 15.5),
                          onMapCreated: (c) => _ctrl = c,
                          markers: {
                            Marker(
                              markerId: const MarkerId('bus'),
                              position: pos,
                              infoWindow:
                                  const InfoWindow(title: 'School bus'),
                            ),
                          },
                          myLocationButtonEnabled: false,
                          mapToolbarEnabled: false,
                          zoomControlsEnabled: false,
                          compassEnabled: false,
                          liteModeEnabled: true,
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  static String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 5) return 'just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return DateFormat('h:mm a').format(t);
  }
}

class _Pulse extends StatefulWidget {
  const _Pulse({required this.active});
  final bool active;
  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (!widget.active) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            shape: BoxShape.circle),
      );
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: const Color(0xFF10B981),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color:
                  const Color(0xFF10B981).withValues(alpha: 0.4 * _c.value),
              blurRadius: 6 + 6 * _c.value,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotLiveCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cs.onSurfaceVariant.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.location_off_outlined,
                color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('No live trip running',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text('Live tracking appears when the bus starts its trip.',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.transport});
  final ParentTransport transport;

  Future<void> _dial(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.alt_route_rounded, color: cs.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(transport.route?.name ?? 'Route',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          if (transport.stoppage != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.place_rounded, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text('Stoppage: ${transport.stoppage!.name}',
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ],
          if ((transport.driverName ?? '').isNotEmpty) ...[
            const Divider(height: 24),
            _ContactRow(
              icon: Icons.person_outline_rounded,
              label: 'Driver',
              value: transport.driverName!,
              phone: transport.driverContact,
              onCall: _dial,
            ),
          ],
          if ((transport.conductorName ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            _ContactRow(
              icon: Icons.support_agent_rounded,
              label: 'Conductor',
              value: transport.conductorName!,
              phone: transport.conductorContact,
              onCall: _dial,
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.phone,
    required this.onCall,
  });
  final IconData icon;
  final String label;
  final String value;
  final String? phone;
  final Future<void> Function(String) onCall;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.onSurfaceVariant),
        const SizedBox(width: 8),
        Text('$label:',
            style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
        ),
        if ((phone ?? '').isNotEmpty)
          IconButton(
            tooltip: 'Call',
            icon: Icon(Icons.call_rounded, color: cs.primary, size: 20),
            onPressed: () => onCall(phone!),
          ),
      ],
    );
  }
}

class _StoppagesCard extends StatelessWidget {
  const _StoppagesCard({
    required this.stoppages,
    required this.myStoppageId,
  });
  final List<TransportStoppageSummary> stoppages;
  final String? myStoppageId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (stoppages.isEmpty) return const SizedBox.shrink();
    final ordered = [...stoppages]..sort((a, b) => a.order.compareTo(b.order));
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              children: [
                Icon(Icons.timeline_rounded, color: cs.primary, size: 18),
                const SizedBox(width: 8),
                const Text('Stoppages',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
          ),
          const Divider(height: 1),
          for (var i = 0; i < ordered.length; i++)
            _StoppageRow(
              stoppage: ordered[i],
              isMyStoppage: ordered[i].id == myStoppageId,
              isLast: i == ordered.length - 1,
            ),
        ],
      ),
    );
  }
}

class _StoppageRow extends StatelessWidget {
  const _StoppageRow({
    required this.stoppage,
    required this.isMyStoppage,
    required this.isLast,
  });
  final TransportStoppageSummary stoppage;
  final bool isMyStoppage;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent =
        isMyStoppage ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.6);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 1.2),
                ),
                child: Text('${stoppage.order}',
                    style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 28,
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(stoppage.name,
                    style: TextStyle(
                        fontWeight: isMyStoppage
                            ? FontWeight.w800
                            : FontWeight.w600,
                        fontSize: 14,
                        color: isMyStoppage ? cs.primary : cs.onSurface)),
                if (isMyStoppage)
                  Text('Your stoppage',
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.primary,
                          fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
