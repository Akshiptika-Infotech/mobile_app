import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/admin/data/exam_repository.dart';
import 'package:mobile_app/features/admin/domain/exam_model.dart';

// ── Exam subjects ─────────────────────────────────────────────────────────────

final examSubjectsProvider =
    FutureProvider.autoDispose<List<ExamSubject>>((ref) async {
  final repo = ref.watch(examRepositoryProvider);
  return repo.fetchExamSubjects();
});

// ── Mark entry state ──────────────────────────────────────────────────────────

class MarkEntryState {
  const MarkEntryState({
    this.selectedSubject,
    this.students = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.success = false,
    this.error,
  });

  final ExamSubject? selectedSubject;
  final List<StudentMark> students;
  final bool isLoading;
  final bool isSubmitting;
  final bool success;
  final String? error;

  MarkEntryState copyWith({
    ExamSubject? selectedSubject,
    bool clearSubject = false,
    List<StudentMark>? students,
    bool? isLoading,
    bool? isSubmitting,
    bool? success,
    String? error,
  }) {
    return MarkEntryState(
      selectedSubject:
          clearSubject ? null : selectedSubject ?? this.selectedSubject,
      students: students ?? this.students,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      success: success ?? this.success,
      error: error,
    );
  }
}

class MarkEntryNotifier extends StateNotifier<MarkEntryState> {
  MarkEntryNotifier(this._repo) : super(const MarkEntryState());

  final ExamRepository _repo;

  Future<void> selectSubject(ExamSubject subject) async {
    if (!mounted) return;
    state =
        state.copyWith(selectedSubject: subject, isLoading: true, students: []);
    try {
      final students = await _repo.fetchStudentMarks(subject.id);
      if (!mounted) return;
      state = state.copyWith(students: students, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setMark(String studentId, int? marks) {
    if (!mounted) return;
    final updated = state.students.map((s) {
      if (s.studentId == studentId) {
        s.marksObtained = marks;
      }
      return s;
    }).toList();
    state = state.copyWith(students: updated);
  }

  Future<void> submit() async {
    if (!mounted) return;
    final subject = state.selectedSubject;
    if (subject == null) return;
    state = state.copyWith(isSubmitting: true);
    try {
      final marks = state.students.map((s) => s.toJson()).toList();
      await _repo.submitMarks(subject.id, marks);
      if (!mounted) return;
      state = state.copyWith(isSubmitting: false, success: true);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isSubmitting: false, error: e.toString());
    }
  }

  void reset() {
    if (!mounted) return;
    state = const MarkEntryState();
  }
}

final markEntryProvider =
    StateNotifierProvider.autoDispose<MarkEntryNotifier, MarkEntryState>(
        (ref) {
  return MarkEntryNotifier(ref.watch(examRepositoryProvider));
});

// ── Report cards ──────────────────────────────────────────────────────────────

final reportCardsProvider = FutureProvider.autoDispose
    .family<List<ReportCard>, String>((ref, classId) async {
  final repo = ref.watch(examRepositoryProvider);
  return repo.fetchReportCards(classId);
});
