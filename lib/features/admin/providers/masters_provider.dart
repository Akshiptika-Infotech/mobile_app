import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/admin/data/masters_repository.dart';

/// Fetches master list items for a given model name (e.g. "houses", "castes").
///
/// Usage: `ref.watch(mastersProvider('houses'))`
final mastersProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, model) async {
  final repo = ref.watch(mastersRepositoryProvider);
  return repo.fetchMasters(model);
});
