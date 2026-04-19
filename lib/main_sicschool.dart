import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/app.dart';
import 'package:mobile_app/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const config = AppConfig(
    flavor: 'sicschool',
    appName: 'SIC School',
    baseUrl: 'https://sicschool.in',
    primaryColor: Color(0xFF166534),
    logoUrl: 'https://sicschool.in/api/logo',
  );

  final container = await buildContainer(config);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const App(config: config),
    ),
  );
}
