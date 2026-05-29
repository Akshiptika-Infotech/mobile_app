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
    this.isSavingDraft = false,
    this.success = false,
    this.draftSaved = false,
    this.error,
  });

  final ExamSubject? selectedSubject;
  final List<StudentMark> students;
  final bool isLoading;
  final bool isSubmitting;
  final bool isSavingDraft;
  final bool success;
  final bool draftSaved;
  final String? error;

  MarkEntryState copyWith({
    ExamSubject? selectedSubject,
    bool clearSubject = false,
    List<StudentMark>? students,
    bool? isLoading,
    bool? isSubmitting,
    bool? isSavingDraft,
    bool? success,
    bool? draftSaved,
    String? error,
  }) {
    return MarkEntryState(
      selectedSubject:
          clearSubject ? null : selectedSubject ?? this.selectedSubject,
      students: students ?? this.students,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSavingDraft: isSavingDraft ?? this.isSavingDraft,
      success: success ?? this.success,
      draftSaved: draftSaved ?? this.draftSaved,
      error: error,
    );
  }
}

class MarkEntryNotifier extends StateNotifier<MarkEntryState> {
  MarkEntryNotifier(this._repo, this._ref) : super(const MarkEntryState());

  final ExamRepository _repo;
  final Ref _ref;

  /// Flips the selected subject to read-only after a 403 and refreshes the
  /// subjects list so the picker reflects the closed window too.
  void _lockSelected(String message, {required bool wasSubmitting}) {
    if (!mounted) return;
    final locked = state.selectedSubject?.copyWith(locked: true);
    state = state.copyWith(
      selectedSubject: locked,
      isSubmitting: wasSubmitting ? false : null,
      isSavingDraft: wasSubmitting ? null : false,
      error: message,
    );
    _ref.invalidate(examSubjectsProvider);
  }

  Future<void> selectSubject(ExamSubject subject) async {
    if (!mounted) return;
    state =
        state.copyWith(selectedSubject: subject, isLoading: true, students: []);
    try {
      final students = await _repo.fetchStudentMarks(subject);
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

  void setGrade(String studentId, String? grade) {
    if (!mounted) return;
    final updated = state.students.map((s) {
      if (s.studentId == studentId) {
        s.grade = grade;
      }
      return s;
    }).toList();
    state = state.copyWith(students: updated);
  }

  Future<void> saveDraft() async {
    if (!mounted) return;
    final subject = state.selectedSubject;
    if (subject == null) return;
    state = state.copyWith(isSavingDraft: true);
    try {
      final marks = state.students.map((s) => s.toJson()).toList();
      await _repo.submitMarks(subject, marks, status: 'DRAFT');
      if (!mounted) return;
      state = state.copyWith(isSavingDraft: false, draftSaved: true);
    } on MarksLockedException catch (e) {
      _lockSelected(e.message, wasSubmitting: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isSavingDraft: false, error: e.toString());
    }
  }

  Future<void> submit() async {
    if (!mounted) return;
    final subject = state.selectedSubject;
    if (subject == null) return;
    state = state.copyWith(isSubmitting: true);
    try {
      final marks = state.students.map((s) => s.toJson()).toList();
      await _repo.submitMarks(subject, marks, status: 'SUBMITTED');
      if (!mounted) return;
      state = state.copyWith(isSubmitting: false, success: true);
    } on MarksLockedException catch (e) {
      _lockSelected(e.message, wasSubmitting: true);
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
    StateNotifierProvider.autoDispose<MarkEntryNotifier, MarkEntryState>((ref) {
  return MarkEntryNotifier(ref.watch(examRepositoryProvider), ref);
});

// ── Report cards ──────────────────────────────────────────────────────────────

final reportCardsProvider = FutureProvider.autoDispose
    .family<List<ReportCard>, String>((ref, classId) async {
  final repo = ref.watch(examRepositoryProvider);
  return repo.fetchReportCards(classId);
});
