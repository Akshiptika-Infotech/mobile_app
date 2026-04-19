import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/driver/data/driver_repository.dart';
import 'package:mobile_app/features/driver/domain/driver_model.dart';

// ── Trip & Route ──────────────────────────────────────────────────────────────

final driverTripProvider = FutureProvider.autoDispose<DriverTrip>((ref) {
  return ref.watch(driverRepositoryProvider).fetchTrip();
});

final driverRouteProvider = FutureProvider.autoDispose<DriverRoute>((ref) {
  return ref.watch(driverRepositoryProvider).fetchRoute();
});

final driverStudentsProvider =
    FutureProvider.autoDispose<List<DriverStudent>>((ref) {
  return ref.watch(driverRepositoryProvider).fetchStudents();
});

// ── Bus attendance state ───────────────────────────────────────────────────────

class BusAttendanceState {
  const BusAttendanceState({
    this.tripType = 'morning',
    this.students = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.submitted = false,
    this.error,
  });

  final String tripType; // 'morning' | 'afternoon'
  final List<DriverStudent> students;
  final bool isLoading;
  final bool isSubmitting;
  final bool submitted;
  final String? error;

  BusAttendanceState copyWith({
    String? tripType,
    List<DriverStudent>? students,
    bool? isLoading,
    bool? isSubmitting,
    bool? submitted,
    String? error,
  }) {
    return BusAttendanceState(
      tripType: tripType ?? this.tripType,
      students: students ?? this.students,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitted: submitted ?? this.submitted,
      error: error,
    );
  }
}

class BusAttendanceNotifier extends StateNotifier<BusAttendanceState> {
  BusAttendanceNotifier(this._repo) : super(const BusAttendanceState()) {
    load('morning');
  }

  final DriverRepository _repo;

  Future<void> load(String tripType) async {
    if (!mounted) return;
    state = state.copyWith(tripType: tripType, isLoading: true, students: []);
    try {
      final students = await _repo.fetchAttendance(tripType);
      if (!mounted) return;
      final alreadySubmitted = students.isNotEmpty &&
          students.every((s) =>
              s.status == 'present' ||
              s.status == 'absent' ||
              s.status == 'not_boarded');
      state = state.copyWith(
          students: students, isLoading: false, submitted: alreadySubmitted);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setStatus(String studentId, String status) {
    if (!mounted) return;
    final updated = state.students.map((s) {
      if (s.id == studentId) s.status = status;
      return s;
    }).toList();
    state = state.copyWith(students: updated);
  }

  void markAll(String status) {
    if (!mounted) return;
    for (final s in state.students) {
      s.status = status;
    }
    state = state.copyWith(students: List.from(state.students));
  }

  Future<void> submit() async {
    if (!mounted) return;
    state = state.copyWith(isSubmitting: true);
    try {
      final records = state.students.map((s) => s.toJson()).toList();
      await _repo.submitAttendance(state.tripType, records);
      if (!mounted) return;
      state = state.copyWith(isSubmitting: false, submitted: true);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isSubmitting: false, error: e.toString());
    }
  }
}

final busAttendanceProvider = StateNotifierProvider.autoDispose<
    BusAttendanceNotifier, BusAttendanceState>((ref) {
  return BusAttendanceNotifier(ref.watch(driverRepositoryProvider));
});
