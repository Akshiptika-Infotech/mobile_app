import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/driver/domain/driver_profile_model.dart';
import 'package:mobile_app/features/driver/domain/driver_route_model.dart';
import 'package:mobile_app/features/driver/domain/driver_trip_model.dart';

final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  return DriverRepository(ref.watch(dioClientProvider));
});

class DriverRepository {
  DriverRepository(this._dio);

  final Dio _dio;

  // ── Route ──────────────────────────────────────────────────────────────────

  /// `GET /api/driver/route` — returns the route assigned to the driver, or
  /// `null` if no route exists.
  Future<DriverRoute?> fetchRoute() async {
    final res = await _dio.get('/api/driver/route');
    final data = res.data;
    if (data == null) return null;
    if (data is Map<String, dynamic>) return DriverRoute.fromJson(data);
    return null;
  }

  // ── Trips ──────────────────────────────────────────────────────────────────

  /// `GET /api/driver/trips?date=YYYY-MM-DD` — list of today's (or given
  /// date's) trips for this driver. Backend wraps the list under `data`.
  Future<List<DriverTrip>> fetchTripsForDate(DateTime date) async {
    final res = await _dio.get(
      '/api/driver/trips',
      queryParameters: {'date': _yyyyMmDd(date)},
    );
    final data = res.data;
    final list = _extractList(data);
    return list
        .map((e) => DriverTrip.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /api/driver/trips` — starts a new trip; backend creates one
  /// attendance row per assigned student. Returns the created trip with
  /// its attendance pre-populated.
  Future<DriverTrip> startTrip({
    required String routeId,
    required DateTime date,
    required TripType tripType,
  }) async {
    final res = await _dio.post(
      '/api/driver/trips',
      data: {
        'routeId': routeId,
        'tripDate': _yyyyMmDd(date),
        'tripType': tripType.apiValue,
      },
    );
    return DriverTrip.fromJson(_unwrap(res.data));
  }

  /// `GET /api/driver/trips/:id/attendance` — full trip detail including
  /// per-student attendance rows.
  Future<DriverTrip> fetchTripAttendance(String tripId) async {
    final res = await _dio.get('/api/driver/trips/$tripId/attendance');
    return DriverTrip.fromJson(_unwrap(res.data));
  }

  /// `PUT /api/driver/trips/:id/attendance` — bulk-update attendance rows
  /// and optionally mark the trip COMPLETED.
  Future<void> updateTripAttendance({
    required String tripId,
    required List<TripAttendance> rows,
    bool complete = false,
  }) async {
    await _dio.put(
      '/api/driver/trips/$tripId/attendance',
      data: {
        'attendance': rows
            .map((r) => {'id': r.id, 'status': r.status.apiValue})
            .toList(),
        if (complete) 'complete': true,
      },
    );
  }

  // ── GPS history ping ───────────────────────────────────────────────────────

  /// `POST /api/driver/location` — stores a GPS ping for trip-history
  /// playback. Rate-limited server-side at 120/min. Live updates are
  /// fanned to Firebase Realtime DB by the location service, not here.
  Future<void> postLocationPing({
    required String tripId,
    required double latitude,
    required double longitude,
    double? speed,
    double? accuracy,
  }) async {
    await _dio.post(
      '/api/driver/location',
      data: {
        'tripId': tripId,
        'latitude': latitude,
        'longitude': longitude,
        if (speed != null) 'speed': speed,
        if (accuracy != null) 'accuracy': accuracy,
      },
    );
  }

  // ── Profile ────────────────────────────────────────────────────────────────

  Future<DriverProfile> fetchProfile() async {
    final res = await _dio.get('/api/driver/profile');
    return DriverProfile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> updateProfilePhoto(String imageUrl) async {
    await _dio.patch('/api/driver/profile', data: {'image': imageUrl});
  }

  /// Uploads a local image file to the shared `/api/admin/upload` Cloudinary
  /// endpoint (auth-only — drivers are permitted) and returns the hosted URL.
  /// Uses the `avatars/` folder so the backend skips the face-aware 4:5
  /// crop that's reserved for student/staff ID photos (`photos/`).
  Future<String> uploadProfilePhoto(String filePath) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
      'folder': 'avatars',
      'resourceType': 'image',
    });
    final res = await _dio.post('/api/admin/upload', data: form);
    final data = res.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Unexpected upload response format');
    }
    final url = (data['url'] ?? data['path'] ?? '').toString();
    if (url.isEmpty) throw Exception('Upload returned an empty URL');
    return url;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.patch('/api/driver/profile', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _yyyyMmDd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Backend wraps some responses as `{success: true, data: ...}`. Some use a
  /// bare object. Normalise both.
  static Map<String, dynamic> _unwrap(dynamic data) {
    if (data is Map<String, dynamic> &&
        data['success'] == true &&
        data['data'] is Map<String, dynamic>) {
      return data['data'] as Map<String, dynamic>;
    }
    if (data is Map<String, dynamic>) return data;
    return <String, dynamic>{};
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      if (data['data'] is List) return data['data'] as List;
      if (data['trips'] is List) return data['trips'] as List;
    }
    return const [];
  }
}
