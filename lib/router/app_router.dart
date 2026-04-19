import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/features/admin/presentation/admin_shell.dart';
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
import 'package:mobile_app/features/admin/presentation/students/student_add_screen.dart';
import 'package:mobile_app/features/admin/presentation/students/student_detail_screen.dart';
import 'package:mobile_app/features/admin/presentation/students/student_edit_screen.dart';
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
import 'package:mobile_app/features/security/presentation/face_verify_screen.dart';
import 'package:mobile_app/features/driver/presentation/bus_attendance_screen.dart';
import 'package:mobile_app/features/driver/presentation/route_screen.dart';
import 'package:mobile_app/features/driver/presentation/student_roster_screen.dart';
import 'package:mobile_app/features/security/presentation/entry_exit_screen.dart';
import 'package:mobile_app/features/security/presentation/gate_passes_screen.dart';
import 'package:mobile_app/features/security/presentation/visitors_screen.dart';
import 'package:mobile_app/features/auth/domain/user_model.dart';
import 'package:mobile_app/features/auth/presentation/login_screen.dart';
import 'package:mobile_app/features/auth/providers/auth_provider.dart';
import 'package:mobile_app/features/driver/presentation/dashboard_screen.dart'
    as driver;
import 'package:mobile_app/features/driver/presentation/driver_shell.dart';
import 'package:mobile_app/features/parent/presentation/dashboard_screen.dart'
    as parent;
import 'package:mobile_app/features/parent/presentation/parent_calendar_screen.dart';
import 'package:mobile_app/features/parent/presentation/parent_shell.dart';
import 'package:mobile_app/features/parent/presentation/parent_timetable_screen.dart';
import 'package:mobile_app/features/profile/presentation/profile_screen.dart';
import 'package:mobile_app/features/reception/presentation/appointments_screen.dart';
import 'package:mobile_app/features/reception/presentation/call_log_screen.dart';
import 'package:mobile_app/features/reception/presentation/dashboard_screen.dart'
    as reception;
import 'package:mobile_app/features/reception/presentation/late_arrivals_screen.dart';
import 'package:mobile_app/features/reception/presentation/reception_shell.dart';
import 'package:mobile_app/features/reception/presentation/visitors_screen.dart'
    as reception_visitors;
import 'package:mobile_app/features/security/presentation/dashboard_screen.dart'
    as security;
import 'package:mobile_app/features/security/presentation/security_shell.dart';
import 'package:mobile_app/features/student/presentation/dashboard_screen.dart'
    as student;
import 'package:mobile_app/features/student/presentation/fee_matrix_screen.dart';
import 'package:mobile_app/features/student/presentation/receipts_screen.dart'
    as student_receipts;
import 'package:mobile_app/features/student/presentation/student_shell.dart';
import 'package:mobile_app/features/student/presentation/transport_screen.dart';
import 'package:mobile_app/features/parent/presentation/child_fees_screen.dart';
import 'package:mobile_app/features/parent/presentation/receipts_screen.dart'
    as parent_receipts;
import 'package:mobile_app/features/web_admin/presentation/web_admin_shell.dart';
import 'package:mobile_app/features/web_admin/presentation/web_admin_dashboard_screen.dart'
    as web_admin;
