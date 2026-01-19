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
      createdAt: entity.createdAt,
    );
  }

  static VaultItemsCompanion toCompanion(domain.VaultItem model) {
    return VaultItemsCompanion(
      id: Value(model.id),
      key: Value(model.key),
      value: Value(model.value),
      category: Value(model.category),
      createdAt: Value(model.createdAt),
    );
  }
}
