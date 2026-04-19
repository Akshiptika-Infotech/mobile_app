import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/reception/data/reception_repository.dart';
import 'package:mobile_app/features/reception/domain/reception_model.dart';

final receptionDashboardProvider =
    FutureProvider.autoDispose<ReceptionDashboard>((ref) {
  return ref.watch(receptionRepositoryProvider).fetchDashboard();
});

final receptionVisitorsProvider =
    FutureProvider.autoDispose<List<ReceptionVisitor>>((ref) {
  return ref.watch(receptionRepositoryProvider).fetchVisitors();
});

final receptionGatePassesProvider =
    FutureProvider.autoDispose<List<ReceptionGatePass>>((ref) {
  return ref.watch(receptionRepositoryProvider).fetchGatePasses();
});

final callLogProvider =
    FutureProvider.autoDispose<List<CallLog>>((ref) {
  return ref.watch(receptionRepositoryProvider).fetchCallLog();
});

final appointmentsProvider =
    FutureProvider.autoDispose<List<Appointment>>((ref) {
  return ref.watch(receptionRepositoryProvider).fetchAppointments();
});

final lateArrivalsProvider =
    FutureProvider.autoDispose<List<LateArrival>>((ref) {
  return ref.watch(receptionRepositoryProvider).fetchLateArrivals();
});
