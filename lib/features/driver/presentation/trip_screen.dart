import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobile_app/app_config.dart';
import 'package:mobile_app/features/driver/domain/driver_trip_model.dart';
import 'package:mobile_app/features/driver/providers/driver_providers.dart';
import 'package:mobile_app/features/driver/services/driver_location_service.dart';

class DriverTripScreen extends ConsumerStatefulWidget {
  const DriverTripScreen({super.key});

  @override
  ConsumerState<DriverTripScreen> createState() => _DriverTripScreenState();
}

class _DriverTripScreenState extends ConsumerState<DriverTripScreen> {
  GoogleMapController? _mapController;
  String? _trackedTripId;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Start the foreground location service for [tripId] if not already
  /// streaming for it. Called whenever an active trip becomes visible.
  void _maybeStartTracking(String tripId) {
    if (_trackedTripId == tripId) return;
    _trackedTripId = tripId;
    final svc = ref.read(driverLocationServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ok = await svc.start(tripId);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Location permission denied — live tracking is OFF.')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = ref.watch(activeTripProvider);

    if (active == null) return const _NoActiveTrip();

    _maybeStartTracking(active.id);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: Text('${active.tripType.label} Trip'),
        centerTitle: false,
      ),
      body: Consumer(builder: (context, ref, _) {
        final tripAsync = ref.watch(tripAttendanceProvider(active.id));
        return tripAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Failed to load trip\n$e',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.error)),
            ),
          ),
          data: (trip) => _TripBody(trip: trip),
        );
      }),
    );
  }
}

class _NoActiveTrip extends StatelessWidget {
  const _NoActiveTrip();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(title: const Text('Trip')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_bus_outlined,
                  size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              const Text('No trip in progress',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                'Start a Morning or Evening trip from the dashboard.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.go('/driver/dashboard'),
                icon: const Icon(Icons.dashboard_rounded),
                label: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripBody extends ConsumerWidget {
  const _TripBody({required this.trip});
  final DriverTrip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isCompleted = trip.isCompleted;
    final progress = trip.attendance.isEmpty
        ? 0.0
        : trip.markedCount / trip.attendance.length;

    // Group attendance rows by stoppage, preserving stoppage order from
    // the backend (it returns rows ordered by stoppage.order, name).
    final byStoppage = <String, List<TripAttendance>>{};
    final stopOrder = <String, String>{};
    for (final a in trip.attendance) {
      byStoppage.putIfAbsent(a.stoppageId, () => <TripAttendance>[]).add(a);
      stopOrder.putIfAbsent(a.stoppageId, () => a.stoppageName);
    }

    return Column(
      children: [
        _GpsCard(brand: AppConfigScope.of(context).primaryColor),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Row(
            children: [
              Text(
                '${trip.markedCount} / ${trip.attendance.length} marked',
                style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
              ),
              const Spacer(),
              if (isCompleted)
                const Chip(
                    label: Text('Completed',
                        style: TextStyle(fontSize: 11)),
                    avatar: Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981))),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: cs.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation(cs.primary),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: byStoppage.entries.map((entry) {
              return _StoppageGroup(
                stoppageName: stopOrder[entry.key] ?? '',
                rows: entry.value,
                trip: trip,
                disabled: isCompleted,
              );
            }).toList(),
          ),
        ),
        if (!isCompleted) _SubmitBar(trip: trip),
      ],
    );
  }
}

