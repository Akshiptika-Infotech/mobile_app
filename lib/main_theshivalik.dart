import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/app.dart';
import 'package:mobile_app/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const config = AppConfig(
    flavor: 'theshivalik',
    appName: 'The Shivalik',
    baseUrl: 'https://theshivalik.in',
    primaryColor: Color(0xFFEF4444),
    logoUrl: 'https://theshivalik.in/api/logo',
  );

  final container = await buildContainer(config);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const App(config: config),
    ),
  );
}
