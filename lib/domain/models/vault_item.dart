class VaultItem {
  final String id;
  final String key;
  final String value;
  final String? category;
  final String? projectId;
  final String? serverId;
  final bool isSynced;
  final bool isDeleted;
  final DateTime createdAt;

  VaultItem({
    required this.id,
    required this.key,
    required this.value,
    this.category,
    this.projectId,
    this.serverId,
    this.isSynced = false,
    this.isDeleted = false,
    required this.createdAt,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? createdAt; // Default to createdAt if null

  final DateTime lastUpdated;
}
