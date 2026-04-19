import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/app.dart';
import 'package:mobile_app/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const config = AppConfig(
    flavor: 'schoolfeepro',
    appName: 'School Fee Pro',
    baseUrl: 'https://schoolfeepro.in',
    primaryColor: Color(0xFF7c3aed),
    logoUrl: 'https://schoolfeepro.in/api/logo',
  );

  final container = await buildContainer(config);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const App(config: config),
    ),
  );
}
