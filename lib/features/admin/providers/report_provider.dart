import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/admin/data/report_repository.dart';

class ReportParams {
  const ReportParams({
    required this.type,
    this.from,
    this.to,
  });

  final String type;
  final String? from;
  final String? to;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportParams &&
          other.type == type &&
          other.from == from &&
          other.to == to;

  @override
  int get hashCode => Object.hash(type, from, to);
}

final reportProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, ReportParams>((ref, params) async {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.fetchReport(
    type: params.type,
    from: params.from,
    to: params.to,
  );
});
