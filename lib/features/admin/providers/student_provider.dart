import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/admin/data/student_repository.dart';
import 'package:mobile_app/features/admin/domain/student_model.dart';

// ── Students List State ───────────────────────────────────────────────────────

class StudentsListState {
  const StudentsListState({
    this.students = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.search = '',
    this.status = 'active',
    this.page = 1,
    this.hasMore = true,
  });

  final List<StudentModel> students;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String search;
  final String status;
  final int page;
  final bool hasMore;

  StudentsListState copyWith({
    List<StudentModel>? students,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    String? search,
    String? status,
    int? page,
    bool? hasMore,
  }) {
    return StudentsListState(
      students: students ?? this.students,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      search: search ?? this.search,
      status: status ?? this.status,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class StudentsListNotifier extends StateNotifier<StudentsListState> {
  StudentsListNotifier(this._repo) : super(const StudentsListState()) {
    load();
  }

  final StudentRepository _repo;

  Future<void> load({bool refresh = false}) async {
    if (!mounted) return;
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, page: 1, students: []);
    try {
      final page = await _repo.fetchStudents(
        search: state.search,
        status: state.status,
        page: 1,
      );
      if (!mounted) return;
      state = state.copyWith(
        students: page.students,
        isLoading: false,
        page: 1,
        hasMore: page.hasMore,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (!mounted) return;
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.page + 1;
      final page = await _repo.fetchStudents(
        search: state.search,
        status: state.status,
        page: nextPage,
      );
      if (!mounted) return;
      state = state.copyWith(
        students: [...state.students, ...page.students],
        isLoadingMore: false,
        page: nextPage,
        hasMore: page.hasMore,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  void setSearch(String query) {
    state = state.copyWith(search: query);
    load();
  }

  void setStatus(String status) {
    state = state.copyWith(status: status);
    load();
  }
}

final studentsListProvider =
    StateNotifierProvider.autoDispose<StudentsListNotifier, StudentsListState>(
        (ref) {
  return StudentsListNotifier(ref.watch(studentRepositoryProvider));
});

// ── Student Detail ────────────────────────────────────────────────────────────

final studentDetailProvider =
    FutureProvider.autoDispose.family<StudentModel, String>((ref, id) async {
  final repo = ref.watch(studentRepositoryProvider);
  return repo.fetchStudent(id);
});

// ── Student Form State ────────────────────────────────────────────────────────

class StudentFormState {
  const StudentFormState({
    this.isSubmitting = false,
    this.error,
    this.success = false,
    this.createdId,
  });

  final bool isSubmitting;
  final String? error;
  final bool success;
  final String? createdId;

  StudentFormState copyWith({
    bool? isSubmitting,
    String? error,
    bool? success,
    String? createdId,
  }) {
    return StudentFormState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      success: success ?? this.success,
      createdId: createdId ?? this.createdId,
    );
  }
}

class StudentFormNotifier extends StateNotifier<StudentFormState> {
  StudentFormNotifier(this._repo) : super(const StudentFormState());

  final StudentRepository _repo;

  Future<void> create(Map<String, dynamic> payload) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final student = await _repo.createStudent(payload);
      state = state.copyWith(
          isSubmitting: false, success: true, createdId: student.id);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
    }
  }

  Future<void> update(String id, Map<String, dynamic> payload) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await _repo.updateStudent(id, payload);
      state = state.copyWith(isSubmitting: false, success: true);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
    }
  }

  void reset() {
    state = const StudentFormState();
  }
}

final studentFormProvider =
    StateNotifierProvider.autoDispose<StudentFormNotifier, StudentFormState>(
        (ref) {
  return StudentFormNotifier(ref.watch(studentRepositoryProvider));
});
