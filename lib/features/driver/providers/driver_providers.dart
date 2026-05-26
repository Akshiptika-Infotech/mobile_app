import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/driver/data/driver_repository.dart';
import 'package:mobile_app/features/driver/domain/driver_profile_model.dart';
import 'package:mobile_app/features/driver/domain/driver_route_model.dart';
import 'package:mobile_app/features/driver/domain/driver_trip_model.dart';

// ── Route ─────────────────────────────────────────────────────────────────────

final driverRouteProvider =
    FutureProvider.autoDispose<DriverRoute?>((ref) async {
  return ref.watch(driverRepositoryProvider).fetchRoute();
});

// ── Today's trips ─────────────────────────────────────────────────────────────

final driverTripsTodayProvider =
    FutureProvider.autoDispose<List<DriverTrip>>((ref) async {
  return ref
      .watch(driverRepositoryProvider)
      .fetchTripsForDate(DateTime.now());
});

/// Convenience: the trip currently `IN_PROGRESS`, if any.
final activeTripProvider = Provider.autoDispose<DriverTrip?>((ref) {
  final trips = ref.watch(driverTripsTodayProvider).value ?? const [];
  for (final t in trips) {
    if (t.isActive) return t;
  }
  return null;
});

// ── Trip detail (attendance) ──────────────────────────────────────────────────

final tripAttendanceProvider = StateNotifierProvider.autoDispose
    .family<TripAttendanceNotifier, AsyncValue<DriverTrip>, String>(
        (ref, tripId) {
  return TripAttendanceNotifier(
    repo: ref.watch(driverRepositoryProvider),
    tripId: tripId,
  )..load();
});

class TripAttendanceNotifier extends StateNotifier<AsyncValue<DriverTrip>> {
  TripAttendanceNotifier({required this.repo, required this.tripId})
      : super(const AsyncValue.loading());

  final DriverRepository repo;
  final String tripId;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final trip = await repo.fetchTripAttendance(tripId);
      if (!mounted) return;
      state = AsyncValue.data(trip);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  /// Locally toggles a student's status. The new value is held in memory
  /// until `submit()` is called.
  void setStatus(String attendanceId, AttendanceStatus status) {
    final current = state.value;
    if (current == null) return;
    final updated = current.attendance.map((a) {
      return a.id == attendanceId ? a.copyWith(status: status) : a;
    }).toList();
    state = AsyncValue.data(current.copyWith(attendance: updated));
  }

  /// Pushes pending changes to the backend. If `complete` is true and every
  /// student has a non-NOT_BOARDED status, the backend marks the trip
  /// `COMPLETED`.
  Future<void> submit({bool complete = false}) async {
    final current = state.value;
    if (current == null) return;
    await repo.updateTripAttendance(
      tripId: tripId,
      rows: current.attendance,
      complete: complete,
    );
    if (complete) {
      state = AsyncValue.data(current.copyWith(status: TripStatus.completed));
    }
  }
}

// ── Start trip ────────────────────────────────────────────────────────────────

final startTripControllerProvider =
    Provider.autoDispose<StartTripController>((ref) {
  return StartTripController(ref);
});

class StartTripController {
  StartTripController(this._ref);
  final Ref _ref;

  Future<DriverTrip> start({
    required String routeId,
    required TripType type,
  }) async {
    final trip = await _ref.read(driverRepositoryProvider).startTrip(
          routeId: routeId,
          date: DateTime.now(),
          tripType: type,
        );
    // Refresh today's trips so dashboard reflects the new state.
    _ref.invalidate(driverTripsTodayProvider);
    return trip;
  }
}

// ── Profile ───────────────────────────────────────────────────────────────────

final driverProfileProvider =
    FutureProvider.autoDispose<DriverProfile>((ref) async {
  return ref.watch(driverRepositoryProvider).fetchProfile();
});
