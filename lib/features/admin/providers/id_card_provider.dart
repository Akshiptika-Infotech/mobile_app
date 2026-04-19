import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/admin/data/id_card_repository.dart';
import 'package:mobile_app/features/admin/domain/id_card_model.dart';

class IdCardState {
  const IdCardState({
    this.idCards = const [],
    this.isLoading = false,
    this.isGenerating = false,
    this.error,
  });

  final List<IdCardModel> idCards;
  final bool isLoading;
  final bool isGenerating;
  final String? error;

  IdCardState copyWith({
    List<IdCardModel>? idCards,
    bool? isLoading,
    bool? isGenerating,
    String? error,
  }) {
    return IdCardState(
      idCards: idCards ?? this.idCards,
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
    );
  }
}

class IdCardNotifier extends StateNotifier<IdCardState> {
  IdCardNotifier(this._repo) : super(const IdCardState()) {
    load();
  }

  final IdCardRepository _repo;

  Future<void> load() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);
    try {
      final cards = await _repo.fetchIdCards();
      if (!mounted) return;
      state = state.copyWith(idCards: cards, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> generate({List<String>? studentIds, String? classId}) async {
    if (!mounted) return;
    state = state.copyWith(isGenerating: true);
    try {
      final generated = await _repo.generateIdCards(
        studentIds: studentIds,
        classId: classId,
      );
      if (!mounted) return;
      state = state.copyWith(
        idCards: [...generated, ...state.idCards],
        isGenerating: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isGenerating: false, error: e.toString());
    }
  }
}

final idCardProvider =
    StateNotifierProvider.autoDispose<IdCardNotifier, IdCardState>((ref) {
  return IdCardNotifier(ref.watch(idCardRepositoryProvider));
});
