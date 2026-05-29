import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/admin/domain/my_profile_model.dart';

/// Fetches and caches the signed-in staff user from `/api/admin/me`.
///
/// Kept alive while any widget watches it (e.g. [TeacherShell]) so that
/// `isMotherTeacher`, `assignedClassId`, and `assignedSectionId` are
/// available without re-fetching on every screen.
class MyProfileNotifier extends StateNotifier<AsyncValue<MyProfile>> {
  MyProfileNotifier(this._dio) : super(const AsyncValue.loading()) {
    load();
  }

  final Dio _dio;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final res = await _dio.get('/api/admin/me');
      final profile = MyProfile.fromJson(res.data as Map<String, dynamic>);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void refresh() => load();
}

final myProfileProvider =
    StateNotifierProvider<MyProfileNotifier, AsyncValue<MyProfile>>((ref) {
  return MyProfileNotifier(ref.watch(dioClientProvider));
});
