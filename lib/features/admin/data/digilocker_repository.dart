import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/admin/domain/digilocker_model.dart';

class DigiLockerRepository {
  DigiLockerRepository(this._dio);
  final Dio _dio;

  Future<List<DigiLockerPin>> fetchPins() async {
    final res = await _dio.get('/api/clerk/digilocker-pins');
    final data = res.data;
    final list = _extractList(data);
    return list
        .map((e) => DigiLockerPin.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in ['data', 'pins', 'students']) {
        if (data[key] is List) return data[key] as List;
      }
    }
    return [];
  }
}

final digilockerRepositoryProvider = Provider<DigiLockerRepository>((ref) {
  return DigiLockerRepository(ref.watch(dioClientProvider));
});
