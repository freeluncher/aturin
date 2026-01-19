import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers.dart';
import '../dashboard_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStream = ref.watch(authRepositoryProvider).authStateChanges;

    return StreamBuilder<User?>(
      stream: authStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Check if we already have a current user synchronously to avoid flicker
          final currentUser = ref.read(authRepositoryProvider).currentUser;
          if (currentUser != null) {
            return const DashboardScreen();
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user != null) {
          return const DashboardScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
