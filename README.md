# School Management Mobile App — Overview & Deployment Pack

_Generated 2026-05-26 from a full sweep of the codebase, pubspec, AndroidManifest, router and backend folder structure. Numbers below are exact, not estimates._

---

## 1. Quick answers to your scoping questions

### How many screens / modules?

**77 screen files** wired through **87 GoRouter routes**, grouped into 7 role portals:

| Portal | Screen files | Notes |
|---|---|---|
| **Admin** (Admin / Clerk / Super Admin / Teacher reuses same shell) | **50** | The largest portal: dashboard, students, fees collection + history, fee masters (types, structures, late fee, concessions), classes, sections, academic years, masters, attendance (mark, my attendance, staff attendance, leave requests), timetable, exams (mark entry, report cards), calendar, certificates, ID cards, transport (routes, assignments, rebates), gate (passes, visitors, entry/exit log), reception (call log, appointments, late arrivals), notifications (send + log), DigiLocker, reports, users, settings, face enrolment + scan, approvals. |
| **Teacher** | **4** | Re-uses admin screens (mark attendance, mark entry, report cards) plus its own dashboard, exams hub, leave-request screen, more. |
| **Driver** | **4** | Dashboard, Route, Trip (live GPS tracking), More. |
| **Security guard** | **7** | Dashboard, Visitors, Register Visitor, Entry/Exit log, Log Entry/Exit (with QR scan), Gate Passes, More. |
| **Parent** | **9** | Dashboard, Fees (3-card layout + Razorpay), Receipts, Attendance, Bus (live GPS map), Calendar, Timetable, Profile, More. |
| **Auth** | **2** | Login, Change-password (forced on first login). |
| **Profile (shared)** | **1** | Generic profile screen used by some shells. |

Total **205 backend API endpoints** under `/api/admin`, `/api/teacher`, `/api/driver`, `/api/security`, `/api/parent`, `/api/student`, `/api/clerk`, `/api/reception`, `/api/payment`, `/api/receipts`, `/api/auth`, `/api/public`, `/api/portal`, `/api/web-admin`, `/api/mobile`, plus `/api/icon`, `/api/logo`, `/api/health`.

### Is the backend stable / production-ready?

**Yes — production.** The mobile app talks directly to `https://<flavor>.in/api/*` on the live backend (Next.js on Cloudflare). Endpoints are NextAuth-protected (cookie session). Every portal has been smoke-tested against the live API during this build.

Recent backend additions made during mobile development:
- `/api/parent/attendance` + `/api/parent/transport` (with `activeTripId` for live GPS).
- `/api/parent/children/:id/matrix` filtering refined to match the admin fee-collection screen.
- `/api/security/profile` opened up to PATCH `{image}`.
- `/api/auth/change-password` + `mustChangePassword` flag on the session.
- Calendar endpoint extended to scope events by `sectionId`.

### Hardware / device integrations

| Integration | Purpose | Package |
|---|---|---|
| **GPS / foreground location** | Driver continuously streams bus location during a trip; parent watches it live on a map. | `geolocator`, `flutter_foreground_task`, `permission_handler` |
| **Camera** | QR scanning (gate-pass scan, student attendance QR), photo capture for visitor registration / profile photos. | `camera`, `mobile_scanner`, `image_picker` |
| **Face detection (on-device ML)** | Admin face-enrolment + face-attendance scan. | `tflite_flutter`, `google_mlkit_face_detection` |
| **Local storage (SQLite)** | Offline caches. | `sqflite` |
| **Secure storage** | NextAuth session cookie persistence. | `flutter_secure_storage` |
| **PDF generation + print + share** | Fee receipts, ID cards, certificates. | `pdf`, `printing`, `share_plus` |
| **Local notifications** | Reminders, in-app banners. | `flutter_local_notifications` |
| **Connectivity awareness** | Offline banner + reconnect retries. | `connectivity_plus` |
| **OTG / USB thermal printer** | Already declared in manifest (`usb_device_filter`). | Built-in Android USB intents |

### How are the 5 flavors different?

It's **white-label only.** Same codebase, same screens, same flows. Each flavor differs only by:

