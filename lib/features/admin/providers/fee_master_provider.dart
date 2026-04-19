import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/admin/data/fee_master_repository.dart';
import 'package:mobile_app/features/admin/domain/fee_master_model.dart';

final feeTypesProvider =
    FutureProvider.autoDispose<List<FeeType>>((ref) async {
  return ref.watch(feeMasterRepositoryProvider).fetchFeeTypes();
});

final feeStructuresProvider =
    FutureProvider.autoDispose<List<FeeStructure>>((ref) async {
  return ref.watch(feeMasterRepositoryProvider).fetchFeeStructures();
});

final concessionsProvider =
    FutureProvider.autoDispose<List<ConcessionType>>((ref) async {
  return ref.watch(feeMasterRepositoryProvider).fetchConcessions();
});

final lateFeeConfigProvider =
    FutureProvider.autoDispose<LateFeeConfig>((ref) async {
  return ref.watch(feeMasterRepositoryProvider).fetchLateFeeConfig();
});
