import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/admin/data/fee_repository.dart';
import 'package:mobile_app/features/admin/domain/fee_model.dart';

// ── Fee Collection Flow State ─────────────────────────────────────────────────

enum FeeCollectionStep { search, matrix, payment, receipt }

class FeeCollectionState {
  const FeeCollectionState({
    this.step = FeeCollectionStep.search,
    this.searchQuery = '',
    this.searchResults = const [],
    this.isSearching = false,
    this.selectedStudent,
    this.feeMatrix,
    this.selectedMonths = const [],
    this.isLoadingMatrix = false,
    this.isSubmitting = false,
    this.receipt,
    this.error,
  });

  final FeeCollectionStep step;
  final String searchQuery;
  final List<FeeSearchResult> searchResults;
  final bool isSearching;
  final FeeSearchResult? selectedStudent;
  final FeeStudentSummary? feeMatrix;
  final List<FeeMonth> selectedMonths;
  final bool isLoadingMatrix;
  final bool isSubmitting;
  final FeeReceipt? receipt;
  final String? error;

  double get totalAmount =>
      selectedMonths.fold(0.0, (sum, m) => sum + m.amount);

  FeeCollectionState copyWith({
    FeeCollectionStep? step,
    String? searchQuery,
    List<FeeSearchResult>? searchResults,
    bool? isSearching,
    FeeSearchResult? selectedStudent,
    FeeStudentSummary? feeMatrix,
    List<FeeMonth>? selectedMonths,
    bool? isLoadingMatrix,
    bool? isSubmitting,
    FeeReceipt? receipt,
    String? error,
    bool clearSelectedStudent = false,
    bool clearFeeMatrix = false,
    bool clearReceipt = false,
    bool clearError = false,
  }) {
    return FeeCollectionState(
      step: step ?? this.step,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      selectedStudent:
          clearSelectedStudent ? null : (selectedStudent ?? this.selectedStudent),
      feeMatrix: clearFeeMatrix ? null : (feeMatrix ?? this.feeMatrix),
      selectedMonths: selectedMonths ?? this.selectedMonths,
      isLoadingMatrix: isLoadingMatrix ?? this.isLoadingMatrix,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      receipt: clearReceipt ? null : (receipt ?? this.receipt),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class FeeCollectionNotifier extends StateNotifier<FeeCollectionState> {
  FeeCollectionNotifier(this._repo) : super(const FeeCollectionState());

  final FeeRepository _repo;

  Future<void> search(String query) async {
    state = state.copyWith(
      searchQuery: query,
      isSearching: true,
      clearError: true,
    );
    try {
      final results = await _repo.searchStudents(query);
      state = state.copyWith(searchResults: results, isSearching: false);
    } catch (e) {
      state = state.copyWith(
          isSearching: false, error: e.toString(), searchResults: []);
    }
  }

  Future<void> selectStudent(FeeSearchResult student) async {
    state = state.copyWith(
      selectedStudent: student,
      step: FeeCollectionStep.matrix,
      isLoadingMatrix: true,
      selectedMonths: [],
      clearFeeMatrix: true,
      clearError: true,
    );
    try {
      final matrix = await _repo.fetchFeeMatrix(student.id);
      state = state.copyWith(feeMatrix: matrix, isLoadingMatrix: false);
    } catch (e) {
      state = state.copyWith(isLoadingMatrix: false, error: e.toString());
    }
  }

  void toggleMonth(FeeMonth month) {
    final current = List<FeeMonth>.from(state.selectedMonths);
    final idx = current.indexWhere(
        (m) => m.month == month.month && m.feeType == month.feeType);
    if (idx >= 0) {
      current.removeAt(idx);
    } else {
      current.add(month);
    }
    state = state.copyWith(selectedMonths: current);
  }

  void proceedToPayment() {
    state = state.copyWith(step: FeeCollectionStep.payment);
  }

  Future<void> submitPayment({
    required String paymentMode,
    required String receiptNumber,
    required String date,
  }) async {
    if (state.selectedStudent == null) return;
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final receipt = await _repo.submitFeeCollection(
        studentId: state.selectedStudent!.id,
        selectedMonths: state.selectedMonths
            .map((m) => {
                  'month': m.month,
                  'year': m.year,
                  'feeType': m.feeType,
                  'amount': m.amount,
                })
            .toList(),
        amount: state.totalAmount,
        paymentMode: paymentMode,
        receiptNumber: receiptNumber,
        date: date,
      );
      state = state.copyWith(
        isSubmitting: false,
        receipt: receipt,
        step: FeeCollectionStep.receipt,
      );
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
    }
  }

  void reset() {
    state = const FeeCollectionState();
  }

  void goBack() {
    switch (state.step) {
      case FeeCollectionStep.search:
        break;
      case FeeCollectionStep.matrix:
        state = state.copyWith(
            step: FeeCollectionStep.search,
            clearSelectedStudent: true,
            clearFeeMatrix: true,
            selectedMonths: []);
        break;
      case FeeCollectionStep.payment:
        state = state.copyWith(step: FeeCollectionStep.matrix);
        break;
      case FeeCollectionStep.receipt:
        reset();
        break;
    }
  }
}

final feeCollectionProvider =
    StateNotifierProvider.autoDispose<FeeCollectionNotifier, FeeCollectionState>(
        (ref) {
  return FeeCollectionNotifier(ref.watch(feeRepositoryProvider));
});

// ── Fee History ───────────────────────────────────────────────────────────────

class FeeHistoryState {
  const FeeHistoryState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.dateFrom,
    this.dateTo,
  });

  final List<FeeHistoryItem> items;
  final bool isLoading;
  final String? error;
  final String? dateFrom;
  final String? dateTo;

  FeeHistoryState copyWith({
    List<FeeHistoryItem>? items,
    bool? isLoading,
    String? error,
    String? dateFrom,
    String? dateTo,
    bool clearError = false,
    bool clearDateFrom = false,
    bool clearDateTo = false,
  }) {
    return FeeHistoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
    );
  }
}

class FeeHistoryNotifier extends StateNotifier<FeeHistoryState> {
  FeeHistoryNotifier(this._repo) : super(const FeeHistoryState()) {
    load();
  }

  final FeeRepository _repo;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repo.fetchHistory(
        dateFrom: state.dateFrom,
        dateTo: state.dateTo,
      );
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setDateRange(String? from, String? to) {
    state = state.copyWith(
      dateFrom: from,
      dateTo: to,
      clearDateFrom: from == null,
      clearDateTo: to == null,
    );
    load();
  }

  Future<void> revoke(String id, String reason) async {
    try {
      await _repo.revokeCollection(id, reason);
      state = state.copyWith(
        items: state.items.where((item) => item.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final feeHistoryProvider =
    StateNotifierProvider.autoDispose<FeeHistoryNotifier, FeeHistoryState>(
        (ref) {
  return FeeHistoryNotifier(ref.watch(feeRepositoryProvider));
});
