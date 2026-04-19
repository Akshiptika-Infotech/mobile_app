import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/admin/data/class_repository.dart';
import 'package:mobile_app/features/admin/domain/class_model.dart';

// ── Academic Year List ────────────────────────────────────────────────────────

final academicYearsProvider =
    FutureProvider.autoDispose<List<AcademicYear>>((ref) async {
  return ref.watch(classRepositoryProvider).fetchAcademicYears();
});

// ── Academic Year Mutations ───────────────────────────────────────────────────

class AcademicYearState {
  const AcademicYearState({
    this.years = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  final List<AcademicYear> years;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  AcademicYearState copyWith({
    List<AcademicYear>? years,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
  }) {
    return AcademicYearState(
      years: years ?? this.years,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

class AcademicYearNotifier extends StateNotifier<AcademicYearState> {
  AcademicYearNotifier(this._repo) : super(const AcademicYearState()) {
    load();
  }

  final ClassRepository _repo;

  Future<void> load() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);
    try {
      final years = await _repo.fetchAcademicYears();
      if (!mounted) return;
      state = state.copyWith(years: years, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> create({
    required String name,
    required String startDate,
    required String endDate,
  }) async {
    if (!mounted) return;
    state = state.copyWith(isSubmitting: true);
    try {
      await _repo.createAcademicYear(name, startDate, endDate);
      if (!mounted) return;
      state = state.copyWith(isSubmitting: false);
      await load();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isSubmitting: false, error: e.toString());
    }
  }

  Future<void> activate(String id) async {
    if (!mounted) return;
    state = state.copyWith(isSubmitting: true);
    try {
      await _repo.setActiveYear(id);
      if (!mounted) return;
      state = state.copyWith(isSubmitting: false);
      await load();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isSubmitting: false, error: e.toString());
    }
  }
}

final academicYearNotifierProvider = StateNotifierProvider.autoDispose<
    AcademicYearNotifier, AcademicYearState>((ref) {
  return AcademicYearNotifier(ref.watch(classRepositoryProvider));
});
