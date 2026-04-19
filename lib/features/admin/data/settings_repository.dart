import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/admin/domain/settings_model.dart';

class SettingsRepository {
  SettingsRepository(this._dio);
  final Dio _dio;

  Future<AppSettings> fetchSettings() async {
    final res = await _dio.get('/api/admin/settings');
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final item = data['data'] ?? data;
      return AppSettings.fromJson(item as Map<String, dynamic>);
    }
    return const AppSettings(
      schoolName: '',
      contactEmail: '',
      contactPhone: '',
      logoUrl: '',
      activeAcademicYear: '',
    );
  }

  Future<void> updateSettings(Map<String, dynamic> data) async {
    await _dio.patch('/api/admin/settings', data: data);
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(dioClientProvider));
});
