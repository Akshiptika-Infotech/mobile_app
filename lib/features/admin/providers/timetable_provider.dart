import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/admin/data/timetable_repository.dart';
import 'package:mobile_app/features/admin/domain/timetable_model.dart';
import 'package:mobile_app/features/admin/providers/my_profile_provider.dart';
import 'package:mobile_app/features/auth/domain/user_model.dart';
import 'package:mobile_app/features/auth/providers/auth_provider.dart';

final timetableProvider =
    FutureProvider.autoDispose<List<TimetablePeriod>>((ref) async {
  final repo = ref.watch(timetableRepositoryProvider);
  return repo.fetchMyTimetable();
});

/// Teacher-scoped timetable.
///
/// If the logged-in user is a teacher with an assigned class/section,
/// this filters [timetableProvider] so that only entries matching the
/// teacher's scope are returned. This protects against backend bugs
/// where `/api/teacher/timetable` returns entries for the wrong teacher
/// or for the whole school.
final teacherTimetableProvider =
    FutureProvider.autoDispose<List<TimetablePeriod>>((ref) async {
  final periods = await ref.watch(timetableProvider.future);
  final user = ref.watch(currentUserProvider);
  if (user?.role != AppRole.teacher) return periods;

  final profile = ref.watch(myProfileProvider).valueOrNull;
  final teacherSectionId = profile?.assignedSectionId;
  final teacherClassId = profile?.assignedClassId;

  // Prefer section-level filtering (most precise).
  if (teacherSectionId != null && teacherSectionId.isNotEmpty) {
    return periods.where((p) => p.sectionId == teacherSectionId).toList();
  }
  // Fall back to class-level filtering.
  if (teacherClassId != null && teacherClassId.isNotEmpty) {
    return periods.where((p) => p.classId == teacherClassId).toList();
  }
  return periods;
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
