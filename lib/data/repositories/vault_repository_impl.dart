import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../domain/models/vault_item.dart' as domain;
import '../../domain/repositories/vault_repository.dart';
import '../local/app_database.dart';
import '../mappers/vault_mapper.dart';

class VaultRepositoryImpl implements VaultRepository {
  final AppDatabase _db;

  VaultRepositoryImpl(this._db);

  @override
  Stream<List<domain.VaultItem>> getAllItems() {
    return _db.select(_db.vaultItems).watch().map((rows) {
      return rows.map((row) => VaultMapper.toDomain(row)).toList();
    });
  }

  @override
  Future<void> saveItem(domain.VaultItem item) async {
    await _db
        .into(_db.vaultItems)
        .insertOnConflictUpdate(VaultMapper.toCompanion(item));
  }

  @override
  Future<void> deleteItem(String id) async {
    await (_db.delete(_db.vaultItems)..where((tbl) => tbl.id.equals(id))).go();
  }
}

final vaultRepositoryProvider = Provider<VaultRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return VaultRepositoryImpl(db);
});
