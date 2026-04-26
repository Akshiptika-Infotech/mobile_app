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

  /// Backend exposes `/api/admin/id-cards/students` (data) and
  /// `/api/admin/id-cards/students/pdf` (PDF). There is no JSON
  /// "generate" endpoint — the PDF route returns a file directly.
  Future<List<IdCardModel>> fetchIdCards({String? classId, String? sectionId}) async {
    final response = await _dio.get(
      '/api/admin/id-cards/students',
      queryParameters: {
        if (classId != null && classId.isNotEmpty) 'classId': classId,
        if (sectionId != null && sectionId.isNotEmpty) 'sectionId': sectionId,
      },
    );
    final list = _extractList(response.data);
    return list.map(_studentToCard).toList();
  }

  /// "Generate" is a refresh against the same data endpoint, optionally
  /// scoped to specific students or a class. The actual PDF is produced
  /// by `/api/admin/id-cards/students/pdf` — open that URL via the
  /// browser/url_launcher when the user wants the printable file.
  Future<List<IdCardModel>> generateIdCards({
    List<String>? studentIds,
    String? classId,
  }) async {
    final response = await _dio.get(
      '/api/admin/id-cards/students',
      queryParameters: {
        if (classId != null && classId.isNotEmpty) 'classId': classId,
      },
    );
    final list = _extractList(response.data);
    var cards = list.map(_studentToCard);
    if (studentIds != null && studentIds.isNotEmpty) {
      final ids = studentIds.toSet();
      cards = cards.where((c) => ids.contains(c.studentId));
    }
    return cards.toList();
  }

  /// Maps a student row from `/api/admin/id-cards/students` into the
  /// IdCardModel shape the UI expects.
  static IdCardModel _studentToCard(dynamic raw) {
    final s = raw as Map<String, dynamic>;
    final first = (s['firstName'] ?? '').toString().trim();
    final last  = (s['lastName']  ?? '').toString().trim();
    final cls   = (s['class'] is Map<String, dynamic>)
        ? (s['class'] as Map<String, dynamic>)['name']?.toString() ?? ''
        : '';
    final sec = (s['section'] is Map<String, dynamic>)
        ? (s['section'] as Map<String, dynamic>)['name']?.toString() ?? ''
        : '';
    final className = [cls, sec].where((e) => e.isNotEmpty).join(' · ');
    return IdCardModel(
      id:          (s['id'] ?? s['admissionNumber'] ?? '').toString(),
      studentId:   (s['id'] ?? '').toString(),
      studentName: [first, last].where((e) => e.isNotEmpty).join(' '),
      className:   className,
      generatedAt: '',
      url:         s['photoPath'] as String?,
    );
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
