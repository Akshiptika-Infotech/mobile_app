import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/admin/domain/calendar_model.dart';
import 'package:mobile_app/features/parent/data/parent_repository.dart';
import 'package:mobile_app/features/parent/domain/parent_model.dart';
import 'package:mobile_app/features/student/domain/student_portal_model.dart';

// ── Academic Years ────────────────────────────────────────────────────────────

final parentAcademicYearsProvider =
    FutureProvider.autoDispose<List<AcademicYear>>((ref) {
  return ref.watch(parentRepositoryProvider).fetchAcademicYears();
});

/// User-selected academic year (null = use active/first).
final selectedParentYearIdProvider = StateProvider<String?>((ref) => null);

/// Resolves to the effective year ID.
final effectiveParentYearIdProvider = Provider<String?>((ref) {
  final selected = ref.watch(selectedParentYearIdProvider);
  if (selected != null) return selected;
  return ref.watch(parentAcademicYearsProvider).whenOrNull(
    data: (years) {
      if (years.isEmpty) return null;
      return years.firstWhere((y) => y.isActive, orElse: () => years.first).id;
    },
  );
});

// ── Children ──────────────────────────────────────────────────────────────────

final parentChildrenProvider =
    FutureProvider.autoDispose<List<ChildSummary>>((ref) {
  return ref.watch(parentRepositoryProvider).fetchChildren();
});

// ── Child Fee Matrix ──────────────────────────────────────────────────────────

final parentChildMatrixProvider = FutureProvider.autoDispose
    .family<FeeMatrixData?, String>((ref, studentId) async {
  final yearId = ref.watch(effectiveParentYearIdProvider);
  if (yearId == null) return null;
  return ref
      .watch(parentRepositoryProvider)
      .fetchChildMatrix(studentId, yearId);
});

// ── Receipts ──────────────────────────────────────────────────────────────────

final parentReceiptsProvider =
    FutureProvider.autoDispose<List<ParentReceipt>>((ref) {
  return ref.watch(parentRepositoryProvider).fetchReceipts();
});

// ── Calendar ──────────────────────────────────────────────────────────────────

final parentCalendarProvider = FutureProvider.autoDispose
    .family<List<CalendarEvent>, ({String studentId, int month, int year})>(
        (ref, params) {
  return ref.watch(parentRepositoryProvider).fetchCalendarEvents(
        studentId: params.studentId,
        month: params.month,
        year: params.year,
      );
});

// ── Timetable ─────────────────────────────────────────────────────────────────

final parentTimetableProvider = FutureProvider.autoDispose
    .family<List<TimetableEntry>, String>((ref, studentId) {
  return ref.watch(parentRepositoryProvider).fetchTimetable(studentId);
});
