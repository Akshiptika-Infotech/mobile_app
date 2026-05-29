import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/features/admin/presentation/admin_shell.dart';
import 'package:mobile_app/features/admin/presentation/approvals/approvals_screen.dart';
import 'package:mobile_app/features/admin/presentation/attendance/mark_attendance_screen.dart';
import 'package:mobile_app/features/admin/presentation/attendance/my_attendance_screen.dart';
import 'package:mobile_app/features/admin/presentation/attendance/leave_requests_screen.dart';
import 'package:mobile_app/features/admin/presentation/attendance/staff_attendance_screen.dart';
import 'package:mobile_app/features/admin/presentation/attendance/student_attendance_screen.dart';
import 'package:mobile_app/features/admin/presentation/academic_years/academic_years_screen.dart';
import 'package:mobile_app/features/admin/presentation/calendar/calendar_screen.dart';
import 'package:mobile_app/features/admin/presentation/certificates/certificates_issued_screen.dart';
import 'package:mobile_app/features/admin/presentation/classes/classes_screen.dart';
import 'package:mobile_app/features/admin/presentation/dashboard_screen.dart'
    as admin;
import 'package:mobile_app/features/admin/presentation/digilocker/digilocker_screen.dart';
import 'package:mobile_app/features/admin/presentation/exams/mark_entry_screen.dart';
import 'package:mobile_app/features/admin/presentation/exams/report_cards_screen.dart';
import 'package:mobile_app/features/admin/presentation/fee_masters/concessions_screen.dart';
import 'package:mobile_app/features/admin/presentation/fee_masters/fee_structures_screen.dart';
import 'package:mobile_app/features/admin/presentation/fee_masters/fee_types_screen.dart';
import 'package:mobile_app/features/admin/presentation/fee_masters/late_fee_screen.dart';
import 'package:mobile_app/features/admin/presentation/fee_collection/fee_collection_screen.dart';
import 'package:mobile_app/features/admin/presentation/fee_collection/fee_history_screen.dart';
import 'package:mobile_app/features/admin/presentation/gate/entry_exit_log_screen.dart';
import 'package:mobile_app/features/admin/presentation/gate/gate_passes_admin_screen.dart';
import 'package:mobile_app/features/admin/presentation/gate/gate_visitors_screen.dart';
import 'package:mobile_app/features/admin/presentation/id_cards/student_id_cards_screen.dart';
import 'package:mobile_app/features/admin/presentation/masters/masters_screen.dart';
import 'package:mobile_app/features/admin/presentation/notifications/notification_log_screen.dart';
import 'package:mobile_app/features/admin/presentation/notifications/send_notification_screen.dart';
import 'package:mobile_app/features/admin/presentation/reception/reception_appointments_admin_screen.dart';
import 'package:mobile_app/features/admin/presentation/reception/reception_call_log_admin_screen.dart';
import 'package:mobile_app/features/admin/presentation/reception/reception_late_arrivals_admin_screen.dart';
import 'package:mobile_app/features/admin/presentation/reports/report_screen.dart';
import 'package:mobile_app/features/admin/presentation/settings/settings_screen.dart';
import 'package:mobile_app/features/admin/presentation/students/student_detail_screen.dart';
import 'package:mobile_app/features/admin/presentation/students/my_class_students_screen.dart';
import 'package:mobile_app/features/admin/presentation/students/students_list_screen.dart';
import 'package:mobile_app/features/admin/presentation/timetable/my_timetable_screen.dart';
import 'package:mobile_app/features/admin/presentation/timetable/timetable_screen.dart';
import 'package:mobile_app/features/admin/presentation/transport/transport_assignments_screen.dart';
import 'package:mobile_app/features/admin/presentation/transport/transport_rebates_screen.dart';
import 'package:mobile_app/features/admin/presentation/transport/transport_routes_screen.dart';
import 'package:mobile_app/features/admin/presentation/attendance/qr_live_screen.dart';
import 'package:mobile_app/features/admin/presentation/attendance/qr_scan_setup_screen.dart';
import 'package:mobile_app/features/admin/presentation/attendance/qr_scanner_screen.dart';
import 'package:mobile_app/features/admin/presentation/face/enrollment_list_screen.dart';
import 'package:mobile_app/features/admin/presentation/face/face_register_screen.dart';
import 'package:mobile_app/features/admin/presentation/face/face_scan_screen.dart';
import 'package:mobile_app/features/admin/presentation/more_screen.dart';
import 'package:mobile_app/features/admin/presentation/users/users_screen.dart';
import 'package:mobile_app/features/admin/domain/attendance_model.dart';
import 'package:mobile_app/features/auth/domain/user_model.dart';
import 'package:mobile_app/features/auth/presentation/change_password_screen.dart';
import 'package:mobile_app/features/auth/presentation/login_screen.dart';
import 'package:mobile_app/features/auth/providers/auth_provider.dart';
import 'package:mobile_app/features/profile/presentation/profile_screen.dart';
import 'package:mobile_app/features/teacher/presentation/dashboard_screen.dart'
    as teacher;
