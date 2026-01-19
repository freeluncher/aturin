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

  Task copyWith({
    String? id,
    String? serverId,
    String? projectId,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? lastUpdated,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return Task(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
