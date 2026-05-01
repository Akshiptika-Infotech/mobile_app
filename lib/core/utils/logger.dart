import 'package:flutter/foundation.dart';

/// Lightweight structured logger for the mobile app.
///
/// In debug builds every message is printed to the console.
/// In release builds only [error] and [warn] are surfaced.
///
/// Future: integrate with Firebase Crashlytics by replacing
/// [error] with `FirebaseCrashlytics.instance.recordError`.
class Logger {
  Logger._();
  static final Logger _instance = Logger._();
  static Logger get instance => _instance;

  static const String _prefix = '[MobileApp]';

  void info(String message, {Map<String, dynamic>? context}) {
    if (kDebugMode) {
      _log('INFO', message, context);
    }
  }

  void warn(String message, {Map<String, dynamic>? context}) {
    _log('WARN', message, context);
  }

  void error(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? context}) {
    _log('ERROR', message, {
      ...?context,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    });
  }

  void _log(String level, String message, Map<String, dynamic>? context) {
    final timestamp = DateTime.now().toIso8601String();
    final ctx = context != null && context.isNotEmpty ? ' | ${context.toString()}' : '';
    // ignore: avoid_print
    print('$_prefix [$timestamp] [$level] $message$ctx');
  }
}
