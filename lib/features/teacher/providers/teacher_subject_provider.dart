import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/admin/domain/exam_model.dart';
import 'package:mobile_app/features/teacher/data/teacher_subject_repository.dart';

final teacherSubjectsProvider =
    FutureProvider.autoDispose<List<TeacherExamSubject>>((ref) async {
  final repo = ref.watch(teacherSubjectRepositoryProvider);
  return repo.fetchSubjects();
});

class TeacherSubjectState {
  const TeacherSubjectState({
    this.isLoading = false,
    this.success = false,
    this.error,
  });

  final bool isLoading;
  final bool success;
  final String? error;

  TeacherSubjectState copyWith({
    bool? isLoading,
    bool? success,
    String? error,
  }) {
    return TeacherSubjectState(
      isLoading: isLoading ?? this.isLoading,
      success: success ?? this.success,
      error: error,
    );
  }
}

class TeacherSubjectNotifier extends StateNotifier<TeacherSubjectState> {
  TeacherSubjectNotifier(this._repo) : super(const TeacherSubjectState());

  final TeacherSubjectRepository _repo;

  Future<void> create({
    required String name,
    required String code,
    required bool isGraded,
  }) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);
    try {
      await _repo.createSubject(name: name, code: code, isGraded: isGraded);
      if (!mounted) return;
      state = state.copyWith(isLoading: false, success: true);
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = _extractError(e);
      state = state.copyWith(isLoading: false, error: msg);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> update(
    String id, {
    String? name,
    String? code,
    bool? isGraded,
  }) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);
    try {
      await _repo.updateSubject(id, name: name, code: code, isGraded: isGraded);
      if (!mounted) return;
      state = state.copyWith(isLoading: false, success: true);
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = _extractError(e);
      state = state.copyWith(isLoading: false, error: msg);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> delete(String id) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);
    try {
      await _repo.deleteSubject(id);
      if (!mounted) return;
      state = state.copyWith(isLoading: false, success: true);
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = _extractError(e);
      state = state.copyWith(isLoading: false, error: msg);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() {
    if (!mounted) return;
    state = const TeacherSubjectState();
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

final teacherSubjectNotifierProvider =
    StateNotifierProvider.autoDispose<TeacherSubjectNotifier, TeacherSubjectState>(
  (ref) => TeacherSubjectNotifier(ref.watch(teacherSubjectRepositoryProvider)),
);
