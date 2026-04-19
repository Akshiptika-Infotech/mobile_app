import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/admin/data/digilocker_repository.dart';
import 'package:mobile_app/features/admin/domain/digilocker_model.dart';

final digiLockerPinsProvider =
    FutureProvider.autoDispose<List<DigiLockerPin>>((ref) async {
  return ref.watch(digilockerRepositoryProvider).fetchPins();
});