| Flavor | Display name | API base URL | Brand colour | Package ID |
|---|---|---|---|---|
| `jmukhisics` | JMukhisics | `https://jmukhisics.in` | `#1e40af` (blue) | `in.jmukhisics.mobile_app` |
| `sicschool` | SIC School | `https://sicschool.in` | `#166534` (green) | `in.sicschool.mobile_app` |
| `schoolfeepro` | School Fee Pro | `https://schoolfeepro.in` | `#7c3aed` (purple) | `in.schoolfeepro.mobile_app` |
| `theshivalik` | The Shivalik | `https://theshivalik.in` | `#EF4444` (red) | `in.theshivalik.mobile_app` |
| `shivaliksmartkids` | Shivalik Smart Kids | `https://shivaliksmartkids.in` | `#2563EB` (blue) | `in.shivaliksmartkids.mobile_app` |

Each has its own:
- Launcher icon set (`android/app/src/<flavor>/res/mipmap-*`)
- Signing keystore (`android/keystores/<flavor>.jks`) — **all 5 generated and in place**
- App-name resource (`resValue("string", "app_name", "...")` in `build.gradle.kts`)
- Backend Cloudinary / Razorpay / Firebase credentials (server-side per `schoolId`)

**Same app, 5 storefront listings.** Flows and features are 100% identical across flavors. Switching flavor is purely the `flutter run --flavor X -t lib/main_X.dart` choice.

### Payment gateway integration?

**Yes — Razorpay**, fully wired in the parent + admin flows.
- Dependency: `razorpay_flutter: ^1.4.3`.
- Backend endpoints already live: `POST /api/payment/create-order`, `POST /api/payment/verify`, `POST /api/payment/webhook`.
- Parent fees screen opens the Razorpay native checkout with the school's brand color, verifies signature, and writes the FeeCollection via webhook.
- Razorpay keys are stored server-side per school (`getRazorpayCredentials(schoolId)`).

### Firebase Push Notifications

**Not yet integrated.** The codebase has `firebase_core` and `firebase_database` (used for driver→parent live GPS via Realtime DB) but **`firebase_messaging` is NOT in the pubspec.**

For push notifications you'll need to add — one-time work, ~half a day:
1. `firebase_messaging` dependency.
2. `flutterfire configure` per flavor → produces `google-services.json` and per-flavor `firebase_options_<flavor>.dart`.
3. iOS APNs auth key uploaded to each Firebase project.
4. A Notifications service screen + token registration call to a new backend endpoint `/api/mobile/push-tokens`.

(Local notifications via `flutter_local_notifications` already work — it's the cloud-push fan-out that's pending.)

### Third-party SDKs / services

**Currently installed (from `pubspec.yaml`):**

```
flutter_riverpod, riverpod_annotation       — state management
go_router                                   — navigation
dio, dio_cookie_manager, cookie_jar         — HTTP + NextAuth cookies
flutter_secure_storage                      — session persistence
flutter_svg, cached_network_image           — assets
intl, url_launcher, cupertino_icons         — utilities

mobile_scanner                              — QR scanning
image_picker, camera, image                 — photos
tflite_flutter, google_mlkit_face_detection — on-device face ML

pdf, printing, share_plus                   — receipt / ID-card generation
flutter_local_notifications                 — local notifications
connectivity_plus                           — offline detection
sqflite                                     — local DB

razorpay_flutter                            — payment gateway
geolocator, permission_handler              — GPS
flutter_foreground_task                     — sticky bus-tracking service
firebase_core, firebase_database            — live bus location fan-out
google_maps_flutter                         — map UI for live tracking
path_provider, uuid, path                   — helpers
```

**External services already in production use (backend-side):**
- **Cloudinary** — all photo / PDF uploads.
- **Razorpay** — online fee collection.
- **Firebase Realtime DB** — live bus GPS.
- **NextAuth** — cookie-based session auth.

### Permissions / background services

From [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml):

```
INTERNET, ACCESS_NETWORK_STATE
ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION, ACCESS_BACKGROUND_LOCATION
FOREGROUND_SERVICE, FOREGROUND_SERVICE_LOCATION
POST_NOTIFICATIONS                ← Android 13+
WAKE_LOCK
```

