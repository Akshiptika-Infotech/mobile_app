import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/face/data/face_repository.dart';
import 'package:mobile_app/features/face/domain/face_model.dart';

// ── Enrollment list ───────────────────────────────────────────────────────────

class EnrollmentParams {
  const EnrollmentParams({
    required this.type,
    this.classId,
    this.sectionId,
    this.academicYearId,
    this.role,
  });

  final String type; // 'student' | 'staff'
  final String? classId;
  final String? sectionId;
  final String? academicYearId;
  final String? role;

  @override
  bool operator ==(Object other) =>
      other is EnrollmentParams &&
      other.type == type &&
      other.classId == classId &&
      other.sectionId == sectionId &&
      other.academicYearId == academicYearId &&
      other.role == role;

  @override
  int get hashCode => Object.hash(type, classId, sectionId, academicYearId, role);
}

final enrollmentListProvider = FutureProvider.autoDispose
    .family<FaceEnrollmentList, EnrollmentParams>((ref, params) {
  return ref.watch(faceRepositoryProvider).fetchEnrollmentList(
        type: params.type,
        classId: params.classId,
        sectionId: params.sectionId,
        academicYearId: params.academicYearId,
        role: params.role,
      );
});

// ── Face registration state ───────────────────────────────────────────────────

class FaceRegisterState {
  const FaceRegisterState({
    this.isCapturing = false,
    this.isSubmitting = false,
    this.result,
    this.error,
  });

  final bool isCapturing;
  final bool isSubmitting;
  final FaceRegisterResult? result;
  final String? error;

  bool get isSuccess => result?.ok == true;

  FaceRegisterState copyWith({
    bool? isCapturing,
    bool? isSubmitting,
    FaceRegisterResult? result,
    String? error,
  }) =>
      FaceRegisterState(
        isCapturing: isCapturing ?? this.isCapturing,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        result: result ?? this.result,
        error: error,
      );
}

class FaceRegisterNotifier extends StateNotifier<FaceRegisterState> {
  FaceRegisterNotifier(this._repo) : super(const FaceRegisterState());

  final FaceRepository _repo;

  Future<void> register({
    required String type,
    String? admissionNumber,
    String? identifier,
    required List<double> embedding,
  }) async {
    if (!mounted) return;
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final result = await _repo.registerFace(
        type: type,
        admissionNumber: admissionNumber,
        identifier: identifier,
        embedding: embedding,
      );
      if (!mounted) return;
      state = state.copyWith(isSubmitting: false, result: result);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isSubmitting: false, error: e.toString());
    }
  }

  Future<void> delete({
    required String type,
    String? admissionNumber,
    String? identifier,
  }) async {
    if (!mounted) return;
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      await _repo.deleteFaceRegistration(
        type: type,
        admissionNumber: admissionNumber,
        identifier: identifier,
      );
      if (!mounted) return;
      state = const FaceRegisterState();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isSubmitting: false, error: e.toString());
    }
  }

  void reset() => state = const FaceRegisterState();
}

final faceRegisterNotifierProvider =
    StateNotifierProvider.autoDispose<FaceRegisterNotifier, FaceRegisterState>(
        (ref) => FaceRegisterNotifier(ref.watch(faceRepositoryProvider)));

// ── Face verify state (live scan) ─────────────────────────────────────────────

class FaceVerifyState {
  const FaceVerifyState({
    this.result,
    this.isProcessing = false,
    this.error,
    this.frameCount = 0,
  });

  final FaceVerifyResult? result;
  final bool isProcessing;
  final String? error;
  final int frameCount;

  FaceVerifyState copyWith({
    FaceVerifyResult? result,
    bool? isProcessing,
    String? error,
    int? frameCount,
  }) =>
      FaceVerifyState(
        result: result ?? this.result,
        isProcessing: isProcessing ?? this.isProcessing,
        error: error,
        frameCount: frameCount ?? this.frameCount,
      );

  FaceVerifyState clearResult() => FaceVerifyState(
        isProcessing: isProcessing,
        frameCount: frameCount,
      );
}

class FaceVerifyNotifier extends StateNotifier<FaceVerifyState> {
  FaceVerifyNotifier(this._repo) : super(const FaceVerifyState());

  final FaceRepository _repo;

  Future<void> verify({
    required List<double> embedding,
    required String date,
    required String attendanceType,
    double threshold = 0.6,
    String? classId,
    String? sectionId,
    String? academicYearId,
  }) async {
    if (state.isProcessing || !mounted) return;
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final result = await _repo.verifyFace(
        embedding: embedding,
        date: date,
        attendanceType: attendanceType,
        threshold: threshold,
        classId: classId,
        sectionId: sectionId,
        academicYearId: academicYearId,
      );
      if (!mounted) return;
      state = state.copyWith(
        result: result,
        isProcessing: false,
        frameCount: state.frameCount + 1,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isProcessing: false, error: e.toString());
    }
  }

  void clearResult() {
    if (!mounted) return;
    state = state.clearResult();
  }
}

final faceVerifyNotifierProvider =
    StateNotifierProvider.autoDispose<FaceVerifyNotifier, FaceVerifyState>(
        (ref) => FaceVerifyNotifier(ref.watch(faceRepositoryProvider)));
