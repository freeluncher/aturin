class Project {
  final String id;
  final String? serverId;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final DateTime? deadline;
  final bool isSynced;
  final bool isDeleted;

  Project({
    required this.id,
    this.serverId,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.lastUpdated,
    this.deadline,
    this.isSynced = false,
    this.isDeleted = false,
  });
}
