import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/student/data/student_portal_repository.dart';
import 'package:mobile_app/features/student/domain/student_portal_model.dart';

// ── Academic Years ────────────────────────────────────────────────────────────

final studentAcademicYearsProvider =
    FutureProvider.autoDispose<List<AcademicYear>>((ref) {
  return ref.watch(studentPortalRepositoryProvider).fetchAcademicYears();
});

/// The user-selected academic year ID (null = use active/first from list).
final selectedStudentYearIdProvider = StateProvider<String?>((ref) => null);

/// Resolves to the effective year ID: user selection → active year → first year.
final effectiveStudentYearIdProvider = Provider<String?>((ref) {
  final selected = ref.watch(selectedStudentYearIdProvider);
  if (selected != null) return selected;
  return ref.watch(studentAcademicYearsProvider).whenOrNull(
    data: (years) {
      return years.firstWhere((y) => y.isActive, orElse: () => years.first).id;
    },
  );
});

// ── Fee Matrix ────────────────────────────────────────────────────────────────

final studentFeeMatrixProvider =
    FutureProvider.autoDispose<FeeMatrixData?>((ref) async {
  final yearId = ref.watch(effectiveStudentYearIdProvider);
  if (yearId == null) return null;
  return ref.watch(studentPortalRepositoryProvider).fetchFeeMatrix(yearId);
});

// ── Receipts ──────────────────────────────────────────────────────────────────

final studentReceiptsProvider =
    FutureProvider.autoDispose<List<StudentReceipt>>((ref) {
  return ref.watch(studentPortalRepositoryProvider).fetchReceipts();
});

// ── Transport ─────────────────────────────────────────────────────────────────

final studentTransportProvider =
    FutureProvider.autoDispose<StudentTransportInfo?>((ref) async {
  final yearId = ref.watch(effectiveStudentYearIdProvider);
  if (yearId == null) return null;
  return ref.watch(studentPortalRepositoryProvider).fetchTransport(yearId);
});
