import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/features/admin/data/attendance_repository.dart';
import 'package:mobile_app/features/admin/domain/attendance_model.dart';

// ── My-class attendance state ─────────────────────────────────────────────────

class MyClassAttendanceState {
  const MyClassAttendanceState({
    required this.date,
    this.students = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.submitted = false,
    this.locked = false,
    this.error,
    this.classId,
    this.academicYearId,
    this.sectionId,
  });

  final DateTime date;
  final List<AttendanceStudent> students;
  final bool isLoading;
  final bool isSubmitting;
  final bool submitted;
  final bool locked;
  final String? error;
  final String? classId;
  final String? academicYearId;
  final String? sectionId;

  MyClassAttendanceState copyWith({
    DateTime? date,
    List<AttendanceStudent>? students,
    bool? isLoading,
    bool? isSubmitting,
    bool? submitted,
    bool? locked,
    String? error,
    String? classId,
    String? academicYearId,
    String? sectionId,
  }) {
    return MyClassAttendanceState(
      date: date ?? this.date,
      students: students ?? this.students,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitted: submitted ?? this.submitted,
      locked: locked ?? this.locked,
      error: error,
      classId: classId ?? this.classId,
      academicYearId: academicYearId ?? this.academicYearId,
      sectionId: sectionId ?? this.sectionId,
    );
  }
}

class MyClassAttendanceNotifier
    extends StateNotifier<MyClassAttendanceState> {
  MyClassAttendanceNotifier(this._repo)
      : super(MyClassAttendanceState(date: DateTime.now())) {
    load(DateTime.now());
  }

  final AttendanceRepository _repo;

  Future<void> load(DateTime date) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, date: date, students: []);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final result = await _repo.fetchMyClassForDate(dateStr);
      if (!mounted) return;
      final alreadySubmitted = result.locked ||
          (result.students.isNotEmpty &&
              result.students.every((s) => s.isServerMarked));
      state = state.copyWith(
        students: result.students,
        classId: result.classId,
        academicYearId: result.academicYearId,
        sectionId: result.sectionId,
        isLoading: false,
        submitted: alreadySubmitted,
        locked: result.locked,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setDate(DateTime date) => load(date);

  void setStatus(String studentId, String status) {
    if (!mounted) return;
    final updated = state.students.map((s) {
      if (s.id == studentId) {
        s.status = status;
      }
      return s;
    }).toList();
    state = state.copyWith(students: updated);
  }

  void markAllPresent() {
    if (!mounted) return;
    for (final s in state.students) {
      s.status = 'present';
    }
    state = state.copyWith(students: List.from(state.students));
  }

  Future<void> submit() async {
    if (!mounted) return;
    state = state.copyWith(isSubmitting: true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(state.date);
      final records = state.students.map((s) => s.toJson()).toList();
      await _repo.submitAttendance(
        date: dateStr,
        records: records,
        classId: state.classId,
        academicYearId: state.academicYearId,
        sectionId: state.sectionId,
      );
      if (!mounted) return;
      state = state.copyWith(isSubmitting: false, submitted: true);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
          isSubmitting: false, error: e.toString());
    }
  }
}

final myClassAttendanceProvider = StateNotifierProvider.autoDispose<
    MyClassAttendanceNotifier, MyClassAttendanceState>((ref) {
  return MyClassAttendanceNotifier(ref.watch(attendanceRepositoryProvider));
});

// ── My attendance summary ─────────────────────────────────────────────────────

final myAttendanceProvider =
    FutureProvider.autoDispose<MyAttendanceSummary>((ref) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.fetchMyAttendance();
});

final studentAttendanceProvider = FutureProvider.autoDispose
    .family<List<AttendanceRecord>, ({String? className, String date})>(
        (ref, query) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.fetchStudentAttendance(
    className: query.className,
    date: query.date,
  );
});

/// Pass an empty string to fetch all staff attendance (no date filter).
final staffAttendanceProvider = FutureProvider.autoDispose
    .family<List<AttendanceRecord>, String>((ref, date) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.fetchStaffAttendance(date: date.isEmpty ? null : date);
});

final leaveRequestsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.fetchLeaveRequests();
});
