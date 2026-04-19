import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/admin/data/settings_repository.dart';
import 'package:mobile_app/features/admin/domain/settings_model.dart';

final settingsProvider =
    FutureProvider.autoDispose<AppSettings>((ref) async {
  return ref.watch(settingsRepositoryProvider).fetchSettings();
});
