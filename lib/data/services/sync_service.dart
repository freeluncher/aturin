import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../local/app_database.dart';

class SyncService {
  final AppDatabase _db;
  final supabase.SupabaseClient _supabase;

  SyncService(this._db, this._supabase);

  /// Checks internet connection
  Future<bool> get isOnline async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  /// Pushes local changes to remote
  Future<void> syncUp() async {
    if (!await isOnline) return;

    try {
      // 1. Sync Projects
      final unsyncedProjects = await (_db.select(
        _db.projects,
      )..where((t) => t.isSynced.equals(false))).get();

      for (var project in unsyncedProjects) {
        await _syncUpProject(project);
      }

      // TODO: Add Sync Tasks here

      debugPrint('SyncUp completed');
    } catch (e) {
      debugPrint('SyncUp failed: $e');
    }
  }

  /// Pulls remote changes to local
  Future<void> syncDown() async {
    if (!await isOnline) return;

    try {
      // 1. Sync Projects Down
      await _syncDownProjects();

      // TODO: Add Sync Tasks Down here

      debugPrint('SyncDown completed');
    } catch (e) {
      debugPrint('SyncDown failed: $e');
    }
  }

  // --- Project Sync Logic ---

  Future<void> _syncUpProject(Project project) async {
    try {
      final data = {
        'id': project.id,
        'user_id': _supabase.auth.currentUser?.id,
        'name': project.name,
        'description': project.description,
        'created_at': project.createdAt.toIso8601String(),
        'last_updated': project.lastUpdated.toIso8601String(),
        'is_deleted': project.isDeleted,
      };

      // Upsert to Supabase
      await _supabase.from('projects').upsert(data);

      // Mark as synced locally
      await (_db.update(_db.projects)..where((t) => t.id.equals(project.id)))
          .write(ProjectsCompanion(isSynced: const Value(true)));
    } catch (e) {
      debugPrint('Failed to sync up project ${project.id}: $e');
    }
  }

  Future<void> _syncDownProjects() async {
    // Get latest local update time to limit fetch range (optimization)
    // For simplicity, we just fetch all or a large window for now,
    // or we could track a 'lastSyncTime' preference.

    final response = await _supabase.from('projects').select();
    final remoteProjects = response as List<dynamic>;

    for (var data in remoteProjects) {
      final id = data['id'] as String;
      final serverUpdatedAt = DateTime.parse(data['last_updated'] as String);

      final localProject = await (_db.select(
        _db.projects,
      )..where((t) => t.id.equals(id))).getSingleOrNull();

      if (localProject == null) {
        // Insert new from server
        await _db
            .into(_db.projects)
            .insert(
              ProjectsCompanion.insert(
                id: Value(id),
                serverId: Value(id),
                name: data['name'] as String,
                description: data['description'] as String,
                createdAt: Value(DateTime.parse(data['created_at'] as String)),
                lastUpdated: Value(serverUpdatedAt),
                isSynced: const Value(true),
                isDeleted: Value(data['is_deleted'] as bool? ?? false),
              ),
            );
      } else {
        // Conflict Resolution: Server Wins if newer
        if (serverUpdatedAt.isAfter(localProject.lastUpdated)) {
          await (_db.update(_db.projects)..where((t) => t.id.equals(id))).write(
            ProjectsCompanion(
              name: Value(data['name'] as String),
              description: Value(data['description'] as String),
              lastUpdated: Value(serverUpdatedAt),
              isSynced: const Value(true), // We are now in sync with server
              isDeleted: Value(data['is_deleted'] as bool? ?? false),
            ),
          );
        }
      }
    }
  }
}
