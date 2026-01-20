import 'package:drift/drift.dart';
import '../../data/local/app_database.dart';
import '../../domain/models/task.dart' as domain;

extension TaskMapper on Task {
  domain.Task toDomain() {
    return domain.Task(
      id: id,
      serverId: serverId,
      projectId: projectId,
      title: title,
      description: description,
      isCompleted: isCompleted,
      createdAt: createdAt,
      lastUpdated: lastUpdated,
      priority: priority,
      dueDate: dueDate,
      isSynced: isSynced,
      isDeleted: isDeleted,
    );
  }
}

extension DomainTaskMapper on domain.Task {
  TasksCompanion toCompanion() {
    return TasksCompanion(
      id: Value(id),
      serverId: Value(serverId),
      projectId: Value(projectId),
      title: Value(title),
      description: Value(description),
      isCompleted: Value(isCompleted),
      createdAt: Value(createdAt),

      lastUpdated: Value(lastUpdated),
      priority: Value(priority),
      dueDate: Value(dueDate),
      isSynced: Value(isSynced),
      isDeleted: Value(isDeleted),
    );
  }
}
