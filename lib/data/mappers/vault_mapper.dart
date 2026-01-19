import 'package:drift/drift.dart';
import '../../domain/models/vault_item.dart' as domain;
import '../local/app_database.dart';

class VaultMapper {
  static domain.VaultItem toDomain(VaultItem entity) {
    return domain.VaultItem(
      id: entity.id,
      key: entity.key,
      value: entity.value,
      category: entity.category,
      projectId: entity.projectId,
      serverId: entity.serverId,
      isSynced: entity.isSynced,
      isDeleted: entity.isDeleted,
      createdAt: entity.createdAt,
      lastUpdated: entity.lastUpdated,
    );
  }

  static VaultItemsCompanion toCompanion(domain.VaultItem model) {
    return VaultItemsCompanion(
      id: Value(model.id),
      key: Value(model.key),
      value: Value(model.value),
      category: Value(model.category),
      projectId: Value(model.projectId),
      serverId: Value(model.serverId),
      isSynced: Value(model.isSynced),
      isDeleted: Value(model.isDeleted),
      createdAt: Value(model.createdAt),
      lastUpdated: Value(model.lastUpdated),
    );
  }
}
