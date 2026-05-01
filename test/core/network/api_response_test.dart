import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/network/api_response.dart';

void main() {
  group('ApiResponse', () {
    test('parses success envelope', () {
      final json = {
        'success': true,
        'data': {'id': '123', 'name': 'Test'},
      };
      final response = ApiResponse.fromJson(
        json,
        (data) => data as Map<String, dynamic>,
      );
      expect(response.success, isTrue);
      expect(response.data, {'id': '123', 'name': 'Test'});
      expect(response.error, isNull);
    });

    test('parses error envelope', () {
      final json = {
        'success': false,
        'error': 'Not found',
        'code': 'NOT_FOUND',
      };
      final response = ApiResponse.fromJson(
        json,
        (data) => data,
      );
      expect(response.success, isFalse);
      expect(response.error, 'Not found');
      expect(response.code, 'NOT_FOUND');
      expect(response.data, isNull);
    });

    test('parses legacy raw data without envelope', () {
      final json = {'id': '456', 'name': 'Legacy'};
      final response = ApiResponse.fromJsonLegacy(
        json,
        (data) => data as Map<String, dynamic>,
      );
      expect(response.success, isTrue);
      expect(response.data, {'id': '456', 'name': 'Legacy'});
    });

    test('when() calls success callback for successful response', () {
      const response = ApiResponse<String>(
        success: true,
        data: 'hello',
      );
      final result = response.when(
        success: (data, meta) => 'got $data',
        failure: (error, code) => 'error: $error',
      );
      expect(result, 'got hello');
    });

    test('when() calls failure callback for failed response', () {
      const response = ApiResponse<String>(
        success: false,
        error: 'boom',
      );
      final result = response.when(
        success: (data, meta) => 'got $data',
        failure: (error, code) => 'error: $error',
      );
      expect(result, 'error: boom');
    });
  });

  group('PaginationMeta', () {
    test('parses from json with defaults', () {
      final meta = PaginationMeta.fromJson({});
      expect(meta.page, 1);
      expect(meta.limit, 20);
      expect(meta.total, 0);
      expect(meta.totalPages, 1);
    });

    test('parses from json with values', () {
      final meta = PaginationMeta.fromJson({
        'page': 2,
        'limit': 50,
        'total': 100,
        'totalPages': 2,
      });
      expect(meta.page, 2);
      expect(meta.limit, 50);
      expect(meta.total, 100);
      expect(meta.totalPages, 2);
    });
  });
}