import 'package:mobile_app/features/teacher/presentation/exams_hub_screen.dart';
import 'package:mobile_app/features/teacher/presentation/leave_request_screen.dart';
import 'package:mobile_app/features/teacher/presentation/more_screen.dart'
    as teacher_more;
import 'package:mobile_app/features/teacher/presentation/teacher_subjects_screen.dart';
import 'package:mobile_app/features/teacher/presentation/teacher_shell.dart';
import 'package:mobile_app/features/driver/presentation/dashboard_screen.dart'
    as driver;
import 'package:mobile_app/features/driver/presentation/driver_shell.dart';
import 'package:mobile_app/features/driver/presentation/more_screen.dart'
    as driver_more;
import 'package:mobile_app/features/driver/presentation/route_screen.dart';
import 'package:mobile_app/features/driver/presentation/trip_screen.dart';
import 'package:mobile_app/features/security/presentation/dashboard_screen.dart'
    as security;
import 'package:mobile_app/features/security/presentation/entry_exit_log_screen.dart'
    as security_log;
import 'package:mobile_app/features/security/presentation/gate_passes_screen.dart';
import 'package:mobile_app/features/security/presentation/log_entry_exit_screen.dart';
import 'package:mobile_app/features/security/presentation/more_screen.dart'
    as security_more;
import 'package:mobile_app/features/security/presentation/register_visitor_screen.dart';
import 'package:mobile_app/features/security/presentation/security_shell.dart';
import 'package:mobile_app/features/security/presentation/visitors_screen.dart';
import 'package:mobile_app/features/parent/presentation/attendance_screen.dart';
import 'package:mobile_app/features/parent/presentation/calendar_screen.dart';
import 'package:mobile_app/features/parent/presentation/dashboard_screen.dart'
    as parent;
import 'package:mobile_app/features/parent/presentation/fees_screen.dart';
import 'package:mobile_app/features/parent/presentation/more_screen.dart'
    as parent_more;
import 'package:mobile_app/features/parent/presentation/parent_shell.dart';
import 'package:mobile_app/features/parent/presentation/profile_screen.dart'
    as parent_profile;
