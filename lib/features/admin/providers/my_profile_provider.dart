import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/admin/domain/my_profile_model.dart';

/// Fetches the signed-in staff user, including their assigned class and
/// section. Returned by `/api/admin/me` — used by teacher-aware screens
/// (QR attendance setup, mark entry, etc.) to lock or prefill class/section.
final myProfileProvider = FutureProvider.autoDispose<MyProfile>((ref) async {
  final dio = ref.watch(dioClientProvider);
  final res = await dio.get('/api/admin/me');
  return MyProfile.fromJson(res.data as Map<String, dynamic>);
});
