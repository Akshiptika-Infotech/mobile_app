import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/admin/data/transport_repository.dart';
import 'package:mobile_app/features/admin/domain/transport_model.dart';

final transportRoutesProvider =
    FutureProvider.autoDispose<List<TransportRoute>>((ref) async {
  return ref.watch(transportAdminRepositoryProvider).fetchRoutes();
});

final transportAssignmentsProvider =
    FutureProvider.autoDispose<List<TransportAssignment>>((ref) async {
  return ref.watch(transportAdminRepositoryProvider).fetchAssignments();
});

final transportRebatesProvider =
    FutureProvider.autoDispose<List<TransportRebate>>((ref) async {
  return ref.watch(transportAdminRepositoryProvider).fetchRebates();
});
