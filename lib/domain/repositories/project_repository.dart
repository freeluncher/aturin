import '../models/project.dart';
import '../models/task.dart';

abstract class ProjectRepository {
  /// Returns a stream of projects from the local database.
  /// It should also trigger a background sync with the remote server.
  Stream<List<Project>> getProjects();

  Future<void> createProject(Project project);
  Future<void> updateProject(Project project);
  Future<void> deleteProject(String projectId);

  Future<void> syncProjects();

  // Task Operations
  Stream<List<Task>> getTasks(String projectId);
  Stream<List<Task>> getAllTasks();
  Future<void> createTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(String taskId);
}
