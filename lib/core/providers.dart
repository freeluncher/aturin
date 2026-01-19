import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/project_repository.dart';
import '../../data/repositories/project_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/vault_repository.dart'; // Added
import '../../data/repositories/vault_repository_impl.dart'; // Added
import '../../data/local/app_database.dart';
import '../data/services/sync_service.dart';
import 'supabase_config.dart';

// Database Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Supabase Client Provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseConfig.client;
});

// Project Repository Provider
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final supabase = ref.watch(supabaseClientProvider);
  return ProjectRepositoryImpl(db, supabase);
});

// Sync Service Provider
final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final supabase = ref.watch(supabaseClientProvider);
  return SyncService(db, supabase);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AuthRepositoryImpl(supabase);
});

final vaultRepositoryProvider = Provider<VaultRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return VaultRepositoryImpl(db);
});

// Task Stream Provider
final allTasksStreamProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(projectRepositoryProvider).getAllTasks();
});

// Projects Stream Provider
final projectsStreamProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(projectRepositoryProvider).getProjects();
});

// Connectivity Stream Provider
// Emits true if online, false if offline
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    return !results.contains(ConnectivityResult.none);
  });
});
