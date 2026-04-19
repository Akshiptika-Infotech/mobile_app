import 'package:flutter/material.dart';

class AppConfig {
  final String flavor;
  final String appName;
  final String baseUrl;
  final Color primaryColor;
  /// Direct URL to the school logo (SVG or PNG).  Shown on the login screen
  /// without any API call so it works before the user authenticates.
  final String? logoUrl;

  const AppConfig({
    required this.flavor,
    required this.appName,
    required this.baseUrl,
    required this.primaryColor,
    this.logoUrl,
  });
}

/// InheritedWidget to provide AppConfig down the widget tree.
class AppConfigScope extends InheritedWidget {
  const AppConfigScope({
    super.key,
    required this.config,
    required super.child,
  });

  final AppConfig config;

  static AppConfig of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppConfigScope>();
    assert(scope != null, 'No AppConfigScope found in context');
    return scope!.config;
  }

  @override
  bool updateShouldNotify(AppConfigScope oldWidget) =>
      config != oldWidget.config;
}