Background services:
- **`flutter_foreground_task` ForegroundService** — registered with `foregroundServiceType="location"` for the driver bus-tracking flow. Sticky notification "Bus tracking active" while a trip is IN_PROGRESS.

For iOS we'll need to add Info.plist entries during App Store submission:
- `NSLocationAlwaysAndWhenInUseUsageDescription` (driver tracking)
- `NSCameraUsageDescription` (QR / visitor photos)
- `NSPhotoLibraryUsageDescription` (image picker)
- `UIBackgroundModes` → `location` (driver flow)

### Store assets readiness

| Asset | State |
|---|---|
| **Launcher icons (Android)** | ✅ Generated per flavor in `android/app/src/<flavor>/res/mipmap-*`. `create_icons.py` and `create_featured_images.py` are in [extras/](extras/) for re-generation. |
| **iOS App Icon** | ⚠ Default Flutter `Assets.xcassets/AppIcon.appiconset` exists. Need to swap in per-flavor 1024×1024 marketing icons. |
| **Splash / launch image** | ⚠ iOS uses default `LaunchImage.imageset` — needs branded splash per flavor. |
| **Feature graphics / screenshots** | ⚠ `extras/featured_images/` folder exists but is per-flavor and needs verification — likely incomplete for 5 flavors. |
| **Privacy policy** | ⚠ Not in repo. Each flavor will need a hosted privacy policy URL (`https://<flavor>.in/privacy`) referenced in store listing. |
| **Store descriptions (short + full)** | ⚠ Not drafted. |
| **APKs ready for Play Store** | ✅ All 5 flavors built and signed: `build/app/outputs/flutter-apk/app-<flavor>-release.apk`. Replace with `flutter build appbundle` for Play Store (AAB is mandatory for new releases). |
| **iOS archive (.ipa)** | ❌ Not yet built — needs first run from a Mac with Xcode, Apple Developer account, App Store Connect entries, signing certificate, and provisioning profile per flavor. |

### Deployment cost approval (₹8,000 one-time)

That covers, per your spec:
- Android Play Store deployment for all 5 flavors (Play Console internal-track upload → review → production).
- iOS App Store / TestFlight: Apple Developer account is yours; you'll create the Apple ID for each flavor in App Store Connect, then we generate the certificate + provisioning profile per app bundle ID and submit via Xcode/Transporter to TestFlight.
- Certificates, provisioning profiles, archive (.ipa), TestFlight + App Store submission for each of the 5 flavors.

Recommend keeping the cost as a single line item even though we now have 5 flavors (not 4) — the extra `shivaliksmartkids` flavor is mechanically identical work.

---

## 2. App Flow Documentation

### 2.1 Architecture (clean-architecture, feature-first)

```
lib/
├── app.dart                    Root MaterialApp.router + Firebase init (graceful no-op)
├── app_config.dart             AppConfig (InheritedWidget) — flavor, baseUrl, brand color
├── main.dart                   Default entry (used by IDE Run)
├── main_jmukhisics.dart        Per-flavor entry points (5 total)
├── main_sicschool.dart
├── main_schoolfeepro.dart
├── main_theshivalik.dart
├── main_shivaliksmartkids.dart
├── core/
│   ├── network/dio_client.dart       Dio + cookie jar + 401 interceptor
│   ├── storage/secure_storage.dart   Session + role persistence
│   ├── theme/app_theme.dart          Material 3, brand-blue AppBar + nav
│   └── connectivity/                  Offline banner
├── router/
│   └── app_router.dart                go_router with 87 routes + role guards
└── features/
    ├── auth/         login + force-password-change + provider
    ├── admin/        50 admin screens + repos + providers
    ├── teacher/      teacher dashboard + exams hub (re-uses admin code)
    ├── driver/       4 screens + GPS foreground service
    ├── security/     7 screens
    ├── parent/       9 screens
    └── profile/      shared profile screen
```

State management: **Riverpod** (`StateNotifierProvider` for complex flows, `FutureProvider.autoDispose` for fetches).

