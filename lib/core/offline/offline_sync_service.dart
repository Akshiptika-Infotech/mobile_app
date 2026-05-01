import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/offline/offline_queue.dart';
import 'package:mobile_app/features/driver/data/driver_repository.dart';
import 'package:mobile_app/features/security/data/security_repository.dart';

/// Listens to connectivity changes and replays queued offline actions.
///
/// Register this provider at app startup so the sync loop is active
/// for the lifetime of the app:
///
/// ```dart
/// void main() {
///   WidgetsFlutterBinding.ensureInitialized();
///   final container = ProviderContainer();
///   container.read(offlineSyncServiceProvider); // start listening
///   runApp(UncontrolledProviderScope(container: container, child: MyApp()));
/// }
/// ```
class OfflineSyncService {
  OfflineSyncService(this._driverRepo, this._securityRepo) {
    _init();
  }

  final DriverRepository _driverRepo;
  final SecurityRepository _securityRepo;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isSyncing = false;

  void _init() {
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final hasNetwork = results.any(
        (r) => r == ConnectivityResult.wifi || r == ConnectivityResult.mobile,
      );
      if (hasNetwork) _sync();
    });
  }

  /// Manually trigger a sync (e.g. after user pulls-to-refresh).
  Future<void> sync() => _sync();

  Future<void> _sync() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pending = await OfflineQueue.instance.getPending();
      for (final action in pending) {
        // Max 3 retries before giving up.
        if (action.retryCount >= 3) {
          await OfflineQueue.instance.markFailed(action.id, 'Max retries exceeded');
          continue;
        }

        try {
          await _execute(action);
          await OfflineQueue.instance.markCompleted(action.id);
        } catch (e) {
          await OfflineQueue.instance.markRetry(action.id);
        }
      }

      // Clean up old failed records.
      await OfflineQueue.instance.pruneFailed();
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _execute(QueuedAction action) async {
    switch (action.actionType) {
      case 'driver_attendance':
        final tripType = action.payload['tripType'] as String?;
        final records = (action.payload['records'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>();
        if (tripType == null || records == null) throw ArgumentError('Invalid payload');
        await _driverRepo.submitAttendance(tripType, records);
      case 'security_entry_exit':
        final personName = action.payload['personName'] as String?;
        final personType = action.payload['personType'] as String?;
        final type = action.payload['type'] as String?;
        if (personName == null || personType == null || type == null) {
          throw ArgumentError('Invalid payload');
        }
        await _securityRepo.logEntryExit(
          personName: personName,
          personType: personType,
          type: type,
        );
      default:
        throw UnimplementedError('Unknown action type: ${action.actionType}');
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}

final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  final driverRepo = ref.watch(driverRepositoryProvider);
  final securityRepo = ref.watch(securityRepositoryProvider);
  return OfflineSyncService(driverRepo, securityRepo);
});
