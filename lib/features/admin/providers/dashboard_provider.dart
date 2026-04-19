import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/admin/data/dashboard_repository.dart';
import 'package:mobile_app/features/admin/domain/dashboard_model.dart';

final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.fetchStats();
});
