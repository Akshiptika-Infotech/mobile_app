import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/face/domain/face_model.dart';

class FaceRepository {
  const FaceRepository(this._dio);
  final Dio _dio;

  Future<FaceRegisterResult> registerFace({
    required String type, // 'student' | 'staff'
    String? admissionNumber,
    String? identifier, // staff employeeId
    required List<double> embedding,
  }) async {
    final r = await _dio.post('/api/mobile/face/register', data: {
      'type': type,
      if (admissionNumber != null) 'admissionNumber': admissionNumber,
      if (identifier != null) 'identifier': identifier,
      'embedding': embedding,
    });
    return FaceRegisterResult.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> deleteFaceRegistration({
    required String type,
    String? admissionNumber,
    String? identifier,
  }) async {
    await _dio.delete('/api/mobile/face/register', data: {
      'type': type,
      if (admissionNumber != null) 'admissionNumber': admissionNumber,
      if (identifier != null) 'identifier': identifier,
    });
  }

  Future<FaceVerifyResult> verifyFace({
    required List<double> embedding,
    required String date,
    required String attendanceType, // 'student' | 'staff'
    double threshold = 0.6,
    String? classId,
    String? sectionId,
    String? academicYearId,
  }) async {
    final r = await _dio.post('/api/mobile/face/verify', data: {
      'embedding': embedding,
      'threshold': threshold,
      'date': date,
      'attendanceType': attendanceType,
      if (classId != null) 'classId': classId,
      if (sectionId != null) 'sectionId': sectionId,
      if (academicYearId != null) 'academicYearId': academicYearId,
    });
    return FaceVerifyResult.fromJson(r.data as Map<String, dynamic>);
  }

  Future<FaceEnrollmentList> fetchEnrollmentList({
    required String type, // 'student' | 'staff'
    String? classId,
    String? sectionId,
    String? academicYearId,
    String? role, // for staff: 'TEACHER' etc.
  }) async {
    final r = await _dio.get('/api/mobile/face/list', queryParameters: {
      'type': type,
      if (classId != null) 'classId': classId,
      if (sectionId != null) 'sectionId': sectionId,
      if (academicYearId != null) 'academicYearId': academicYearId,
      if (role != null) 'role': role,
    });
    return FaceEnrollmentList.fromJson(r.data as Map<String, dynamic>);
  }
}

final faceRepositoryProvider = Provider<FaceRepository>((ref) {
  return FaceRepository(ref.watch(dioClientProvider));
});
