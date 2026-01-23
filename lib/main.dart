import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/supabase_config.dart';
import 'ui/screens/auth/auth_wrapper.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'core/providers/dashboard_config_provider.dart';

void main() async {
  // Ensure widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (loads .env internally)
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint("Warning: Supabase initialization failed: $e");
  }

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MainApp(),
    ),
  );
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
