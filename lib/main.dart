import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/app.dart';
import 'package:mobile_app/app_config.dart';

// Default entry point — uses jmukhisics config for local development.
Future<void> main() async {
  const config = AppConfig(
    flavor: 'jmukhisics',
    appName: 'JMukhisics',
    baseUrl: 'https://jmukhisics.in',
    primaryColor: Color(0xFF1e40af),
    logoUrl: 'https://jmukhisics.in/logo.png',
  );

  final container = await buildContainer(config);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const App(config: config),
    ),
  );
}
