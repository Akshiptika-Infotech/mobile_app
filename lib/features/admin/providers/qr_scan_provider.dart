import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/admin/data/attendance_repository.dart';
import 'package:mobile_app/features/admin/domain/attendance_model.dart';

// ── QR scan notifier (submission + offline queue) ─────────────────────────────

class QrScanState {
  const QrScanState({
    this.lastResult,
    this.error,
    this.scannedCount = 0,
    this.offlineQueue = const [],
    this.isProcessing = false,
  });

  final QrScanResult? lastResult;
  final String? error;
  final int scannedCount;
  final List<String> offlineQueue; // raw QR strings pending retry
  final bool isProcessing;

  QrScanState copyWith({
    QrScanResult? lastResult,
    String? error,
    int? scannedCount,
    List<String>? offlineQueue,
    bool? isProcessing,
  }) =>
      QrScanState(
        lastResult: lastResult ?? this.lastResult,
        error: error,
        scannedCount: scannedCount ?? this.scannedCount,
        offlineQueue: offlineQueue ?? this.offlineQueue,
        isProcessing: isProcessing ?? this.isProcessing,
      );
}

class QrScanNotifier extends StateNotifier<QrScanState> {
  QrScanNotifier(this._repo, this._params) : super(const QrScanState()) {
    _retryTimer = Timer.periodic(const Duration(seconds: 10), (_) => _retryQueue());
  }

  final AttendanceRepository _repo;
  final QrScanParams _params;
  late final Timer _retryTimer;

  // Debounce: ignore same QR within 3 seconds
  final Map<String, DateTime> _recentScans = {};

  @override
  void dispose() {
    _retryTimer.cancel();
    super.dispose();
  }

  Future<void> scan(String rawQr) async {
    // Debounce check
    final now = DateTime.now();
    final last = _recentScans[rawQr];
    if (last != null && now.difference(last).inSeconds < 3) return;
    _recentScans[rawQr] = now;

    if (state.isProcessing) return;
    state = state.copyWith(isProcessing: true, error: null);

    try {
      final result = await _repo.submitQrScan(
        qrData: rawQr,
        date: _params.date,
        classId: _params.classId,
        academicYearId: _params.academicYearId,
        sectionId: _params.sectionId,
      );
      if (!mounted) return;
      state = state.copyWith(
        lastResult: result,
        scannedCount: state.scannedCount + 1,
        isProcessing: false,
        error: null,
      );
    } catch (e) {
      if (!mounted) return;
      // Network error → queue for retry
      if (_isNetworkError(e)) {
        state = state.copyWith(
          offlineQueue: [...state.offlineQueue, rawQr],
          isProcessing: false,
          error: 'Offline — queued for retry',
        );
      } else {
        state = state.copyWith(
          isProcessing: false,
          error: _extractError(e),
        );
      }
    }
  }

  Future<void> _retryQueue() async {
    if (state.offlineQueue.isEmpty || !mounted) return;
    final queue = List<String>.from(state.offlineQueue);
    final remaining = <String>[];

    for (final rawQr in queue) {
      try {
        await _repo.submitQrScan(
          qrData: rawQr,
          date: _params.date,
          classId: _params.classId,
          academicYearId: _params.academicYearId,
          sectionId: _params.sectionId,
        );
        if (!mounted) return;
        state = state.copyWith(scannedCount: state.scannedCount + 1);
      } catch (_) {
        remaining.add(rawQr);
      }
    }

    if (!mounted) return;
    state = state.copyWith(
      offlineQueue: remaining,
      error: remaining.isEmpty ? null : state.error,
    );
  }

  static bool _isNetworkError(Object e) {
    return e.toString().toLowerCase().contains('socket') ||
        e.toString().toLowerCase().contains('network') ||
        e.toString().toLowerCase().contains('connection');
  }

  static String _extractError(Object e) {
    final s = e.toString();
    // DioException wraps server message
    final match = RegExp(r'"error"\s*:\s*"([^"]+)"').firstMatch(s);
    return match?.group(1) ?? s;
  }
}

final qrScanNotifierProvider = StateNotifierProvider.autoDispose
    .family<QrScanNotifier, QrScanState, QrScanParams>((ref, params) {
  return QrScanNotifier(ref.watch(attendanceRepositoryProvider), params);
});

// ── Live attendance list (polling) ────────────────────────────────────────────

class QrLiveState {
  const QrLiveState({
    this.students = const [],
    this.isLoading = false,
    this.error,
  });

  final List<LiveAttendanceStudent> students;
  final bool isLoading;
  final String? error;

  int get markedCount => students.where((s) => s.isMarked).length;
  int get presentCount => students.where((s) => s.isPresent).length;

  QrLiveState copyWith({
    List<LiveAttendanceStudent>? students,
    bool? isLoading,
    String? error,
  }) =>
      QrLiveState(
        students: students ?? this.students,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class QrLiveNotifier extends StateNotifier<QrLiveState> {
  QrLiveNotifier(this._repo, this._params) : super(const QrLiveState()) {
    _fetch();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _fetch());
  }

  final AttendanceRepository _repo;
  final QrScanParams _params;
  late final Timer _pollTimer;

  @override
  void dispose() {
    _pollTimer.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    // Only show loading spinner on first fetch
    if (state.students.isEmpty) {
      state = state.copyWith(isLoading: true);
    }
    try {
      final list = await _repo.fetchQrLiveList(
        date: _params.date,
        classId: _params.classId,
        academicYearId: _params.academicYearId,
        sectionId: _params.sectionId,
      );
      if (!mounted) return;
      state = state.copyWith(students: list, isLoading: false, error: null);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _fetch();
}

final qrLiveNotifierProvider = StateNotifierProvider.autoDispose
    .family<QrLiveNotifier, QrLiveState, QrScanParams>((ref, params) {
  return QrLiveNotifier(ref.watch(attendanceRepositoryProvider), params);
});
