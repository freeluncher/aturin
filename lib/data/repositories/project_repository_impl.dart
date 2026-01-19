import '../../domain/models/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../local/app_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final AppDatabase _db;
  final SupabaseClient _supabase;

  ProjectRepositoryImpl(this._db, this._supabase);

  @override
  Future<List<Project>> getProjects() async {
    // TODO: Implement local + remote fetch logic
    return [];
  }

  @override
  Future<void> createProject(Project project) async {
    // TODO: Implement create logic
  }
}
