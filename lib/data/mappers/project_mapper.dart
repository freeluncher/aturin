import 'package:drift/drift.dart';
import '../../data/local/app_database.dart';
import '../../domain/models/project.dart' as domain;

extension ProjectMapper on Project {
  domain.Project toDomain() {
    return domain.Project(
      id: id,
      serverId: serverId,
      name: name,
      description: description,
      createdAt: createdAt,
      lastUpdated: lastUpdated,
      isSynced: isSynced,
      isDeleted: isDeleted,
    );
  }
}

extension DomainProjectMapper on domain.Project {
  ProjectsCompanion toCompanion() {
    return ProjectsCompanion(
      id: Value(id),
      serverId: Value(serverId),
      name: Value(name),
      description: Value(description),
      createdAt: Value(createdAt),
      lastUpdated: Value(lastUpdated),
      isSynced: Value(isSynced),
      isDeleted: Value(isDeleted),
    );
  }
}
