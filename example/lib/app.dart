import 'package:flutter/material.dart';

import 'package:simple_architecture/simple_architecture.dart';

import 'features/auth/domain/authenticated_user_changed_notification.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/home/presentation/home_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild when the currently authenticated user changes
    return MediatorNotificationListener<AuthenticatedUserChangedNotification>(
      // When there are no notifications emitted, build an empty widget
      // (this is optional and defaults to `SizedBox.shrink()`)
      waitingBuilder: (context) => const MaterialApp(
        home: Scaffold(),
      ),
      // The notification is avaible, so we'll render `LoginPage()` or
      // `HomePage()`, depending if user is null or not.
      builder: (context, notification) => MaterialApp(
        home: notification.user == null ? const LoginPage() : const HomePage(),
      ),
    );
  }
}
