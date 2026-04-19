import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/admin/domain/id_card_model.dart';

final idCardRepositoryProvider = Provider<IdCardRepository>((ref) {
  return IdCardRepository(ref.watch(dioClientProvider));
});

class IdCardRepository {
  IdCardRepository(this._dio);

  final Dio _dio;

  Future<List<IdCardModel>> fetchIdCards() async {
    final response = await _dio.get('/api/admin/id-cards');
    final list = _extractList(response.data);
    return list
        .map((e) => IdCardModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Generates ID cards for the given [studentIds].
  /// Pass [classId] alone to generate for an entire class.
  Future<List<IdCardModel>> generateIdCards({
    List<String>? studentIds,
    String? classId,
  }) async {
    final response = await _dio.post(
      '/api/admin/id-cards/generate',
      data: {
        if (studentIds != null && studentIds.isNotEmpty)
          'studentIds': studentIds,
        if (classId != null && classId.isNotEmpty) 'classId': classId,
      },
    );
    final list = _extractList(response.data);
    return list
        .map((e) => IdCardModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in ['data', 'idCards', 'id_cards', 'results']) {
        if (data[key] is List) return data[key] as List;
      }
    }
    return [];
  }
}
