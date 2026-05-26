import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/app.dart';
import 'package:mobile_app/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const config = AppConfig(
    flavor: 'shivaliksmartkids',
    appName: 'Shivalik Smart Kids',
    baseUrl: 'https://shivaliksmartkids.in',
    primaryColor: Color(0xFF2563EB),
    logoUrl: 'https://shivaliksmartkids.in/api/logo',
  );

  final container = await buildContainer(config);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const App(config: config),
    ),
  );
}