### 2.2 Authentication flow

```
launch
  ↓
SecureStorage check → /api/auth/session
  ├─ no cookie   →  /login screen
  │                  ↓
  │            POST /api/auth/csrf
  │            POST /api/auth/callback/credentials   (NextAuth)
  │            GET  /api/auth/session                (read role + flags)
  │                  ↓
  └─ ok        →  router redirect:
                  ├─ mustChangePassword=true        →  /change-password (forced)
                  ├─ role = SUPER_ADMIN/ADMIN/CLERK →  /admin/dashboard
                  ├─ role = TEACHER                 →  /teacher/dashboard
                  ├─ role = DRIVER                  →  /driver/dashboard
                  ├─ role = SECURITY_GUARD          →  /security/dashboard
                  └─ role = PARENT                  →  /parent/dashboard

session expiry → 401 interceptor → logout → /login
```

### 2.3 Role-portal feature matrices

#### Admin / Clerk / Super Admin (`AdminShell` — 5 bottom tabs)

| Tab | Routes & key screens |
|---|---|
| **Dashboard** | `/admin/dashboard` — stats, quick actions |
| **Students** | `/admin/students` list, `/admin/students/:id` detail, my-class students |
| **Fees** | `/admin/fee-collection` (matrix + Razorpay-or-cash collection), `/admin/fee-collection/history`, masters: types / structures / concessions / late-fee |
| **More** | reports, users, masters, classes, academic-years, calendar, timetable, certificates, ID cards, transport (routes/assignments/rebates), gate (passes/visitors/entry-exit log), reception (calls/appointments/late arrivals), notifications, DigiLocker, settings, attendance (mark/staff/student), exams (mark entry/report cards), approvals, face enrolment + scan |

#### Teacher (`TeacherShell` — 5 bottom tabs)

| Tab | Routes |
|---|---|
| **Dashboard** | `/teacher/dashboard` |
| **Timetable** | `/teacher/timetable` (read-only) |
| **Attendance** | `/teacher/attendance` + QR scan flow → bulk submit |
| **Exams** | `/teacher/exams` → mark entry + report cards (re-uses admin screens with scope guard) |
| **Calendar** | `/teacher/calendar` |
| **More / Profile** | `/teacher/more`, `/teacher/profile`, `/teacher/leaves`, `/teacher/my-attendance` |

Teachers are locked to their `assignedClassId` / `assignedSectionId` (server-enforced + client-prefilled).

#### Driver (`DriverShell` — 4 bottom tabs)

| Tab | Flow |
|---|---|
| **Dashboard** | Today's trips (Morning / Evening), route summary, active-trip resume |
| **Route** | Read-only stoppages + assigned students per stoppage |
| **Trip** | Active trip only — live GPS card (foreground service), stoppage-by-stoppage attendance (Present / Absent / Not Boarded), Complete Trip button |
| **More** | Profile, change password, photo upload, logout |

GPS pipeline: driver app → Firebase Realtime DB `buses/{tripId}` (every ~5s) → parent live map. Also POSTs every 30s to `/api/driver/location` for permanent history.

#### Security Guard (`SecurityShell` — 4 bottom tabs)

| Tab | Flow |
|---|---|
| **Dashboard** | Today's counters (visitors / entries / exits), active gate-passes, quick actions, recent activity |
| **Visitors** | List + register-visitor form (with photo) + check-out |
| **Entry/Exit** | Filter chips by person type, log form with optional QR-pass scan |
| **More** | Gate passes (mark used / log exit), change password / photo, logout |

#### Parent (`ParentShell` — 5 bottom tabs)

Persistent **child selector** at top of Dashboard / Fees / Receipts / Attendance / Bus / Calendar / Timetable when parent has multiple children.

