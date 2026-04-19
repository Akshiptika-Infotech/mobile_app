import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/security/data/security_repository.dart';
import 'package:mobile_app/features/security/domain/security_model.dart';

final securityDashboardProvider =
    FutureProvider.autoDispose<SecurityDashboard>((ref) {
  return ref.watch(securityRepositoryProvider).fetchDashboard();
});

final entryExitLogProvider =
    FutureProvider.autoDispose<List<EntryExitRecord>>((ref) {
  return ref.watch(securityRepositoryProvider).fetchTodayLog();
});

final visitorsProvider =
    FutureProvider.autoDispose<List<Visitor>>((ref) {
  return ref.watch(securityRepositoryProvider).fetchVisitors();
});

final gatePassesProvider =
    FutureProvider.autoDispose<List<GatePass>>((ref) {
  return ref.watch(securityRepositoryProvider).fetchGatePasses();
});
