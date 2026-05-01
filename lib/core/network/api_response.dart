/// Standardized API response envelope shared between backend and mobile.
///
/// The backend is migrating to always return:
///   { success: true, data: T, meta?: PaginationMeta }
///   { success: false, error: string, code?: string }
///
/// This class lets repositories parse responses uniformly instead of
/// using defensive `_extractList` helpers.
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.code,
    this.meta,
  });

  final bool success;
  final T? data;
  final String? error;
  final String? code;
  final PaginationMeta? meta;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) parseData,
  ) {
    final ok = json['success'] as bool? ?? false;
    if (ok) {
      return ApiResponse<T>(
        success: true,
        data: json.containsKey('data') ? parseData(json['data']) : null,
        meta: json['meta'] != null
            ? PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>)
            : null,
      );
    }
    return ApiResponse<T>(
      success: false,
      error: json['error']?.toString() ?? 'Unknown error',
      code: json['code']?.toString(),
    );
  }

  /// Parses a raw JSON value that might be either the new envelope or a legacy
  /// raw array/object.  Used during the migration period.
  factory ApiResponse.fromJsonLegacy(
    dynamic json,
    T Function(dynamic) parseData,
  ) {
    if (json is Map<String, dynamic> && json.containsKey('success')) {
      return ApiResponse.fromJson(json, parseData);
    }
    // Legacy: backend returned raw data without envelope.
    return ApiResponse<T>(success: true, data: parseData(json));
  }

  R when<R>({
    required R Function(T data, PaginationMeta? meta) success,
    required R Function(String error, String? code) failure,
  }) {
    if (this.success && data != null) {
      return success(data as T, meta);
    }
    return failure(error ?? 'Unexpected error', code);
  }
}

class PaginationMeta {
  const PaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final int page;
  final int limit;
  final int total;
  final int totalPages;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Exception thrown when an API call returns a structured error envelope.
class ApiException implements Exception {
  const ApiException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'ApiException: $message${code != null ? ' (code: $code)' : ''}';
}
