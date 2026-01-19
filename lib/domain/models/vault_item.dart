class VaultItem {
  final String id;
  final String key;
  final String value;
  final String? category;
  final DateTime createdAt;

  VaultItem({
    required this.id,
    required this.key,
    required this.value,
    this.category,
    required this.createdAt,
  });
}
