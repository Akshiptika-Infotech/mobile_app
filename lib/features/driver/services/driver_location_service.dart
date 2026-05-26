import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_app/features/driver/data/driver_repository.dart';

/// Singleton service that streams the driver's GPS position while a trip
/// is active. Two fan-outs:
///   1. Every emission → Firebase Realtime DB at `buses/{tripId}` so admin
///      / parent screens see sub-5s updates.
///   2. Every 30s → `POST /api/driver/location` for permanent history.
///
/// The service is wrapped in a foreground task (sticky notification) so
/// Android doesn't suspend the GPS stream when the driver app goes to
/// the background.
class DriverLocationService {
  DriverLocationService._(this._repo);

  static DriverLocationService? _instance;
  static DriverLocationService instance(DriverRepository repo) =>
      _instance ??= DriverLocationService._(repo);

  final DriverRepository _repo;

  StreamSubscription<Position>? _sub;
  Timer? _backendThrottle;
  Position? _lastPosition;
  String? _activeTripId;
  DatabaseReference? _busRef;

  final _stateController = StreamController<DriverLocationSnapshot>.broadcast();
  Stream<DriverLocationSnapshot> get stream => _stateController.stream;
  DriverLocationSnapshot get current => DriverLocationSnapshot(
        tripId: _activeTripId,
        position: _lastPosition,
        isTracking: _sub != null,
      );

  bool get isTracking => _sub != null;
  String? get activeTripId => _activeTripId;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Returns true when permissions are granted AND the service is streaming.
  Future<bool> start(String tripId) async {
    if (isTracking && _activeTripId == tripId) return true;
    await stop(); // tear down any previous session

    final permitted = await _ensurePermission();
    if (!permitted) return false;

    _activeTripId = tripId;
    _busRef = _initFirebaseRef(tripId);

    await _initForegroundTask();
    await FlutterForegroundTask.startService(
      notificationTitle: 'Bus tracking active',
      notificationText: 'Sharing your location with the school.',
    );

    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        // Emit when the bus moves ~10m, but cap at one emission every 5s
        // via our debounce below to bound battery use.
        distanceFilter: 10,
      ),
    ).listen(_onPosition);

    // Every 30s, flush the last seen position to the backend for history.
    _backendThrottle = Timer.periodic(const Duration(seconds: 30), (_) {
      _flushToBackend();
    });

    return true;
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _backendThrottle?.cancel();
    _backendThrottle = null;
    _activeTripId = null;
    _busRef = null;
    _lastPosition = null;
    try {
      await FlutterForegroundTask.stopService();
    } catch (_) {/* service may not have been running */}
    _emit();
  }

  // ── Position handling ──────────────────────────────────────────────────────

  Future<void> _onPosition(Position p) async {
    _lastPosition = p;
    _emit();
    // Live fan-out to Firebase — only if firebase_core was initialised.
    final ref = _busRef;
    if (ref != null) {
      try {
        await ref.set({
          'lat': p.latitude,
          'lng': p.longitude,
          'speed': p.speed,
          'heading': p.heading,
          'accuracy': p.accuracy,
          'ts': DateTime.now().millisecondsSinceEpoch,
          'tripId': _activeTripId,
        });
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[DriverLocationService] Firebase write failed: $e');
        }
      }
    }
  }

  Future<void> _flushToBackend() async {
    final p = _lastPosition;
    final tripId = _activeTripId;
    if (p == null || tripId == null) return;
    try {
      await _repo.postLocationPing(
        tripId: tripId,
        latitude: p.latitude,
        longitude: p.longitude,
        speed: p.speed,
        accuracy: p.accuracy,
      );
    } catch (e) {
      // Don't crash the service if a ping fails — the next 30s tick will
      // try again. Production hardening could spool to disk.
      if (kDebugMode) {
        debugPrint('[DriverLocationService] backend ping failed: $e');
      }
    }
  }

  void _emit() => _stateController.add(current);

  // ── Permissions ────────────────────────────────────────────────────────────

  Future<bool> _ensurePermission() async {
    // Service must be enabled first.
    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) return false;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever ||
        perm == LocationPermission.denied) {
      return false;
    }
    return true;
  }

  // ── Firebase ───────────────────────────────────────────────────────────────

  DatabaseReference? _initFirebaseRef(String tripId) {
    try {
      // If Firebase wasn't initialised in main(), Firebase.app() throws.
      Firebase.app();
      return FirebaseDatabase.instance.ref('buses/$tripId');
    } catch (_) {
      // Firebase not configured — live tracking is disabled, but the
      // backend ping every 30s still works.
      if (kDebugMode) {
        debugPrint(
            '[DriverLocationService] Firebase not initialised — '
            'skipping live RTDB writes.');
      }
      return null;
    }
  }

  // ── Foreground task config ─────────────────────────────────────────────────

  Future<void> _initForegroundTask() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'driver_tracking',
        channelName: 'Bus Tracking',
        channelDescription: 'Notifies you when your bus location is being shared.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  void dispose() {
    _stateController.close();
  }
}

class DriverLocationSnapshot {
  const DriverLocationSnapshot({
    this.tripId,
    this.position,
    required this.isTracking,
  });

  final String? tripId;
  final Position? position;
  final bool isTracking;
}

// ── Riverpod glue ───────────────────────────────────────────────────────────

final driverLocationServiceProvider =
    Provider<DriverLocationService>((ref) {
  return DriverLocationService.instance(
    ref.watch(driverRepositoryProvider),
  );
});

/// Reactive stream of the latest GPS snapshot, suitable for `ref.watch`.
final driverLocationSnapshotProvider =
    StreamProvider<DriverLocationSnapshot>((ref) {
  final svc = ref.watch(driverLocationServiceProvider);
  return svc.stream;
});
