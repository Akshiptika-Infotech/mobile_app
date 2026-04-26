import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/admin/data/staff_repository.dart';
import 'package:mobile_app/features/admin/domain/user_staff_model.dart';

final staffListProvider =
    FutureProvider.autoDispose<List<StaffUser>>((ref) async {
  return ref.watch(staffRepositoryProvider).fetchUsers();
});

class StaffNotifier extends StateNotifier<AsyncValue<List<StaffUser>>> {
  StaffNotifier(this._repo) : super(const AsyncValue.loading()) {
    _load();
  }

  final StaffRepository _repo;

  Future<void> _load() async {
    if (!mounted) return;
    state = const AsyncValue.loading();
    try {
      final users = await _repo.fetchUsers();
      if (!mounted) return;
      state = AsyncValue.data(users);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> create(Map<String, dynamic> data) async {
    try {
      await _repo.createUser(data);
      if (!mounted) return;
      await _load();
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    try {
      await _repo.updateUser(id, data);
      if (!mounted) return;
      await _load();
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> delete(String id) async {
    await _repo.deleteUser(id);
    if (!mounted) return;
    await _load();
  }

  Future<String> resetPassword(String id) async {
    return _repo.resetPassword(id);
  }
}

final staffNotifierProvider = StateNotifierProvider.autoDispose<StaffNotifier,
    AsyncValue<List<StaffUser>>>((ref) {
  return StaffNotifier(ref.watch(staffRepositoryProvider));
});
