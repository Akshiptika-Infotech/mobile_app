import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/auth/providers/auth_provider.dart';

/// Observes app lifecycle changes and proactively validates the auth session
/// whenever the app resumes from background.
///
/// Place this widget near the root of the widget tree (e.g. inside [App]'s
/// builder or as a child of [MaterialApp.router]):
///
/// ```dart
/// SessionLifecycleObserver(child: MyAppContent())
/// ```
class SessionLifecycleObserver extends ConsumerStatefulWidget {
  const SessionLifecycleObserver({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SessionLifecycleObserver> createState() =>
      _SessionLifecycleObserverState();
}

class _SessionLifecycleObserverState
    extends ConsumerState<SessionLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came to foreground → validate session before user interacts.
      ref.read(authProvider.notifier).validateSession();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
