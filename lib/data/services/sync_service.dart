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
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return !connectivityResult.contains(ConnectivityResult.none);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return false; // Assume offline if check fails
    }
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

      // 2. Sync Tasks
      final unsyncedTasks = await (_db.select(
        _db.tasks,
      )..where((t) => t.isSynced.equals(false))).get();

      for (var task in unsyncedTasks) {
        await _syncUpTask(task);
      }

      // 3. Sync Vault Up
      final unsyncedVault = await (_db.select(
        _db.vaultItems,
      )..where((t) => t.isSynced.equals(false))).get();

      for (var item in unsyncedVault) {
        await _syncUpVault(item);
      }

      debugPrint('SyncUp completed');
    } catch (e) {
      debugPrint('SyncUp failed: $e');
    }
  }

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Initializes connectivity listener for auto-sync
  Future<void> initialize() async {
    // Feature Check: Try to just check connectivity once.
    // If this fails, the platform implementation is likely broken or permissions are missing.
    try {
      await Connectivity().checkConnectivity();
    } catch (e) {
      debugPrint('Connectivity plugin check failed (skipping auto-sync): $e');
      return;
    }

    try {
      _subscription = Connectivity().onConnectivityChanged.listen(
        (results) {
          if (!results.contains(ConnectivityResult.none)) {
            debugPrint('Connection restored. Triggering Auto-Sync...');
            syncUp().then((_) => syncDown());
          }
        },
        onError: (e) {
          debugPrint('Connectivity Stream Error: $e');
        },
      );
    } catch (e) {
      debugPrint('Failed to subscribe to connectivity updates: $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
  }

  /// Pulls remote changes to local
  Future<void> syncDown() async {
    if (!await isOnline) return;

    try {
      // 1. Sync Projects Down
      await _syncDownProjects();

      // 2. Sync Tasks Down
      await _syncDownTasks();

      // 3. Sync Vault Down
      await _syncDownVault();

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
        'deadline': project.deadline?.toIso8601String(),
        'is_deleted': project.isDeleted,
      };

      await _supabase.from('projects').upsert(data);

      await (_db.update(_db.projects)..where((t) => t.id.equals(project.id)))
          .write(ProjectsCompanion(isSynced: const Value(true)));
    } catch (e) {
      debugPrint('Failed to sync up project ${project.id}: $e');
    }
  }

  Future<void> _syncDownProjects() async {
    final response = await _supabase.from('projects').select();
    final remoteProjects = response as List<dynamic>;

    for (var data in remoteProjects) {
      final id = data['id'] as String;
      final serverUpdatedAt = DateTime.parse(data['last_updated'] as String);

      final localProject = await (_db.select(
        _db.projects,
      )..where((t) => t.id.equals(id))).getSingleOrNull();

      if (localProject == null) {
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
                deadline: Value(
                  data['deadline'] != null
                      ? DateTime.parse(data['deadline'] as String)
                      : null,
                ),
                isSynced: const Value(true),
                isDeleted: Value(data['is_deleted'] as bool? ?? false),
              ),
            );
      } else {
        if (serverUpdatedAt.isAfter(localProject.lastUpdated)) {
          await (_db.update(_db.projects)..where((t) => t.id.equals(id))).write(
            ProjectsCompanion(
              name: Value(data['name'] as String),
              description: Value(data['description'] as String),
              lastUpdated: Value(serverUpdatedAt),
              deadline: Value(
                data['deadline'] != null
                    ? DateTime.parse(data['deadline'] as String)
                    : null,
              ),
              isSynced: const Value(true),
              isDeleted: Value(data['is_deleted'] as bool? ?? false),
            ),
          );
        }
      }
    }
  }

  // --- Task Sync Logic ---

  Future<void> _syncUpTask(Task task) async {
    try {
      final data = {
        'id': task.id,
        'project_id': task.projectId,
        'title': task.title,
        'description': task.description,
        'is_completed': task.isCompleted,
        'created_at': task.createdAt.toIso8601String(),
        'last_updated': task.lastUpdated.toIso8601String(),
        'is_deleted': task.isDeleted,
      };

      await _supabase.from('tasks').upsert(data);

      await (_db.update(_db.tasks)..where((t) => t.id.equals(task.id))).write(
        TasksCompanion(isSynced: const Value(true)),
      );
    } catch (e) {
      debugPrint('Failed to sync up task ${task.id}: $e');
    }
  }

  Future<void> _syncDownTasks() async {
    final response = await _supabase.from('tasks').select();
    final remoteTasks = response as List<dynamic>;

    for (var data in remoteTasks) {
      final id = data['id'] as String;
      final projectId = data['project_id'] as String;
      final serverUpdatedAt = DateTime.parse(data['last_updated'] as String);

      // Verify project exists locally to satisfy FK
      final projectExists = await (_db.select(
        _db.projects,
      )..where((t) => t.id.equals(projectId))).getSingleOrNull();

      if (projectExists == null) {
        // Skip task if project doesn't exist locally yet
        // (Should be rare as we sync projects first, but robustness check)
        continue;
      }

      final localTask = await (_db.select(
        _db.tasks,
      )..where((t) => t.id.equals(id))).getSingleOrNull();

      if (localTask == null) {
        await _db
            .into(_db.tasks)
            .insert(
              TasksCompanion.insert(
                id: Value(id),
                serverId: Value(id),
                projectId: projectId,
                title: data['title'] as String,
                description: Value(data['description'] as String?),
                isCompleted: Value(data['is_completed'] as bool? ?? false),
                createdAt: Value(DateTime.parse(data['created_at'] as String)),
                lastUpdated: Value(serverUpdatedAt),
                isSynced: const Value(true),
                isDeleted: Value(data['is_deleted'] as bool? ?? false),
              ),
            );
      } else {
        if (serverUpdatedAt.isAfter(localTask.lastUpdated)) {
          await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
            TasksCompanion(
              title: Value(data['title'] as String),
              description: Value(data['description'] as String?),
              isCompleted: Value(data['is_completed'] as bool? ?? false),
              lastUpdated: Value(serverUpdatedAt),
              isSynced: const Value(true),
              isDeleted: Value(data['is_deleted'] as bool? ?? false),
            ),
          );
        }
      }
    }
  }
  // --- Vault Sync Logic ---

  Future<void> _syncUpVault(VaultItem item) async {
    try {
      if (item.isDeleted) {
        // HARD DELETE Strategy:
        // User requested permanent removal.
        // 1. Delete from Server
        await _supabase.from('vault_items').delete().eq('id', item.id);

        // 2. Delete from Local (Physical delete, no tombstone)
        await _db
            .delete(_db.vaultItems)
            .delete(VaultItemsCompanion(id: Value(item.id)));
      } else {
        // Standard Upsert
        final data = {
          'id': item.id,
          'user_id': _supabase.auth.currentUser?.id,
          'key': item.key,
          'value': item.value,
          'category': item.category,
          'project_id': item.projectId,
          'created_at': item.createdAt.toIso8601String(),
          'last_updated': item.lastUpdated.toIso8601String(),
          'is_deleted': false, // Ensure server knows it's active
        };

        await _supabase.from('vault_items').upsert(data);

        await (_db.update(_db.vaultItems)..where((t) => t.id.equals(item.id)))
            .write(VaultItemsCompanion(isSynced: const Value(true)));
      }
    } catch (e) {
      debugPrint('Failed to sync up vault item ${item.id}: $e');
    }
  }

  Future<void> _syncDownVault() async {
    try {
      final response = await _supabase.from('vault_items').select();
      final remoteItems = response as List<dynamic>;
      final remoteIds = <String>{};

      for (var data in remoteItems) {
        final id = data['id'] as String;
        remoteIds.add(id);

        // Use created_at as fallback if last_updated is null on server (old records)
        final serverCreatedAt = DateTime.parse(data['created_at'] as String);
        final serverUpdatedAt = data['last_updated'] != null
            ? DateTime.parse(data['last_updated'] as String)
            : serverCreatedAt;

        final localItem = await (_db.select(
          _db.vaultItems,
        )..where((t) => t.id.equals(id))).getSingleOrNull();

        if (localItem == null) {
          await _db
              .into(_db.vaultItems)
              .insert(
                VaultItemsCompanion.insert(
                  id: Value(id),
                  key: data['key'] as String,
                  value: data['value'] as String,
                  category: Value(data['category'] as String?),
                  projectId: Value(data['project_id'] as String?),
                  serverId: Value(id),
                  createdAt: Value(serverCreatedAt),
                  lastUpdated: Value(serverUpdatedAt),
                  isSynced: const Value(true),
                  isDeleted: const Value(false),
                ),
              );
        } else {
          // Conflict Resolution: Server Wins if Newer
          if (serverUpdatedAt.isAfter(localItem.lastUpdated)) {
            await (_db.update(
              _db.vaultItems,
            )..where((t) => t.id.equals(id))).write(
              VaultItemsCompanion(
                key: Value(data['key'] as String),
                value: Value(data['value'] as String),
                category: Value(data['category'] as String?),
                projectId: Value(data['project_id'] as String?),
                lastUpdated: Value(serverUpdatedAt),
                isSynced: const Value(true),
                isDeleted: const Value(false),
              ),
            );
          }
        }
      }

      // Hard Delete Propagation:
      // If a local item is marked as 'Synced' but is MISSING from server,
      // it means it was Hard Deleted on another device. We should delete it too.
      // We do NOT delete items that are !isSynced (pending push).
      final allLocalSynced = await (_db.select(
        _db.vaultItems,
      )..where((t) => t.isSynced.equals(true))).get();

      for (var local in allLocalSynced) {
        if (!remoteIds.contains(local.id)) {
          debugPrint('Deleting orphaned vault item: ${local.id}');
          await _db
              .delete(_db.vaultItems)
              .delete(VaultItemsCompanion(id: Value(local.id)));
        }
      }
    } catch (e) {
      debugPrint('SyncDown Vault failed: $e');
    }
  }
}
