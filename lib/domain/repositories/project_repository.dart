import '../models/project.dart';

abstract class ProjectRepository {
  Future<List<Project>> getProjects();
  Future<void> createProject(Project project);
}
