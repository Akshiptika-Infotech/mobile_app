import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/admin/domain/calendar_model.dart';
import 'package:mobile_app/features/admin/domain/class_model.dart';
import 'package:mobile_app/features/admin/domain/timetable_model.dart';
import 'package:mobile_app/features/admin/providers/academic_year_provider.dart';
import 'package:mobile_app/features/parent/data/parent_repository.dart';
import 'package:mobile_app/features/parent/domain/child_model.dart';
import 'package:mobile_app/features/parent/domain/fee_matrix_model.dart';
import 'package:mobile_app/features/parent/domain/parent_profile_model.dart';
import 'package:mobile_app/features/parent/domain/parent_receipt_model.dart';
import 'package:mobile_app/features/parent/domain/parent_transport_model.dart';
import 'package:mobile_app/features/parent/domain/student_attendance_model.dart';

// ── Children ──────────────────────────────────────────────────────────────────

final childrenProvider =
    FutureProvider.autoDispose<List<ParentChild>>((ref) async {
  return ref.watch(parentRepositoryProvider).fetchChildren();
});

/// The currently selected child id. Persisted across the parent session;
/// initialised by the dashboard once children are fetched.
final selectedChildIdProvider = StateProvider<String?>((ref) => null);

/// Convenience: the currently selected child object, or null if none yet.
final selectedChildProvider = Provider.autoDispose<ParentChild?>((ref) {
  final children = ref.watch(childrenProvider).value ?? const <ParentChild>[];
  final id = ref.watch(selectedChildIdProvider);
  if (children.isEmpty) return null;
  if (id == null) return children.first;
  return children.firstWhere(
    (c) => c.id == id,
    orElse: () => children.first,
  );
});

// ── Profile ───────────────────────────────────────────────────────────────────

final parentProfileProvider =
    FutureProvider.autoDispose<ParentProfile>((ref) async {
  return ref.watch(parentRepositoryProvider).fetchProfile();
});

// ── Selected academic year ────────────────────────────────────────────────────

/// Defaults to the active academic year. The fees + receipts screens let the
/// parent change it.
final selectedYearProvider = StateProvider<AcademicYear?>((ref) {
  final years = ref.watch(academicYearsProvider).value ?? const [];
  if (years.isEmpty) return null;
  return years.firstWhere(
    (y) => y.isActive,
    orElse: () => years.first,
  );
});

// ── Fee matrix (per child + year) ─────────────────────────────────────────────

final feeMatrixProvider = FutureProvider.autoDispose<FeeMatrix?>((ref) async {
  final child = ref.watch(selectedChildProvider);
  final year = ref.watch(selectedYearProvider);
  if (child == null || year == null) return null;
  return ref.watch(parentRepositoryProvider).fetchMatrix(
        studentId: child.id,
        academicYearId: year.id,
      );
});

// ── Receipts (per child + year) ───────────────────────────────────────────────

final receiptsProvider =
    FutureProvider.autoDispose<ParentReceiptsPage>((ref) async {
  final child = ref.watch(selectedChildProvider);
  final year = ref.watch(selectedYearProvider);
  return ref.watch(parentRepositoryProvider).fetchReceipts(
        studentId: child?.id,
        academicYearId: year?.id,
      );
});

// ── Calendar ──────────────────────────────────────────────────────────────────

/// Currently visible calendar month (1-12 + year). Defaults to current month.
final calendarMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final calendarEventsProvider =
    FutureProvider.autoDispose<List<CalendarEvent>>((ref) async {
  final child = ref.watch(selectedChildProvider);
  if (child == null) return const [];
  final month = ref.watch(calendarMonthProvider);
  final yyyyMm =
      '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';
  return ref
      .watch(parentRepositoryProvider)
      .fetchCalendar(studentId: child.id, monthYyyyMm: yyyyMm);
});

// ── Timetable ─────────────────────────────────────────────────────────────────

final timetableProvider =
    FutureProvider.autoDispose<List<TimetablePeriod>>((ref) async {
  final child = ref.watch(selectedChildProvider);
  if (child == null) return const [];
  return ref.watch(parentRepositoryProvider).fetchTimetable(child.id);
});

// ── Attendance ────────────────────────────────────────────────────────────────

/// Currently visible attendance month — defaults to the current month.
final attendanceMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final attendanceProvider = FutureProvider.autoDispose<
    ({List<StudentAttendanceDay> days, StudentAttendanceSummary summary})>((ref) async {
  final child = ref.watch(selectedChildProvider);
  if (child == null) {
    return (
      days: <StudentAttendanceDay>[],
      summary: const StudentAttendanceSummary(
        present: 0, absent: 0, late: 0, leave: 0, totalMarked: 0),
    );
  }
  final m = ref.watch(attendanceMonthProvider);
  final yyyyMm =
      '${m.year.toString().padLeft(4, '0')}-${m.month.toString().padLeft(2, '0')}';
  return ref.watch(parentRepositoryProvider).fetchAttendance(
        studentId: child.id,
        monthYyyyMm: yyyyMm,
      );
});

// ── Transport ─────────────────────────────────────────────────────────────────

final transportProvider =
    FutureProvider.autoDispose<ParentTransport?>((ref) async {
  final child = ref.watch(selectedChildProvider);
  if (child == null) return null;
  return ref.watch(parentRepositoryProvider).fetchTransport(child.id);
});

// ── Live bus location (Firebase RTDB) ─────────────────────────────────────────

/// One ping from `buses/{tripId}` written by the driver app every ~5s.
class BusPing {
  const BusPing({
    required this.lat,
    required this.lng,
    this.speed,
    this.heading,
    this.accuracy,
    required this.timestamp,
  });

  final double lat;
  final double lng;
  final double? speed;
  final double? heading;
  final double? accuracy;
  final DateTime timestamp;

  /// True if this ping is less than 30s old.
  bool get isFresh =>
      DateTime.now().difference(timestamp).inSeconds < 30;

  static BusPing? fromMap(dynamic raw) {
    if (raw is! Map) return null;
    final lat = (raw['lat'] as num?)?.toDouble();
    final lng = (raw['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    final tsMs = (raw['ts'] as num?)?.toInt() ?? 0;
    return BusPing(
      lat: lat,
      lng: lng,
      speed: (raw['speed'] as num?)?.toDouble(),
      heading: (raw['heading'] as num?)?.toDouble(),
      accuracy: (raw['accuracy'] as num?)?.toDouble(),
      timestamp: tsMs > 0
          ? DateTime.fromMillisecondsSinceEpoch(tsMs)
          : DateTime.now(),
    );
  }
}

/// Streams the driver's latest GPS ping for the given trip from Firebase
/// Realtime DB. Emits `null` when no data exists (trip not started yet)
/// and when Firebase isn't configured.
final liveBusPingProvider =
    StreamProvider.autoDispose.family<BusPing?, String>((ref, tripId) {
  try {
    Firebase.app(); // throws if not initialised
    final ref0 = FirebaseDatabase.instance.ref('buses/$tripId');
    return ref0.onValue.map((event) {
      final snap = event.snapshot.value;
      return BusPing.fromMap(snap);
    });
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[liveBusPingProvider] Firebase not ready: $e');
    }
    return Stream.value(null);
  }
});