class _GpsCard extends ConsumerWidget {
  const _GpsCard({required this.brand});
  final Color brand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapAsync = ref.watch(driverLocationSnapshotProvider);
    final snap = snapAsync.valueOrNull;
    final pos = snap?.position;
    final tracking = snap?.isTracking ?? false;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: brand,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact map preview (~140px)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: SizedBox(
              height: 140,
              child: pos == null
                  ? Container(
                      color: brand.withValues(alpha: 0.85),
                      alignment: Alignment.center,
                      child: const Text(
                        'Acquiring GPS…',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                    )
                  : _BusMap(position: pos),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(
              children: [
                _Pulse(active: tracking),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tracking ? 'Tracking ON' : 'Tracking OFF',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                      if (pos != null)
                        Text(
                          '${pos.latitude.toStringAsFixed(5)}, '
                          '${pos.longitude.toStringAsFixed(5)} · '
                          '${(pos.speed * 3.6).toStringAsFixed(0)} km/h',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BusMap extends StatefulWidget {
  const _BusMap({required this.position});
  final Position position;

  @override
  State<_BusMap> createState() => _BusMapState();
}

class _BusMapState extends State<_BusMap> {
  GoogleMapController? _ctrl;

  @override
  void didUpdateWidget(covariant _BusMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final p = widget.position;
    _ctrl?.animateCamera(CameraUpdate.newLatLng(LatLng(p.latitude, p.longitude)));
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.position;
    final pos = LatLng(p.latitude, p.longitude);
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: pos, zoom: 15.5),
      onMapCreated: (c) => _ctrl = c,
      markers: {Marker(markerId: const MarkerId('bus'), position: pos)},
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      liteModeEnabled: true,
    );
  }
}

class _Pulse extends StatefulWidget {
  const _Pulse({required this.active});
  final bool active;
  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
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
    if (!widget.active) {
      return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
      );
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Color.lerp(Colors.white, Colors.greenAccent, _c.value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withValues(alpha: 0.4 * _c.value),
                blurRadius: 6 + 6 * _c.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StoppageGroup extends StatelessWidget {
  const _StoppageGroup({
    required this.stoppageName,
    required this.rows,
    required this.trip,
    required this.disabled,
  });
  final String stoppageName;
  final List<TripAttendance> rows;
  final DriverTrip trip;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
          child: Row(
            children: [
              Icon(Icons.place_rounded, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Text(stoppageName.isEmpty ? 'Stoppage' : stoppageName,
                  style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.2)),
              const SizedBox(width: 8),
              Text('· ${rows.length} students',
                  style: TextStyle(
                      color: cs.onSurfaceVariant, fontSize: 11)),
            ],
          ),
        ),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                _AttendanceRow(
                  row: rows[i],
                  trip: trip,
                  disabled: disabled,
                ),
                if (i < rows.length - 1)
                  const Divider(height: 1, indent: 56),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AttendanceRow extends ConsumerWidget {
  const _AttendanceRow({
    required this.row,
    required this.trip,
    required this.disabled,
  });
  final TripAttendance row;
  final DriverTrip trip;
  final bool disabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final hasPhoto = row.photoUrl != null && row.photoUrl!.isNotEmpty;
    final initial = row.studentName.isNotEmpty
        ? row.studentName[0].toUpperCase()
        : '?';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: cs.primaryContainer,
            backgroundImage:
                hasPhoto ? CachedNetworkImageProvider(row.photoUrl!) : null,
            child: !hasPhoto
                ? Text(initial,
                    style: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.studentName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(
                  '${row.admissionNumber}'
                  '${row.className != null ? ' · ${row.className} ${row.section ?? ''}' : ''}',
                  style:
                      TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          _StatusChips(
            selected: row.status,
            onSelected: disabled
                ? null
                : (s) {
                    ref
                        .read(tripAttendanceProvider(trip.id).notifier)
                        .setStatus(row.id, s);
                  },
          ),
        ],
      ),
    );
  }
}

class _StatusChips extends StatelessWidget {
  const _StatusChips({required this.selected, required this.onSelected});
  final AttendanceStatus selected;
  final ValueChanged<AttendanceStatus>? onSelected;

  static const _options = [
    (AttendanceStatus.present, 'P', Color(0xFF10B981)),
    (AttendanceStatus.absent, 'A', Color(0xFFEF4444)),
    (AttendanceStatus.notBoarded, '·', Color(0xFF9CA3AF)),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _options.map((opt) {
        final isSelected = selected == opt.$1;
        return GestureDetector(
          onTap: onSelected == null ? null : () => onSelected!(opt.$1),
          child: Container(
            margin: const EdgeInsets.only(left: 6),
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:
                  isSelected ? opt.$3 : opt.$3.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              opt.$2,
              style: TextStyle(
                color: isSelected ? Colors.white : opt.$3,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SubmitBar extends ConsumerStatefulWidget {
  const _SubmitBar({required this.trip});
  final DriverTrip trip;
  @override
  ConsumerState<_SubmitBar> createState() => _SubmitBarState();
}

class _SubmitBarState extends ConsumerState<_SubmitBar> {
  bool _busy = false;

  Future<void> _doSubmit({required bool complete}) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(tripAttendanceProvider(widget.trip.id).notifier)
          .submit(complete: complete);
      ref.invalidate(driverTripsTodayProvider);
      if (complete) {
        await ref.read(driverLocationServiceProvider).stop();
        messenger.showSnackBar(const SnackBar(
            content: Text('Trip completed — tracking stopped.')));
      } else {
        messenger.showSnackBar(
            const SnackBar(content: Text('Attendance saved.')));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final canComplete = trip.allMarked;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _busy ? null : () => _doSubmit(complete: false),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed:
                  _busy || !canComplete ? null : () => _doSubmit(complete: true),
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.flag_rounded),
              label: const Text('Complete Trip'),
            ),
          ),
        ],
      ),
    );
  }
}
