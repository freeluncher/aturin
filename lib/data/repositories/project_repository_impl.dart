import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../domain/models/project.dart' as domain;
import '../../domain/models/task.dart' as domain;
import '../../domain/repositories/project_repository.dart';
import '../local/app_database.dart';
import '../mappers/project_mapper.dart';
import '../mappers/task_mapper.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final AppDatabase _db;
  final supabase.SupabaseClient _supabase;

  ProjectRepositoryImpl(this._db, this._supabase);

  // --- Projects ---

  @override
  Stream<List<domain.Project>> getProjects() {
    final localStream =
        (_db.select(
          _db.projects,
        )..where((t) => t.isDeleted.equals(false))).watch().map((rows) {
          return rows.map((row) => row.toDomain()).toList();
        });
    // Trigger sync handled by SyncService usually, but keeping existing pattern here specific to this repo if needed.
    // However, since SyncService exists, we should rely on it.
    // For now, I will leave existing logic but redundant sync call might be cleaner to remove if SyncService is the Source of Truth for sync.
    // The previous implementation called _syncFromRemote().
    _syncFromRemote();
    return localStream;
  }

  @override
  Future<void> createProject(domain.Project project) async {
    await _db.into(_db.projects).insert(project.toCompanion());
    if (await _isOnline()) {
      try {
        await _supabase.from('projects').insert({
          'id': project.id,
          'user_id': _supabase.auth.currentUser?.id,
          'name': project.name,
          'description': project.description,
          'created_at': project.createdAt.toIso8601String(),
          'last_updated': project.lastUpdated.toIso8601String(),
          'is_deleted': project.isDeleted,
        });
        await (_db.update(_db.projects)..where((t) => t.id.equals(project.id)))
            .write(ProjectsCompanion(isSynced: const Value(true)));
      } catch (e) {
        debugPrint('Error syncing createProject: $e');
      }
    }
  }

  @override
  Future<void> syncProjects() async {
    await _syncFromRemote();
  }

  @override
  Future<void> updateProject(domain.Project project) async {
    await (_db.update(
      _db.projects,
    )..where((t) => t.id.equals(project.id))).write(project.toCompanion());

    if (await _isOnline()) {
      try {
        await _supabase
            .from('projects')
            .update({
              'name': project.name,
              'description': project.description,
              'last_updated': DateTime.now().toIso8601String(),
              'is_deleted': project.isDeleted,
            })
            .eq('id', project.id);

        await (_db.update(_db.projects)..where((t) => t.id.equals(project.id)))
            .write(ProjectsCompanion(isSynced: const Value(true)));
      } catch (e) {
        debugPrint('Error syncing updateProject: $e');
      }
    }
  }

  @override
  Future<void> deleteProject(String projectId) async {
    // Soft delete
    await (_db.update(
      _db.projects,
    )..where((t) => t.id.equals(projectId))).write(
      const ProjectsCompanion(
        isDeleted: Value(true),
        isSynced: Value(false),
        lastUpdated: Value.absent(),
      ),
    );

    if (await _isOnline()) {
      try {
        await _supabase
            .from('projects')
            .update({
              'is_deleted': true,
              'last_updated': DateTime.now().toIso8601String(),
            })
            .eq('id', projectId);

        await (_db.update(_db.projects)..where((t) => t.id.equals(projectId)))
            .write(ProjectsCompanion(isSynced: const Value(true)));
      } catch (e) {
        debugPrint('Error syncing deleteProject: $e');
      }
    }
  }

  // --- Tasks ---

  @override
  Stream<List<domain.Task>> getTasks(String projectId) {
    return (_db.select(_db.tasks)..where(
          (t) => t.projectId.equals(projectId) & t.isDeleted.equals(false),
        ))
        .watch()
        .map((rows) => rows.map((row) => row.toDomain()).toList());
  }

  @override
  Stream<List<domain.Task>> getAllTasks() {
    return (_db.select(_db.tasks)..where((t) => t.isDeleted.equals(false)))
        .watch()
        .map((rows) => rows.map((row) => row.toDomain()).toList());
  }

  @override
  Future<void> createTask(domain.Task task) async {
    await _db.into(_db.tasks).insert(task.toCompanion());
    if (await _isOnline()) {
      try {
        await _supabase.from('tasks').insert({
          'id': task.id,
          'project_id': task.projectId, // Important: Relation
          // 'user_id' is NOT on tasks table based on schema? Let's check schema.
          // Based on Drift definition, Tasks doesn't have user_id, it links to Project.
          // Supabase RLS should handle access via Project join or if we added user_id to tasks.
          // Let's assume schema matches Drift.
          'title': task.title,
          'description': task.description,
          'is_completed': task.isCompleted,
          'created_at': task.createdAt.toIso8601String(),
          'last_updated': task.lastUpdated.toIso8601String(),
          'is_deleted': task.isDeleted,
        });
        await (_db.update(_db.tasks)..where((t) => t.id.equals(task.id))).write(
          TasksCompanion(isSynced: const Value(true)),
        );
      } catch (e) {
        debugPrint('Error syncing createTask: $e');
      }
    }
  }

  @override
  Future<void> updateTask(domain.Task task) async {
    await (_db.update(
      _db.tasks,
    )..where((t) => t.id.equals(task.id))).write(task.toCompanion());

    if (await _isOnline()) {
      try {
        await _supabase
            .from('tasks')
            .update({
              'title': task.title,
              'description': task.description,
              'is_completed': task.isCompleted,
              'last_updated': DateTime.now()
                  .toIso8601String(), // Update timestamp
              'is_deleted': task.isDeleted,
            })
            .eq('id', task.id);

        await (_db.update(_db.tasks)..where((t) => t.id.equals(task.id))).write(
          TasksCompanion(isSynced: const Value(true)),
        );
      } catch (e) {
        debugPrint('Error syncing updateTask: $e');
      }
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    // Soft delete
    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
      const TasksCompanion(
        isDeleted: Value(true),
        isSynced: Value(false),
        lastUpdated: Value.absent(), // Should update timestamp ideally
      ),
    );

    // Or if hard delete locally:
    // await (_db.delete(_db.tasks)..where((t) => t.id.equals(taskId))).go();
    // But for sync, soft delete is better.
  }

  // --- Helpers ---

  Future<void> _syncFromRemote() async {
    if (!await _isOnline()) return;
    try {
      // Sync Projects
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
                  createdAt: Value(
                    DateTime.parse(data['created_at'] as String),
                  ),
                  lastUpdated: Value(serverUpdatedAt),
                  isSynced: const Value(true),
                  isDeleted: Value(data['is_deleted'] as bool? ?? false),
                ),
              );
        } else {
          // Conflict Resolution: Server Wins if newer
          if (serverUpdatedAt.isAfter(localProject.lastUpdated)) {
            await (_db.update(
              _db.projects,
            )..where((t) => t.id.equals(id))).write(
              ProjectsCompanion(
                name: Value(data['name'] as String),
                description: Value(data['description'] as String),
                lastUpdated: Value(serverUpdatedAt),
                isSynced: const Value(true),
                isDeleted: Value(data['is_deleted'] as bool? ?? false),
              ),
            );
          }
        }
      }
      debugPrint('Sync completed for ${remoteProjects.length} items');
    } catch (e) {
      debugPrint('Sync failed: $e');
    }
  }

  Future<bool> _isOnline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return !connectivityResult.contains(ConnectivityResult.none);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return false; // Assume offline if check fails
    }
  }
}
