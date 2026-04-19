import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/admin/data/certificate_repository.dart';
import 'package:mobile_app/features/admin/domain/certificate_model.dart';

class CertificateState {
  const CertificateState({
    this.certificates = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  final List<CertificateModel> certificates;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  CertificateState copyWith({
    List<CertificateModel>? certificates,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
  }) {
    return CertificateState(
      certificates: certificates ?? this.certificates,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

class CertificateNotifier extends StateNotifier<CertificateState> {
  CertificateNotifier(this._repo) : super(const CertificateState()) {
    load();
  }

  final CertificateRepository _repo;

  Future<void> load() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);
    try {
      final certs = await _repo.fetchCertificates();
      if (!mounted) return;
      state = state.copyWith(certificates: certs, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> issue({
    required String studentId,
    required String type,
    required String date,
  }) async {
    if (!mounted) return;
    state = state.copyWith(isSubmitting: true);
    try {
      final cert = await _repo.issueCertificate(
        studentId: studentId,
        type: type,
        date: date,
      );
      if (!mounted) return;
      state = state.copyWith(
        certificates: [cert, ...state.certificates],
        isSubmitting: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isSubmitting: false, error: e.toString());
    }
  }
}

final certificateProvider =
    StateNotifierProvider.autoDispose<CertificateNotifier, CertificateState>(
        (ref) {
  return CertificateNotifier(ref.watch(certificateRepositoryProvider));
});
