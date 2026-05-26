import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/security/data/security_repository.dart';
import 'package:mobile_app/features/security/domain/entry_exit_log_model.dart';
import 'package:mobile_app/features/security/domain/gate_pass_model.dart';
import 'package:mobile_app/features/security/domain/security_profile_model.dart';
import 'package:mobile_app/features/security/domain/security_visitor_model.dart';

/// Currently selected log/visitor date (defaults to today). Lives at session
/// scope so the date persists as the guard navigates between tabs.
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final visitorsProvider =
    FutureProvider.autoDispose<List<SecurityVisitor>>((ref) async {
  final date = ref.watch(selectedDateProvider);
  return ref.watch(securityRepositoryProvider).fetchVisitors(date);
});

final entryExitLogsProvider =
    FutureProvider.autoDispose<List<EntryExitLog>>((ref) async {
  final date = ref.watch(selectedDateProvider);
  return ref.watch(securityRepositoryProvider).fetchLogs(date);
});

final activeGatePassesProvider =
    FutureProvider.autoDispose<List<GatePass>>((ref) async {
  return ref.watch(securityRepositoryProvider).fetchActivePasses();
});

final securityProfileProvider =
    FutureProvider.autoDispose<SecurityProfile>((ref) async {
  return ref.watch(securityRepositoryProvider).fetchProfile();
});
