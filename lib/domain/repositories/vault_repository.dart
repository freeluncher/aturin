import '../models/vault_item.dart';

abstract class VaultRepository {
  Stream<List<VaultItem>> getAllItems();
  Future<void> saveItem(VaultItem item);
  Future<void> deleteItem(String id);
}
