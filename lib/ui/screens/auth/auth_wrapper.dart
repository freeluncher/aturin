import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers.dart';
import '../dashboard/dashboard_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize Sync Service Listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
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
