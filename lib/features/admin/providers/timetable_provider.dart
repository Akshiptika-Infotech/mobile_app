import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/admin/data/timetable_repository.dart';
import 'package:mobile_app/features/admin/domain/timetable_model.dart';

/// "My Timetable" — only the periods this teacher teaches, across every
/// class/section. The backend scopes this via `?scope=mine`, so no client-side
/// filtering is needed (filtering by section here would wrongly drop periods
/// the teacher takes in other sections).
final teacherTimetableProvider =
    FutureProvider.autoDispose<List<TimetablePeriod>>((ref) async {
  final repo = ref.watch(timetableRepositoryProvider);
  return repo.fetchTeacherTimetable(scope: 'mine');
});

/// "My Class" — the full grid of the teacher's assigned class/section,
/// including every teacher's periods (`?scope=class`). Cells show who takes
/// each period; only the current teacher's own periods are editable.
final classTimetableProvider =
    FutureProvider.autoDispose<List<TimetablePeriod>>((ref) async {
  final repo = ref.watch(timetableRepositoryProvider);
  return repo.fetchTeacherTimetable(scope: 'class');
});

final adminTimetableProvider =
    FutureProvider.autoDispose<List<TimetablePeriod>>((ref) async {
  final repo = ref.watch(timetableRepositoryProvider);
  return repo.fetchAdminTimetable();
});

final timetableSubjectsProvider = FutureProvider.autoDispose
    .family<List<TimetableSubject>, String>((ref, classId) async {
  final repo = ref.watch(timetableRepositoryProvider);
  return repo.fetchTimetableSubjects(classId);
});

// ── Teacher timetable action state ────────────────────────────────────────────

class TeacherTimetableActionState {
  const TeacherTimetableActionState({
    this.isLoading = false,
    this.success = false,
    this.error,
  });

  final bool isLoading;
  final bool success;
  final String? error;

  TeacherTimetableActionState copyWith({
    bool? isLoading,
    bool? success,
    String? error,
  }) {
    return TeacherTimetableActionState(
      isLoading: isLoading ?? this.isLoading,
      success: success ?? this.success,
      error: error,
    );
  }
}

class TeacherTimetableActionNotifier
    extends StateNotifier<TeacherTimetableActionState> {
  TeacherTimetableActionNotifier(this._repo)
      : super(const TeacherTimetableActionState());

  final TimetableRepository _repo;

  Future<void> create({
    required String dayOfWeek,
    required int periodNumber,
    required String startTime,
    required String endTime,
    required String subjectId,
    String? sectionId,
    bool optionSlot = false,
  }) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);
    try {
      await _repo.createTeacherPeriod(
        dayOfWeek: dayOfWeek,
        periodNumber: periodNumber,
        startTime: startTime,
        endTime: endTime,
        subjectId: subjectId,
        sectionId: sectionId,
        optionSlot: optionSlot,
      );
      if (!mounted) return;
      state = state.copyWith(isLoading: false, success: true);
    } on DioException catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e),
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> update(
    String id, {
    String? startTime,
    String? endTime,
    String? subjectId,
  }) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);
    try {
      await _repo.updateTeacherPeriod(
        id,
        startTime: startTime,
        endTime: endTime,
        subjectId: subjectId,
      );
      if (!mounted) return;
      state = state.copyWith(isLoading: false, success: true);
    } on DioException catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e),
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> delete(String id) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);
    try {
      await _repo.deleteTeacherPeriod(id);
      if (!mounted) return;
      state = state.copyWith(isLoading: false, success: true);
    } on DioException catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e),
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() {
    if (!mounted) return;
    state = const TeacherTimetableActionState();
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    if (data is String && data.isNotEmpty) return data;
    return e.message ?? 'An unexpected error occurred.';
  }
}

final teacherTimetableActionProvider = StateNotifierProvider.autoDispose<
    TeacherTimetableActionNotifier, TeacherTimetableActionState>((ref) {
  return TeacherTimetableActionNotifier(ref.watch(timetableRepositoryProvider));
});
