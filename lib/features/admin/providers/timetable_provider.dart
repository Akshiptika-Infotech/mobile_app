import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/admin/data/timetable_repository.dart';
import 'package:mobile_app/features/admin/domain/timetable_model.dart';

final timetableProvider =
    FutureProvider.autoDispose<List<TimetablePeriod>>((ref) async {
  final repo = ref.watch(timetableRepositoryProvider);
  return repo.fetchMyTimetable();
});

final adminTimetableProvider =
    FutureProvider.autoDispose<List<TimetablePeriod>>((ref) async {
  final repo = ref.watch(timetableRepositoryProvider);
  return repo.fetchAdminTimetable();
});
