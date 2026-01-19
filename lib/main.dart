import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/supabase_config.dart';
import 'ui/screens/auth/auth_wrapper.dart';

void main() async {
  // Ensure widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (loads .env internally)
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint("Warning: Supabase initialization failed: $e");
    // We might want to allow running even if Supabase fails (offline mode),
    // but providers depending on SupabaseClient inside SupabaseConfig might be null logic wise if we don't catch it right.
    // Actually SupabaseConfig.initialize throws exception if keys missing.
  }

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Atur.in',
      theme: AppTheme.darkTheme,
      home: const AuthWrapper(),
    );
  }
}