import 'package:mobile_app/features/parent/presentation/receipts_screen.dart';
import 'package:mobile_app/features/parent/presentation/timetable_screen.dart';
import 'package:mobile_app/features/parent/presentation/transport_screen.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  final router = GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggingIn = state.matchedLocation == '/login';

      if (authState is AuthInitial || authState is AuthLoading) {
        return null;
      }
      if (authState is AuthUnauthenticated || authState is AuthError) {
        return isLoggingIn ? null : '/login';
      }
      if (authState is AuthAuthenticated) {
        // Force first-login password rotation. The user can't reach any
        // portal route until the backend's `mustChangePassword` flag has
        // been cleared.
        final mustChange = authState.user.mustChangePassword;
        final onChangePw = state.matchedLocation == '/change-password';
        if (mustChange && !onChangePw) {
          return '/change-password';
        }
        if (!mustChange && onChangePw) {
          // Flag has been cleared — bounce them out to their portal.
          return '/login';
        }

        final role = authState.user.role;
        final isAdmin = AppRole.adminRoles.contains(role);
        final isTeacher = role == AppRole.teacher;
        final isDriver = role == AppRole.driver;
        final isSecurity = role == AppRole.securityGuard;
        final isParent = role == AppRole.parent;
        // Admin-family, teacher, driver, security and parent roles are wired
        // up. Other portals will be reintroduced one by one.
        if (!isAdmin && !isTeacher && !isDriver && !isSecurity && !isParent) {
          Future.microtask(
            () => ref.read(authProvider.notifier).logout(),
          );
          return '/login';
        }
        // Keep each role inside its own portal.
        final loc = state.matchedLocation;
        bool isOtherPortal(String prefix) =>
            loc.startsWith('/admin') ||
            loc.startsWith('/teacher') ||
            loc.startsWith('/driver') ||
            loc.startsWith('/security') ||
            loc.startsWith('/parent')
                ? !loc.startsWith(prefix)
                : false;
        if (isTeacher && isOtherPortal('/teacher')) {
          return '/teacher/dashboard';
        }
        if (isAdmin && isOtherPortal('/admin')) {
          return '/admin/dashboard';
        }
        if (isDriver && isOtherPortal('/driver')) {
          return '/driver/dashboard';
        }
        if (isSecurity && isOtherPortal('/security')) {
          return '/security/dashboard';
        }
        if (isParent && isOtherPortal('/parent')) {
          return '/parent/dashboard';
        }
        if (isLoggingIn) {
          if (isParent) return '/parent/dashboard';
          if (isSecurity) return '/security/dashboard';
          if (isDriver) return '/driver/dashboard';
          return isTeacher ? '/teacher/dashboard' : '/admin/dashboard';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (_, __) => const ChangePasswordScreen(),
      ),

      // ── Admin shell ──────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (_, __) => const admin.DashboardScreen(),
          ),
          GoRoute(
            path: '/admin/approvals',
            builder: (_, __) => const ApprovalsScreen(),
          ),
          GoRoute(
            // Add / edit student lives on the web admin portal — the mobile
            // app is read-only for student records (plus teacher photo update).
            path: '/admin/students',
            builder: (_, __) => const StudentsListScreen(),
            routes: [
              GoRoute(
                path: 'my-class',
                builder: (_, __) => const MyClassStudentsScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    StudentDetailScreen(studentId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/admin/fee-collection',
            builder: (_, __) => const FeeCollectionScreen(),
          ),
          GoRoute(
            path: '/admin/fee-collection/history',
            builder: (_, __) => const FeeHistoryScreen(),
          ),
          GoRoute(
            path: '/admin/timetable/my',
            builder: (_, __) => const MyTimetableScreen(),
          ),
          GoRoute(
            path: '/admin/attendance/my-class',
            builder: (_, __) => const MarkAttendanceScreen(),
          ),
          GoRoute(
            path: '/admin/attendance/my-attendance',
            builder: (_, __) => const MyAttendanceScreen(),
          ),
          GoRoute(
            path: '/admin/exams/marks',
            builder: (_, __) => const MarkEntryScreen(),
          ),
          GoRoute(
            path: '/admin/exams/report-cards',
            builder: (_, __) => const ReportCardsScreen(),
          ),
          GoRoute(
            path: '/admin/calendar',
            builder: (_, __) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/admin/reports/:type',
            builder: (_, state) =>
                ReportScreen(reportType: state.pathParameters['type']!),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (_, __) => const UsersScreen(),
          ),
          GoRoute(
            path: '/admin/notifications/send',
            builder: (_, __) => const SendNotificationScreen(),
          ),
          GoRoute(
            path: '/admin/notifications/log',
            builder: (_, __) => const NotificationLogScreen(),
          ),
          GoRoute(
            path: '/admin/masters/:model',
            builder: (_, state) =>
                MastersScreen(model: state.pathParameters['model']!),
          ),
          GoRoute(
            path: '/admin/classes',
            builder: (_, __) => const ClassesScreen(),
          ),
          GoRoute(
            path: '/admin/academic-years',
            builder: (_, __) => const AcademicYearsScreen(),
          ),
          GoRoute(
            path: '/admin/fee-masters/fee-types',
            builder: (_, __) => const FeeTypesScreen(),
          ),
          GoRoute(
            path: '/admin/fee-masters/fee-structures',
            builder: (_, __) => const FeeStructuresScreen(),
          ),
          GoRoute(
            path: '/admin/fee-masters/concessions',
            builder: (_, __) => const ConcessionsScreen(),
          ),
          GoRoute(
            path: '/admin/fee-masters/late-fee',
            builder: (_, __) => const LateFeeScreen(),
          ),
          GoRoute(
            path: '/admin/transport/routes',
            builder: (_, __) => const TransportRoutesScreen(),
          ),
          GoRoute(
            path: '/admin/transport/assignments',
            builder: (_, __) => const TransportAssignmentsScreen(),
          ),
          GoRoute(
            path: '/admin/transport/rebates',
            builder: (_, __) => const TransportRebatesScreen(),
          ),
          GoRoute(
            path: '/admin/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/admin/digilocker-pins',
            builder: (_, __) => const DigiLockerScreen(),
          ),
          GoRoute(
            path: '/admin/gate/visitors',
            builder: (_, __) => const GateVisitorsScreen(),
          ),
          GoRoute(
            path: '/admin/gate/gate-passes',
            builder: (_, __) => const GatePassesAdminScreen(),
          ),
          GoRoute(
            path: '/admin/gate/entry-exit-log',
            builder: (_, __) => const EntryExitLogScreen(),
          ),
          GoRoute(
            path: '/admin/reception/call-log',
            builder: (_, __) => const ReceptionCallLogAdminScreen(),
          ),
          GoRoute(
            path: '/admin/reception/appointments',
            builder: (_, __) => const ReceptionAppointmentsAdminScreen(),
          ),
          GoRoute(
            path: '/admin/reception/late-arrivals',
            builder: (_, __) => const ReceptionLateArrivalsAdminScreen(),
          ),
          GoRoute(
            path: '/admin/attendance/students',
            builder: (_, __) => const StudentAttendanceScreen(),
          ),
          GoRoute(
            path: '/admin/attendance/staff',
            builder: (_, __) => const StaffAttendanceScreen(),
          ),
          GoRoute(
            path: '/admin/attendance/leaves',
            builder: (_, __) => const LeaveRequestsScreen(),
          ),
          GoRoute(
            path: '/admin/certificates/issued',
            builder: (_, __) => const CertificatesIssuedScreen(),
          ),
          GoRoute(
            path: '/admin/id-cards/students',
            builder: (_, __) => const StudentIdCardsScreen(),
          ),
          GoRoute(
            path: '/admin/timetable',
            builder: (_, __) => const TimetableScreen(),
          ),
          // QR Attendance
          GoRoute(
            path: '/admin/attendance/qr-setup',
            builder: (_, __) => const QrScanSetupScreen(),
          ),
          GoRoute(
            path: '/admin/attendance/qr-scan',
            builder: (_, state) =>
                QrScannerScreen(params: state.extra as QrScanParams),
          ),
          GoRoute(
            path: '/admin/attendance/qr-live',
            builder: (_, state) =>
                QrLiveScreen(params: state.extra as QrScanParams),
          ),
          // Face Attendance
          GoRoute(
            path: '/admin/face/enrollment',
            builder: (_, __) => const EnrollmentListScreen(),
          ),
          GoRoute(
            path: '/admin/face/register',
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return FaceRegisterScreen(
                type: extra?['type'] as String? ?? 'student',
                name: extra?['name'] as String?,
                admissionNumber: extra?['admissionNumber'] as String?,
                identifier: extra?['identifier'] as String?,
              );
            },
          ),
          GoRoute(
            path: '/admin/face/scan',
            builder: (_, state) =>
                FaceScanScreen(params: state.extra as FaceScanParams),
          ),
          GoRoute(
            path: '/admin/more',
            builder: (_, __) => const MoreScreen(),
          ),
          GoRoute(
            path: '/admin/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),

      // ── Teacher shell ────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => TeacherShell(child: child),
        routes: [
          GoRoute(
            path: '/teacher/dashboard',
            builder: (_, __) => const teacher.TeacherDashboardScreen(),
          ),
          GoRoute(
            // Teachers can view their class roster and individual students,
            // but can only update the student photo — full edit and add are
            // admin/clerk only.
            path: '/teacher/class',
            builder: (_, __) => const MyClassStudentsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    StudentDetailScreen(studentId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/teacher/attendance',
            builder: (_, __) => const MarkAttendanceScreen(),
            routes: [
              GoRoute(
                path: 'qr-setup',
                builder: (_, __) => const QrScanSetupScreen(),
              ),
              GoRoute(
                path: 'qr-scan',
                builder: (_, state) =>
                    QrScannerScreen(params: state.extra as QrScanParams),
              ),
              GoRoute(
                path: 'qr-live',
                builder: (_, state) =>
                    QrLiveScreen(params: state.extra as QrScanParams),
              ),
            ],
          ),
          GoRoute(
            path: '/teacher/exams',
            builder: (_, __) => const TeacherExamsHubScreen(),
            routes: [
              GoRoute(
                path: 'marks',
                builder: (_, __) => const MarkEntryScreen(),
              ),
              GoRoute(
                path: 'report-cards',
                builder: (_, __) => const ReportCardsScreen(),
              ),
              GoRoute(
                path: 'subjects',
                builder: (_, __) => const TeacherSubjectsScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/teacher/more',
            builder: (_, __) => const teacher_more.TeacherMoreScreen(),
          ),
          GoRoute(
            path: '/teacher/timetable',
            builder: (_, __) => const MyTimetableScreen(),
          ),
          GoRoute(
            path: '/teacher/calendar',
            builder: (_, __) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/teacher/my-attendance',
            builder: (_, __) => const MyAttendanceScreen(),
          ),
          GoRoute(
            path: '/teacher/leaves',
            builder: (_, __) => const TeacherLeaveScreen(),
          ),
          GoRoute(
            path: '/teacher/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),

      // ── Driver shell ─────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => DriverShell(child: child),
        routes: [
          GoRoute(
            path: '/driver/dashboard',
            builder: (_, __) => const driver.DriverDashboardScreen(),
          ),
          GoRoute(
            path: '/driver/route',
            builder: (_, __) => const DriverRouteScreen(),
          ),
          GoRoute(
            path: '/driver/trip',
            builder: (_, __) => const DriverTripScreen(),
          ),
          GoRoute(
            path: '/driver/more',
            builder: (_, __) => const driver_more.DriverMoreScreen(),
          ),
        ],
      ),

      // ── Security shell ───────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => SecurityShell(child: child),
        routes: [
          GoRoute(
            path: '/security/dashboard',
            builder: (_, __) => const security.SecurityDashboardScreen(),
          ),
          GoRoute(
            path: '/security/visitors',
            builder: (_, __) => const SecurityVisitorsScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, __) => const RegisterVisitorScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/security/entry-exit',
            builder: (_, __) => const security_log.EntryExitLogScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, state) {
                  final extra = state.extra;
                  final scanFirst = extra is Map<String, dynamic> &&
                      extra['scanFirst'] == true;
                  return LogEntryExitScreen(scanFirst: scanFirst);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/security/gate-passes',
            builder: (_, __) => const GatePassesScreen(),
          ),
          GoRoute(
            path: '/security/more',
            builder: (_, __) => const security_more.SecurityMoreScreen(),
          ),
        ],
      ),

      // ── Parent shell ─────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => ParentShell(child: child),
        routes: [
          GoRoute(
            path: '/parent/dashboard',
            builder: (_, __) => const parent.ParentDashboardScreen(),
          ),
          GoRoute(
            path: '/parent/fees',
            builder: (_, __) => const ParentFeesScreen(),
          ),
          GoRoute(
            path: '/parent/attendance',
            builder: (_, __) => const ParentAttendanceScreen(),
          ),
          GoRoute(
            path: '/parent/transport',
            builder: (_, __) => const ParentTransportScreen(),
          ),
          GoRoute(
            path: '/parent/more',
            builder: (_, __) => const parent_more.ParentMoreScreen(),
          ),
          GoRoute(
            path: '/parent/receipts',
            builder: (_, __) => const ParentReceiptsScreen(),
          ),
          GoRoute(
            path: '/parent/calendar',
            builder: (_, __) => const ParentCalendarScreen(),
          ),
          GoRoute(
            path: '/parent/timetable',
            builder: (_, __) => const ParentTimetableScreen(),
          ),
          GoRoute(
            path: '/parent/profile',
            builder: (_, __) => const parent_profile.ParentProfileScreen(),
          ),
        ],
      ),
    ],
  );

  ref.onDispose(notifier.dispose);
  return router;
});

// ── GoRouter refresh bridge ───────────────────────────────────────────────────

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    _subscription = ref.listen<AuthState>(authProvider, (_, __) {
      notifyListeners();
    });
  }

  late final ProviderSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
