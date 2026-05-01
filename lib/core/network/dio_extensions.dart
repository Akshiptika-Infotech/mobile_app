import 'package:dio/dio.dart';
import 'package:mobile_app/core/network/api_response.dart';

/// Extensions on [Dio] [Response] to parse standardized API envelopes.
extension ApiResponseParsing on Response {
  /// Parses the response body using the new `{success, data, error}` envelope.
  ///
  /// Throws [ApiException] when `success == false`.
  ApiResponse<T> parseApiResponse<T>(T Function(dynamic) parseData) {
    final json = data;
    if (json is Map<String, dynamic> && json.containsKey('success')) {
      final response = ApiResponse<T>.fromJson(json, parseData);
      if (!response.success) {
        throw ApiException(response.error ?? 'Unknown API error', code: response.code);
      }
      return response;
    }
    // Legacy fallback: backend returned raw data without envelope.
    return ApiResponse<T>(success: true, data: parseData(json));
  }

  /// Parses a list response that may be wrapped in an envelope or returned raw.
  ///
  /// Throws [ApiException] when `success == false`.
  List<T> parseApiList<T>(T Function(dynamic) parseItem) {
    final json = data;
    if (json is Map<String, dynamic> && json.containsKey('success')) {
      final response = ApiResponse<dynamic>.fromJson(json, (d) => d);
      if (!response.success) {
        throw ApiException(response.error ?? 'Unknown API error', code: response.code);
      }
      final list = response.data as List<dynamic>?;
      return list?.map(parseItem).toList() ?? [];
    }
    // Legacy fallback.
    if (json is List) {
      return json.map(parseItem).toList();
    }
    if (json is Map<String, dynamic> && json.containsKey('data') && json['data'] is List) {
      return (json['data'] as List).map(parseItem).toList();
    }
    return [];
  }
}
