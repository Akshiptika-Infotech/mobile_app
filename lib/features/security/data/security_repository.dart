import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/security/domain/security_model.dart';

class SecurityRepository {
  const SecurityRepository(this._dio);
  final Dio _dio;

  // No /api/security/dashboard exists — build it from 3 parallel calls.
  Future<SecurityDashboard> fetchDashboard() async {
    final results = await Future.wait([
      _dio.get('/api/security/entry-exit'),
      _dio.get('/api/security/visitors'),
      _dio.get('/api/security/gate-passes'),
    ]);

    final logData = results[0].data;
    final visitorData = results[1].data;
    final passData = results[2].data;

    final logs = _extractList(logData);
    final visitors = _extractList(visitorData);
    final passes = _extractList(passData);

    final entries = logs.where((e) {
      final t = (e['logType'] ?? e['type'] ?? '').toString().toLowerCase();
      return t == 'entry' || t == 'in';
    }).length;

    final exits = logs.where((e) {
      final t = (e['logType'] ?? e['type'] ?? '').toString().toLowerCase();
      return t == 'exit' || t == 'out';
    }).length;

    final recentRecords = logs
        .take(5)
        .map((e) => EntryExitRecord.fromJson(e as Map<String, dynamic>))
        .toList();

    return SecurityDashboard(
      todayEntries: entries,
      todayExits: exits,
      activeVisitors: visitors.length,
      pendingPasses: passes.length,
      recentLog: recentRecords,
    );
  }

  Future<void> logEntryExit({
    required String personName,
    required String personType,
    required String type,
  }) async {
    await _dio.post('/api/security/entry-exit', data: {
      'personName': personName,
      'personType': personType,
      'type': type,
    });
  }

  Future<List<EntryExitRecord>> fetchTodayLog() async {
    final res = await _dio.get('/api/security/entry-exit');
    final list = _extractList(res.data);
    return list
        .map((e) => EntryExitRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Visitor>> fetchVisitors() async {
    final res = await _dio.get('/api/security/visitors');
    final list = _extractList(res.data);
    return list
        .map((e) => Visitor.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Upload a photo file and return the Cloudinary URL.
  Future<String> uploadVisitorPhoto(File photo) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(photo.path,
          filename: 'visitor_${DateTime.now().millisecondsSinceEpoch}.jpg'),
      'folder': 'visitors',
    });
    final res = await _dio.post('/api/admin/upload', data: formData);
    final data = res.data as Map<String, dynamic>;
    return (data['url'] ?? data['path'] ?? '').toString();
  }

  Future<void> registerVisitor({
    required String fullName,
    required String phone,
    required String purposeOfVisit,
    String? email,
    String? personToMeet,
    String? vehicleNumber,
    String? imagePath,
    int validHours = 8,
  }) async {
    await _dio.post('/api/security/visitors', data: {
      'fullName': fullName,
      'phone': phone,
      'purposeOfVisit': purposeOfVisit,
      if (email != null && email.isNotEmpty) 'email': email,
      if (personToMeet != null && personToMeet.isNotEmpty) 'personToMeet': personToMeet,
      if (vehicleNumber != null && vehicleNumber.isNotEmpty) 'vehicleNumber': vehicleNumber,
      if (imagePath != null && imagePath.isNotEmpty) 'imagePath': imagePath,
      'validHours': validHours,
    });
  }

  Future<void> checkOutVisitor(String visitorId) async {
    await _dio.post('/api/security/visitors/$visitorId/checkout');
  }

  Future<List<GatePass>> fetchGatePasses() async {
    final res = await _dio.get('/api/security/gate-passes');
    final list = _extractList(res.data);
    return list
        .map((e) => GatePass.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Correct endpoint: PATCH /api/security/gate-passes/{id}/use
  Future<void> markPassUsed(String passId) async {
    await _dio.patch('/api/security/gate-passes/$passId/use');
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in ['data', 'logs', 'records', 'visitors', 'passes', 'gatePasses']) {
        if (data[key] is List) return data[key] as List;
      }
    }
    return [];
  }
}

final securityRepositoryProvider = Provider<SecurityRepository>((ref) {
  return SecurityRepository(ref.watch(dioClientProvider));
});
