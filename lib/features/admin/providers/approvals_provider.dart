import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/admin/data/approvals_repository.dart';
import 'package:mobile_app/features/admin/domain/approval_models.dart';

final pendingGatePassesProvider =
    FutureProvider.autoDispose<List<GatePassApproval>>((ref) {
  return ref.watch(approvalsRepositoryProvider).fetchPendingGatePasses();
});

final pendingPermanentPassesProvider =
    FutureProvider.autoDispose<List<PermanentPassApproval>>((ref) {
  return ref.watch(approvalsRepositoryProvider).fetchPendingPermanentPasses();
});

final pendingLeavesProvider =
    FutureProvider.autoDispose<List<LeaveApproval>>((ref) {
  return ref.watch(approvalsRepositoryProvider).fetchPendingLeaves();
});
