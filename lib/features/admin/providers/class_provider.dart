import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/admin/data/class_repository.dart';
import 'package:mobile_app/features/admin/domain/class_model.dart';

final classesProvider =
    FutureProvider.autoDispose<List<SchoolClass>>((ref) async {
  return ref.watch(classRepositoryProvider).fetchClasses();
});

final academicYearsProvider =
    FutureProvider.autoDispose<List<AcademicYear>>((ref) async {
  return ref.watch(classRepositoryProvider).fetchAcademicYears();
});

final sectionsProvider =
    FutureProvider.autoDispose<List<Section>>((ref) async {
  return ref.watch(classRepositoryProvider).fetchSections();
});
