import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/admin/domain/approval_models.dart';

class ApprovalsRepository {
  ApprovalsRepository(this._dio);
  final Dio _dio;

  // ── Visitor gate passes ───────────────────────────────────────────────────
  Future<List<GatePassApproval>> fetchPendingGatePasses() async {
    final res = await _dio.get(
      '/api/admin/gate-passes',
      queryParameters: {'status': 'PENDING'},
    );
    final list = _list(res.data, ['passes', 'data', 'items']);
    return list
        .map((e) => GatePassApproval.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> approveGatePass(String id) async {
    await _dio.patch('/api/admin/gate-passes/$id', data: {'action': 'approve'});
  }

  Future<void> rejectGatePass(String id, String reason) async {
    await _dio.patch('/api/admin/gate-passes/$id', data: {
      'action': 'reject',
      'rejectionReason': reason,
    });
  }

  // ── Permanent gate passes ────────────────────────────────────────────────
  Future<List<PermanentPassApproval>> fetchPendingPermanentPasses() async {
    final res = await _dio.get(
      '/api/admin/gate-passes/permanent',
      queryParameters: {'status': 'PENDING'},
    );
    final list = _list(res.data, ['passes', 'data', 'items']);
    return list
        .map((e) => PermanentPassApproval.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> approvePermanentPass(String id) async {
    await _dio.patch('/api/admin/gate-passes/permanent/$id',
        data: {'action': 'APPROVE'});
  }

  Future<void> rejectPermanentPass(String id, String reason) async {
    await _dio.patch('/api/admin/gate-passes/permanent/$id', data: {
      'action': 'REJECT',
      'rejectionReason': reason,
    });
  }

  // ── Staff leave requests ─────────────────────────────────────────────────
  Future<List<LeaveApproval>> fetchPendingLeaves() async {
    final res = await _dio.get(
      '/api/admin/attendance/leaves',
      queryParameters: {'status': 'PENDING'},
    );
    final list = _list(res.data, ['leaves', 'data', 'items']);
    return list
        .map((e) => LeaveApproval.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> approveLeave(String id, {String? note}) async {
    await _dio.patch('/api/admin/attendance/leaves/$id', data: {
      'status': 'APPROVED',
      if (note != null && note.isNotEmpty) 'reviewNote': note,
    });
  }

  Future<void> rejectLeave(String id, {String? note}) async {
    await _dio.patch('/api/admin/attendance/leaves/$id', data: {
      'status': 'REJECTED',
      if (note != null && note.isNotEmpty) 'reviewNote': note,
    });
  }

  static List<dynamic> _list(dynamic data, List<String> keys) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final k in keys) {
        if (data[k] is List) return data[k] as List;
      }
    }
    return [];
  }
}

final approvalsRepositoryProvider = Provider<ApprovalsRepository>((ref) {
  return ApprovalsRepository(ref.watch(dioClientProvider));
});
