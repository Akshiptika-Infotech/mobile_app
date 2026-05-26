import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/security/domain/entry_exit_log_model.dart';
import 'package:mobile_app/features/security/domain/gate_pass_model.dart';
import 'package:mobile_app/features/security/domain/security_profile_model.dart';
import 'package:mobile_app/features/security/domain/security_visitor_model.dart';
import 'package:uuid/uuid.dart';

final securityRepositoryProvider = Provider<SecurityRepository>((ref) {
  return SecurityRepository(ref.watch(dioClientProvider));
});

class SecurityRepository {
  SecurityRepository(this._dio);

  final Dio _dio;
  static const _uuid = Uuid();

  // ── Visitors ───────────────────────────────────────────────────────────────

  /// `GET /api/security/visitors?date=YYYY-MM-DD` — today's (or given date's)
  /// registered visitors, each with their latest gate pass + latest entry/exit.
  Future<List<SecurityVisitor>> fetchVisitors(DateTime date) async {
    final res = await _dio.get(
      '/api/security/visitors',
      queryParameters: {'date': _yyyyMmDd(date)},
    );
    final data = res.data;
    if (data is! List) return const [];
    return data
        .map((e) => SecurityVisitor.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /api/security/visitors` — registers a visitor and creates an
  /// APPROVED gate pass + auto-ENTRY log in a single transaction.
  Future<SecurityVisitor> registerVisitor(RegisterVisitorPayload p) async {
    final res = await _dio.post('/api/security/visitors', data: p.toJson());
    return SecurityVisitor.fromJson(res.data as Map<String, dynamic>);
  }

  /// `POST /api/security/visitors/:id/checkout` — marks visitor as checked
  /// out (creates an EXIT entry-exit log row server-side).
  Future<void> checkoutVisitor(String id) async {
    await _dio.post('/api/security/visitors/$id/checkout');
  }

  // ── Entry / Exit ──────────────────────────────────────────────────────────

  Future<List<EntryExitLog>> fetchLogs(DateTime date) async {
    final res = await _dio.get(
      '/api/security/entry-exit',
      queryParameters: {'date': _yyyyMmDd(date)},
    );
    final data = res.data;
    if (data is! List) return const [];
    return data
        .map((e) => EntryExitLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Posts an entry / exit log. Uses a fresh `Idempotency-Key` per call to
  /// match the backend guard.
  Future<EntryExitLog> logEntryExit(EntryExitPayload payload) async {
    final res = await _dio.post(
      '/api/security/entry-exit',
      data: payload.toJson(),
      options: Options(
        headers: {'Idempotency-Key': _uuid.v4()},
      ),
    );
    return EntryExitLog.fromJson(res.data as Map<String, dynamic>);
  }

  // ── Gate passes ───────────────────────────────────────────────────────────

  Future<List<GatePass>> fetchActivePasses() async {
    final res = await _dio.get('/api/security/gate-passes');
    final data = res.data;
    if (data is! List) return const [];
    return data
        .map((e) => GatePass.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markPassUsed(String id) async {
    await _dio.post('/api/security/gate-passes/$id/use');
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<SecurityProfile> fetchProfile() async {
    final res = await _dio.get('/api/security/profile');
    return SecurityProfile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.patch('/api/security/profile', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  /// Updates the guard's own profile image URL. Backend mirrors the driver
  /// profile pattern — `PATCH /api/security/profile` with `{image: url}`.
  Future<void> updateProfilePhoto(String imageUrl) async {
    await _dio.patch('/api/security/profile', data: {'image': imageUrl});
  }

  // ── Photo upload (shared Cloudinary endpoint, auth-only) ──────────────────

  Future<String> uploadVisitorPhoto(String filePath) =>
      _uploadPhoto(filePath, folder: 'visitors');

  /// Profile photos go to `avatars/` so the backend doesn't apply the
  /// face-aware 4:5 crop reserved for student/staff ID photos (folder
  /// `photos/`) — that crop fails when no face is detected.
  Future<String> uploadProfilePhoto(String filePath) =>
      _uploadPhoto(filePath, folder: 'avatars');

  Future<String> _uploadPhoto(String filePath, {required String folder}) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
      'folder': folder,
      'resourceType': 'image',
    });
    try {
      final res = await _dio.post('/api/admin/upload', data: form);
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Unexpected upload response format');
      }
      final url = (data['url'] ?? data['path'] ?? '').toString();
      if (url.isEmpty) throw Exception('Upload returned an empty URL');
      return url;
    } on DioException catch (e) {
      // Surface the backend's actual error message instead of the generic
      // "status code of 500" so the snackbar shows what went wrong.
      final body = e.response?.data;
      String? serverMsg;
      if (body is Map && body['error'] is String) {
        serverMsg = body['error'] as String;
      } else if (body is String && body.isNotEmpty) {
        serverMsg = body;
      }
      final status = e.response?.statusCode;
      throw Exception(
        serverMsg != null
            ? 'Server $status: $serverMsg'
            : 'Upload failed ($status)',
      );
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _yyyyMmDd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
