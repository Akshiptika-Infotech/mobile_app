import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/driver/domain/driver_model.dart';

class DriverRepository {
  const DriverRepository(this._dio);
  final Dio _dio;

  // GET /api/driver/trips?date=today — returns list of trips for the driver
  Future<DriverTrip> fetchTrip() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final res = await _dio.get('/api/driver/trips', queryParameters: {'date': dateStr});
    final data = res.data;
    // API returns array of trips; take the first active or first one
    List<dynamic> trips;
    if (data is List) {
      trips = data;
    } else if (data is Map<String, dynamic>) {
      trips = (data['trips'] ?? data['data'] ?? <dynamic>[]) as List;
    } else {
      trips = [];
    }

    if (trips.isEmpty) {
      // No trip today — return empty trip backed by route info
      return _tripFromRoute();
    }

    // Prefer active trip, else first
    final trip = trips.firstWhere(
      (t) => (t['status'] ?? '').toString().toLowerCase() == 'active',
      orElse: () => trips.first,
    );
    return DriverTrip.fromTripJson(trip as Map<String, dynamic>);
  }

  Future<DriverTrip> _tripFromRoute() async {
    final res = await _dio.get('/api/driver/route');
    final data = res.data;
    if (data == null) return DriverTrip.empty();
    return DriverTrip.fromRouteJson(data as Map<String, dynamic>);
  }

  // GET /api/driver/route — route with stoppages and student assignments
  Future<DriverRoute> fetchRoute() async {
    final res = await _dio.get('/api/driver/route');
    final data = res.data;
    if (data == null) return DriverRoute.empty();
    return DriverRoute.fromJson(data as Map<String, dynamic>);
  }

  // Extract students from route stoppages (no dedicated /api/driver/students endpoint)
  Future<List<DriverStudent>> fetchStudents() async {
    final res = await _dio.get('/api/driver/route');
    final data = res.data;
    if (data == null) return [];
    final stoppages = (data['stoppages'] ?? data['stops'] ?? <dynamic>[]) as List;
    final students = <DriverStudent>[];
    for (final stop in stoppages) {
      final stopMap = stop as Map<String, dynamic>;
      final stopName = (stopMap['name'] ?? '').toString();
      final assignments = (stopMap['assignments'] ?? <dynamic>[]) as List;
      for (final assignment in assignments) {
        final a = assignment as Map<String, dynamic>;
        final stu = a['student'] as Map<String, dynamic>?;
        if (stu == null) continue;
        students.add(DriverStudent.fromRouteJson(stu, stopName));
      }
    }
    return students;
  }

  // GET /api/driver/trips?date=today → find trip ID → GET /api/driver/trips/{id}/attendance
  Future<List<DriverStudent>> fetchAttendance(String tripType) async {
    final tripId = await _getTodayTripId(tripType);
    if (tripId == null) return [];
    final res = await _dio.get('/api/driver/trips/$tripId/attendance');
    final data = res.data as Map<String, dynamic>?;
    if (data == null) return [];
    final attendance = (data['attendance'] ?? <dynamic>[]) as List;
    return attendance
        .map((e) => DriverStudent.fromTripAttendanceJson(e as Map<String, dynamic>))
        .toList();
  }

  // PUT /api/driver/trips/{id}/attendance
  Future<void> submitAttendance(String tripType, List<Map<String, dynamic>> records) async {
    final tripId = await _getTodayTripId(tripType);
    if (tripId == null) throw Exception('No trip found for today ($tripType)');
    await _dio.put('/api/driver/trips/$tripId/attendance', data: {
      'attendance': records,
      'complete': true,
    });
  }

  Future<String?> _getTodayTripId(String tripType) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final res = await _dio.get('/api/driver/trips', queryParameters: {'date': dateStr});
    final data = res.data;
    List<dynamic> trips;
    if (data is List) {
      trips = data;
    } else if (data is Map<String, dynamic>) {
      trips = (data['trips'] ?? data['data'] ?? <dynamic>[]) as List;
    } else {
      return null;
    }
    if (trips.isEmpty) return null;

    // Match by tripType (morning/afternoon)
    final match = trips.firstWhere(
      (t) => (t['tripType'] ?? '').toString().toLowerCase() == tripType.toLowerCase(),
      orElse: () => trips.first,
    );
    return (match['id'] ?? '').toString().isNotEmpty
        ? (match['id'] ?? '').toString()
        : null;
  }
}

final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  return DriverRepository(ref.watch(dioClientProvider));
});
