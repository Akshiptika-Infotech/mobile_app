import 'package:dio/dio.dart';

/// Converts any caught exception into a short, user-friendly string.
///
/// Rules:
///   • [DioException] with a response → map HTTP status to a readable message.
///   • [DioException] without a response → network-level message.
///   • Anything else → generic fallback.
String friendlyMessage(dynamic error) {
  if (error is DioException) {
    final status = error.response?.statusCode;

    // Server returned a JSON body with a message or error field — use it.
    if (error.response?.data is Map) {
      final body = error.response!.data as Map;
      final msg = body['message'] ?? body['error'];
      if (msg != null && msg.toString().isNotEmpty) {
        return msg.toString();
      }
    }

    if (status != null) {
      return switch (status) {
        400 => 'Invalid request. Please check your input.',
        401 => 'Your session has expired. Please sign in again.',
        403 => 'You don\'t have permission to do that.',
        404 => 'The requested item was not found.',
        409 => 'A conflict occurred. The item may already exist.',
        422 => 'Validation failed. Please check your input.',
        429 => 'Too many requests. Please wait a moment.',
        500 || 502 || 503 => 'Server error. Please try again later.',
        _ => 'Request failed (HTTP $status). Please try again.',
      };
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Connection timed out. Please check your network.',
      DioExceptionType.connectionError => 'No internet connection.',
      DioExceptionType.cancel => 'Request was cancelled.',
      _ => 'Network error. Please try again.',
    };
  }

  return 'Something went wrong. Please try again.';
}
