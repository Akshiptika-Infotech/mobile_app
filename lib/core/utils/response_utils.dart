// Helpers for safely extracting typed data from Dio response bodies.
// All API responses can be List, Map, null, or unexpected; these utilities
// centralise defensive casts so repositories don't need to duplicate them.

/// Returns a [List] from [data].
///
/// Checks common envelope keys ([keys]) when [data] is a Map.
/// Falls back to an empty list rather than throwing on unexpected shapes.
List<Map<String, dynamic>> extractList(
  dynamic data, {
  List<String> keys = const ['data', 'students', 'attendance', 'records', 'items', 'list'],
}) {
  if (data is List) {
    return data.whereType<Map<String, dynamic>>().toList();
  }
  if (data is Map<String, dynamic>) {
    for (final key in keys) {
      final value = data[key];
      if (value is List) {
        return value.whereType<Map<String, dynamic>>().toList();
      }
    }
  }
  return [];
}

/// Returns a [Map<String, dynamic>] from [data], or null on mismatch / null input.
Map<String, dynamic>? extractMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  return null;
}

/// Returns a [Map<String, dynamic>] from [data], throwing [Exception] with
/// [errorMessage] when the body is absent or not a Map.
Map<String, dynamic> requireMap(dynamic data, [String errorMessage = 'Unexpected response format']) {
  if (data is Map<String, dynamic>) return data;
  throw Exception(errorMessage);
}