import 'package:mobile_app/features/web_admin/presentation/content_screen.dart';
import 'package:mobile_app/features/web_admin/presentation/gallery_screen.dart';
import 'package:mobile_app/features/web_admin/presentation/more_screen.dart';
import 'package:mobile_app/features/web_admin/presentation/pages_screen.dart';
import 'package:mobile_app/features/web_admin/presentation/website_settings_screen.dart';

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
      if (authState is AuthAuthenticated && isLoggingIn) {
        return _homeForRole(authState.user.role);
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
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
            path: '/admin/students',
            builder: (_, __) => const StudentsListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, __) => const StudentAddScreen(),
              ),
              GoRoute(
                path: 'my-class',
                builder: (_, __) => const MyClassStudentsScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    StudentDetailScreen(studentId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, state) => StudentEditScreen(
                        studentId: state.pathParameters['id']!),
                  ),
                ],
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

      // ── Driver shell ─────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => DriverShell(child: child),
        routes: [
          GoRoute(
            path: '/driver/dashboard',
            builder: (_, __) => const driver.DashboardScreen(),
          ),
          GoRoute(
            path: '/driver/route',
            builder: (_, __) => const RouteScreen(),
          ),
          GoRoute(
            path: '/driver/students',
            builder: (_, __) => const StudentRosterScreen(),
          ),
          GoRoute(
            path: '/driver/attendance',
            builder: (_, __) => const BusAttendanceScreen(),
          ),
          GoRoute(
            path: '/driver/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),

      // ── Security shell ───────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => SecurityShell(child: child),
        routes: [
          GoRoute(
            path: '/security/dashboard',
            builder: (_, __) => const security.DashboardScreen(),
          ),
          GoRoute(
            path: '/security/entry-exit',
            builder: (_, __) => const EntryExitScreen(),
          ),
          GoRoute(
            path: '/security/visitors',
            builder: (_, __) => const VisitorsScreen(),
          ),
          GoRoute(
            path: '/security/passes',
            builder: (_, __) => const GatePassesScreen(),
          ),
          GoRoute(
            path: '/security/face-verify',
            builder: (_, __) => const FaceVerifyScreen(),
          ),
          GoRoute(
            path: '/security/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),

      // ── Reception shell ──────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => ReceptionShell(child: child),
        routes: [
          GoRoute(
            path: '/reception/dashboard',
            builder: (_, __) => const reception.DashboardScreen(),
          ),
          GoRoute(
            path: '/reception/visitors',
            builder: (_, __) => const reception_visitors.ReceptionVisitorsScreen(),
          ),
          GoRoute(
            path: '/reception/calls',
            builder: (_, __) => const CallLogScreen(),
          ),
          GoRoute(
            path: '/reception/more',
            builder: (_, __) => const AppointmentsScreen(),
          ),
          GoRoute(
            path: '/reception/appointments',
            builder: (_, __) => const AppointmentsScreen(),
          ),
          GoRoute(
            path: '/reception/late-arrivals',
            builder: (_, __) => const LateArrivalsScreen(),
          ),
          GoRoute(
            path: '/reception/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),

      // ── Student shell ────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => StudentShell(child: child),
        routes: [
          GoRoute(
            path: '/student/dashboard',
            builder: (_, __) => const student.DashboardScreen(),
          ),
          GoRoute(
            path: '/student/fees',
            builder: (_, __) => const FeeMatrixScreen(),
          ),
          GoRoute(
            path: '/student/receipts',
            builder: (_, __) => const student_receipts.StudentReceiptsScreen(),
          ),
          GoRoute(
            path: '/student/transport',
            builder: (_, __) => const TransportScreen(),
          ),
          GoRoute(
            path: '/student/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),

      // ── Parent shell ─────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => ParentShell(child: child),
        routes: [
          GoRoute(
            path: '/parent/dashboard',
            builder: (_, __) => const parent.DashboardScreen(),
          ),
          GoRoute(
            path: '/parent/receipts',
            builder: (_, __) =>
                const parent_receipts.ParentReceiptsScreen(),
          ),
          GoRoute(
            path: '/parent/children/:id',
            builder: (_, state) => ChildFeesScreen(
              childId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/parent/timetable',
            builder: (_, __) => const ParentTimetableScreen(),
          ),
          GoRoute(
            path: '/parent/calendar',
            builder: (_, __) => const ParentCalendarScreen(),
          ),
          GoRoute(
            path: '/parent/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),

      // ── Web Admin shell ──────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => WebAdminShell(child: child),
        routes: [
          GoRoute(
            path: '/web-admin/dashboard',
            builder: (_, __) => const web_admin.WebAdminDashboardScreen(),
          ),
          GoRoute(
            path: '/web-admin/content',
            builder: (_, __) => const ContentScreen(),
          ),
          GoRoute(
            path: '/web-admin/gallery',
            builder: (_, __) => const GalleryScreen(),
          ),
          GoRoute(
            path: '/web-admin/more',
            builder: (_, __) => const WebAdminMoreScreen(),
          ),
          GoRoute(
            path: '/web-admin/pages',
            builder: (_, __) => const PagesScreen(),
          ),
          GoRoute(
            path: '/web-admin/settings',
            builder: (_, __) => const WebsiteSettingsScreen(),
          ),
          GoRoute(
            path: '/web-admin/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );

  ref.onDispose(notifier.dispose);
  return router;
});

// ── Helpers ───────────────────────────────────────────────────────────────────

String _homeForRole(String role) {
  if (AppRole.adminRoles.contains(role)) return '/admin/dashboard';
  switch (role) {
    case AppRole.driver:
      return '/driver/dashboard';
    case AppRole.securityGuard:
      return '/security/dashboard';
    case AppRole.receptionist:
      return '/reception/dashboard';
    case AppRole.student:
      return '/student/dashboard';
    case AppRole.parent:
      return '/parent/dashboard';
    case AppRole.webAdmin:
      return '/web-admin/dashboard';
    default:
      return '/admin/dashboard';
  }
}

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

