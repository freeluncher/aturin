class Task {
  final String id;
  final String? serverId;
  final String projectId;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final bool isSynced;
  final bool isDeleted;

  Task({
    required this.id,
    this.serverId,
    required this.projectId,
    required this.title,
    this.description,
    this.isCompleted = false,
    required this.createdAt,
    required this.lastUpdated,
    this.isSynced = false,
    this.isDeleted = false,
  });
}