| Tab | Flow |
|---|---|
| **Home** | Greeting, child selector, stats (outstanding / receipts / events), upcoming events, profile icon in app bar |
| **Fees** | Year dropdown + 3 cards: **One-Time Fees** (checkbox + Pay button), **Annual Fees** (checkbox + Pay button), **Monthly Tuition + Transport** (tap a month to Pay). All open Razorpay checkout. |
| **Attendance** | Month switcher, summary %, calendar grid (color-coded: present / absent / late / leave / holiday), day list |
| **Bus** | Live tracking card with Google Map subscribing to Firebase `buses/{activeTripId}`; pulsing dot + speed when fresh; route + stoppage timeline (parent's stoppage highlighted); driver/conductor tap-to-call |
| **More** | Receipts, Calendar, Timetable, Profile, About, Logout |

### 2.4 Razorpay payment flow (parent / student / admin)

```
user selects fee lines
  ↓
POST /api/payment/create-order
        body: { studentId, academicYearId, items: [SelectedFeeLine...] }
        returns: { orderId, amount, currency, paymentId, key }
  ↓
Razorpay native checkout opens (brand-colored)
  ↓
on success → POST /api/payment/verify
            body: { paymentId, razorpay_order_id, razorpay_payment_id, razorpay_signature }
  ↓
backend webhook (POST /api/payment/webhook) writes FeeCollection rows
  ↓
mobile invalidates feeMatrixProvider + receiptsProvider → refreshed UI
```

### 2.5 Live GPS pipeline

```
DRIVER PHONE                                  PARENT PHONE
─────────────────                             ─────────────────
flutter_foreground_task                       Google Map widget
        ↓                                              ↑
geolocator stream (5s)                          StreamProvider
        ↓                                              ↑
       ┌────────────────────────────────────────────┐
       │ Firebase Realtime DB: buses/{tripId}       │
       │   { lat, lng, speed, heading, ts }         │
       └────────────────────────────────────────────┘
        ↓ (every 30s)
POST /api/driver/location  →  permanent history (Postgres)
```

### 2.6 Build & deployment commands

```bash
# Per-flavor run (dev)
flutter run -d <device> -t lib/main_<flavor>.dart --flavor <flavor>

# Release APK
flutter build apk --release --flavor <flavor> -t lib/main_<flavor>.dart

# Release AAB for Play Store
flutter build appbundle --release --flavor <flavor> -t lib/main_<flavor>.dart

# iOS (from Mac)
flutter build ipa --release --flavor <flavor> -t lib/main_<flavor>.dart \
  --export-options-plist ios/ExportOptions-<flavor>.plist
```

Outputs land in:
- `build/app/outputs/flutter-apk/app-<flavor>-release.apk`
- `build/app/outputs/bundle/<flavor>Release/app-<flavor>-release.aab`
- `build/ios/ipa/<flavor>.ipa`

### 2.7 Known gaps before Play / App Store submission

1. **iOS not yet built once on a Mac.** Need first-time signing setup per bundle ID in Apple Developer + App Store Connect.
2. **`firebase_messaging` not added** — push notifications pending if required for v1.
3. **Privacy policy URL per flavor** — hosted privacy policy URL is mandatory for Play Console & App Store.
4. **iOS Info.plist usage descriptions** — need to add `NSLocationAlways*`, `NSCamera*`, `NSPhotoLibrary*`, `UIBackgroundModes`.
5. **Store screenshots & feature graphics** — needed at submission time. `extras/featured_images/` has some assets.
6. **Google Maps API key** — Android manifest has placeholder `YOUR_GOOGLE_MAPS_API_KEY`; need a real key, restricted to each flavor's package ID + SHA-1. For iOS, set in `AppDelegate.swift`.
7. **Per-flavor Firebase project** — driver/parent live GPS already works in dev; production needs verified `google-services.json` per flavor for Android + `GoogleService-Info.plist` per flavor for iOS.

---

## 3. Suggested deployment sequence

1. **Internal track (Play Console)** — upload `app-<flavor>-release.aab` for one flavor, verify signed-in flow with internal testers, then repeat for the remaining 4.
2. **TestFlight** — once Xcode signing is set up for one bundle ID, the remaining 4 are template duplicates.
3. **Privacy policy + store listings drafted in parallel** — same text per flavor, swap school name.
4. **Production rollout** — Play Store 7-day staged 10% → 50% → 100%; App Store full release once Apple review passes.

End of document.
