import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/app_config.dart';
import 'package:mobile_app/core/connectivity/offline_banner.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/core/theme/app_theme.dart';
import 'package:mobile_app/features/auth/presentation/session_lifecycle_observer.dart';
import 'package:mobile_app/features/auth/providers/auth_provider.dart';
import 'package:mobile_app/router/app_router.dart';
import 'package:path_provider/path_provider.dart';

class App extends ConsumerWidget {
  const App({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return AppConfigScope(
      config: config,
      child: MaterialApp.router(
        title: config.appName,
        theme: AppTheme.light(config.primaryColor),
        darkTheme: AppTheme.dark(config.primaryColor),
        themeMode: ThemeMode.system,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        builder: (context, child) => SessionLifecycleObserver(
          child: Column(
            children: [
              const OfflineBanner(),
              Expanded(child: child ?? const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Returns a [ProviderContainer] pre-seeded with flavor-specific overrides.
///
/// Async because [getApplicationDocumentsDirectory] requires the Flutter
/// engine to be initialized before it can be called.
Future<ProviderContainer> buildContainer(AppConfig config) async {
  final appDir = await getApplicationDocumentsDirectory();
  await _initFirebaseSafely();
  late ProviderContainer container;
  final dio = buildDioClient(
    config,
    cookieDir: appDir.path,
    onUnauthorized: () async {
      await container.read(authProvider.notifier).logout();
    },
  );
  container = ProviderContainer(
    overrides: [
      dioClientProvider.overrideWithValue(dio),
    ],
  );
  return container;
}

/// Initialises Firebase using the platform defaults (Android reads
/// `google-services.json`, iOS reads `GoogleService-Info.plist`). The driver
/// portal uses Realtime Database for live bus tracking; when Firebase isn't
/// configured the location service degrades gracefully (history-only via
/// `POST /api/driver/location`).
Future<void> _initFirebaseSafely() async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Firebase isn't configured for this flavor yet — that's fine, the
    // app still works without live GPS fan-out.
    debugPrint('[buildContainer] Firebase init skipped: $e');
  }
}
