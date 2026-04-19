import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/admin/domain/dashboard_model.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dioClientProvider));
});

class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

  Future<DashboardStats> fetchStats() async {
    final response = await _dio.get('/api/admin/dashboard');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return DashboardStats.fromJson(data);
    }
    throw Exception('Unexpected dashboard response format');
  }
}
