import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/teacher/data/teacher_leave_repository.dart';
import 'package:mobile_app/features/teacher/domain/leave_request_model.dart';

/// All of the teacher's own leave requests, newest first.
final myLeavesProvider =
    FutureProvider.autoDispose<List<LeaveRequestModel>>((ref) async {
  return ref.watch(teacherLeaveRepositoryProvider).fetchMyLeaves();
});

/// State for the leave-submission form.
class LeaveSubmissionState {
  const LeaveSubmissionState({
    this.isSubmitting = false,
    this.error,
    this.success = false,
  });

  final bool isSubmitting;
  final String? error;
  final bool success;

  LeaveSubmissionState copyWith({
    bool? isSubmitting,
    String? error,
    bool? success,
    bool clearError = false,
  }) {
    return LeaveSubmissionState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      success: success ?? this.success,
    );
  }
}

class LeaveSubmissionNotifier extends StateNotifier<LeaveSubmissionState> {
  LeaveSubmissionNotifier(this._ref) : super(const LeaveSubmissionState());

  final Ref _ref;

  Future<bool> submit({
    required DateTime fromDate,
    required DateTime toDate,
    required String leaveType,
    required String reason,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true, success: false);
    try {
      await _ref.read(teacherLeaveRepositoryProvider).submitLeave(
            fromDate: fromDate,
            toDate: toDate,
            leaveType: leaveType,
            reason: reason,
          );
      state = const LeaveSubmissionState(success: true);
      _ref.invalidate(myLeavesProvider);
      return true;
    } catch (e) {
      state = LeaveSubmissionState(error: _humanise(e.toString()));
      return false;
    }
  }

  void reset() => state = const LeaveSubmissionState();

  String _humanise(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('unauthorized') || lower.contains('401')) {
      return 'Your session has expired. Please sign in again.';
    }
    if (lower.contains('network') || lower.contains('socket')) {
      return 'No internet connection. Please try again.';
    }
    if (lower.contains('422')) {
      return 'Please review the form and try again.';
    }
    return raw.replaceAll('Exception: ', '');
  }
}

final leaveSubmissionProvider =
    StateNotifierProvider.autoDispose<LeaveSubmissionNotifier, LeaveSubmissionState>(
  (ref) => LeaveSubmissionNotifier(ref),
);
