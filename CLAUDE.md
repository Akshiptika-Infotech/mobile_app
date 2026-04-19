# School Management Flutter App

## Project Overview
A production-grade Flutter mobile application serving **3 separate school brands** from a single codebase using Flutter Flavors. Each app connects to its own domain's REST API.

| Flavor | App Name | Package ID | Base URL | Primary Color |
|---|---|---|---|---|
| `jmukhisics` | JMUKHISICS | `in.jmukhisics.mobile_app` | `https://jmukhisics.in` | `#1e40af` (Blue) |
| `sicschool` | SIC School | `in.sicschool.mobile_app` | `https://sicschool.in` | `#166534` (Green) |
| `schoolfeepro` | SchoolFeePro | `in.schoolfeepro.mobile_app` | `https://schoolfeepro.in` | `#7c3aed` (Purple) |

## Architecture

### Clean Architecture (Feature-First)
```
lib/
├── app.dart                    # Root MaterialApp.router widget
├── app_config.dart             # Flavor config (AppConfig + InheritedWidget)
├── main.dart                   # Default entry (jmukhisics for dev)
├── main_jmukhisics.dart        # Flavor entry point
├── main_sicschool.dart         # Flavor entry point
├── main_schoolfeepro.dart      # Flavor entry point
├── core/
│   ├── network/
│   │   └── dio_client.dart     # Dio instance with cookie-based auth
│   ├── storage/
│   │   └── secure_storage.dart # flutter_secure_storage wrapper
│   └── theme/
│       └── app_theme.dart      # Material 3 theme (light + dark)
├── router/
│   └── app_router.dart         # go_router with role-based ShellRoutes
├── features/
│   ├── auth/                   # Login, session, user model
│   ├── admin/                  # Admin/Clerk/Teacher screens (shared shell)
│   ├── driver/                 # Driver portal
│   ├── security/               # Security guard portal
│   ├── reception/              # Receptionist portal
│   ├── student/                # Student portal
│   ├── parent/                 # Parent portal
│   └── profile/                # Shared profile screen
```

### Each Feature Contains
```
features/<name>/
├── data/           # Repository classes (API calls via Dio)
├── domain/         # Models (fromJson/toJson/copyWith)
├── presentation/   # Screens and widgets
└── providers/      # Riverpod providers and StateNotifiers
```

## Tech Stack
- **Framework**: Flutter (Dart) — SDK ^3.11.4
- **State Management**: Riverpod (`flutter_riverpod` + `StateNotifier`)
- **Navigation**: `go_router` with `ShellRoute` per role group
- **HTTP Client**: `Dio` with `dio_cookie_manager` for session cookies
- **Auth**: NextAuth cookie-based session (POST `/api/auth/callback/credentials`, GET `/api/auth/session`)
- **Storage**: `flutter_secure_storage` for session persistence
- **Theming**: Material 3 with `ColorScheme.fromSeed()` per flavor

## Auth Flow
1. POST `/api/auth/csrf` → get csrfToken
2. POST `/api/auth/callback/credentials` (form-urlencoded) → sets session cookie
3. GET `/api/auth/session` → returns `{ user: { id, name, email, role } }`
4. Role determines redirect → `/admin/dashboard`, `/driver/dashboard`, etc.

## Roles and Navigation Shells
| Role | Shell | Bottom Tabs |
|---|---|---|
| SUPER_ADMIN, ADMIN, CLERK | AdminShell | Dashboard, Students, Fees, More |
| TEACHER | AdminShell (variant) | Dashboard, Timetable, Attendance, Exams, Calendar |
| DRIVER | DriverShell | Dashboard, Route, Students, Attendance |
| SECURITY_GUARD | SecurityShell | Dashboard, Entry/Exit, Visitors, Passes |
| RECEPTIONIST | ReceptionShell | Dashboard, Visitors, Calls, More |
| STUDENT | StudentShell | Dashboard, Fees, Receipts, Transport, Profile |
| PARENT | ParentShell | Dashboard, Receipts, Calendar, Profile |

## API Conventions
- All endpoints live under `/api/*` on the flavor's `baseUrl`
- Admin endpoints: `/api/admin/*`
- Driver: `/api/driver/*`
- Student: `/api/student/*`
- Parent: `/api/parent/*`
- Payments: `/api/payment/*`
- Receipts PDF: `GET /api/receipts/[collectionId]`
- No backend modifications allowed — use existing endpoints only

## Coding Conventions
- Use `ConsumerWidget` / `ConsumerStatefulWidget` for Riverpod integration
- Repositories return domain models, never raw JSON
- Providers use `StateNotifierProvider` for complex state, `FutureProvider` for simple fetches
- All screens handle 3 states: loading (skeleton), error (retry), empty
- Use `Theme.of(context).colorScheme` for colors — never hardcode
- Currency formatting: `NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)`
- Private widgets prefixed with `_` and kept in same file when <100 lines

## Build Commands
```bash
flutter run -t lib/main_jmukhisics.dart --flavor jmukhisics
flutter build apk --flavor jmukhisics -t lib/main_jmukhisics.dart
flutter build appbundle --flavor sicschool -t lib/main_sicschool.dart
```

## Current Status
- ✅ Phases M1–M7 complete (foundation, auth, admin core, teacher, driver, security, reception, student, parent)
- 🔲 Phase M8 in progress: Admin extended screens (reports, users, calendar CRUD, timetable admin, notifications, certificates, masters, fee masters, transport, gate admin, reception admin, digilocker, settings)
- 🔲 Phase M9 pending: Polish & release (FCM, offline caching, QR scanner, camera, Shorebird OTA, Play Store)

## Critical Rules
- NO placeholder implementations — every screen must be fully functional
- NO fake APIs — all data comes from real `/api/*` endpoints
- NO incomplete flows — every user journey must work end-to-end
- Reusable widgets for common patterns (search bars, skeleton loaders, error states, empty states)
- Every list must support pagination with infinite scroll
- All forms must validate and show loading + error states
