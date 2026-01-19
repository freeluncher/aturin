import '../models/project.dart';

abstract class ProjectRepository {
  /// Returns a stream of projects from the local database.
  /// It should also trigger a background sync with the remote server.
  Stream<List<Project>> getProjects();

  Future<void> createProject(Project project);

  Future<void> syncProjects();
}
