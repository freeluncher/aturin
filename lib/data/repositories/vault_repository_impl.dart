import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:drift/drift.dart';

import '../../core/providers.dart';
import '../../domain/models/vault_item.dart' as domain;
import '../../domain/repositories/vault_repository.dart';
import '../local/app_database.dart';
import '../mappers/vault_mapper.dart';

class VaultRepositoryImpl implements VaultRepository {
  final AppDatabase _db;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Cache the key to avoid reading from storage every time
  encrypt.Key? _cachedKey;

  VaultRepositoryImpl(this._db);

  Future<encrypt.Key> _getOrGenerateKey() async {
    if (_cachedKey != null) return _cachedKey!;

    String? keyStr = await _storage.read(key: 'vault_master_key');
    if (keyStr == null) {
      // Generate new key
      final key = encrypt.Key.fromSecureRandom(32); // AES-256
      await _storage.write(key: 'vault_master_key', value: key.base64);
      _cachedKey = key;
    } else {
      _cachedKey = encrypt.Key.fromBase64(keyStr);
    }
    return _cachedKey!;
  }

  Future<String> _encrypt(String plainText) async {
    final key = await _getOrGenerateKey();
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    // Return Format: iv:ciphertext
    return '${iv.base64}:${encrypted.base64}';
  }

  Future<String> _decrypt(String encryptedText) async {
    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) return encryptedText; // Fallback or corrupt

      final iv = encrypt.IV.fromBase64(parts[0]);
      final ciphertext = parts[1];

      final key = await _getOrGenerateKey();
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      return encrypter.decrypt64(ciphertext, iv: iv);
    } catch (e) {
      return 'Error: Decryption failed';
    }
  }

  @override
  Stream<List<domain.VaultItem>> getAllItems() {
    return _db.select(_db.vaultItems).watch().asyncMap((rows) async {
      final items = <domain.VaultItem>[];
      for (var row in rows) {
        // Decrypt value before returning to Domain
        final domainItem = VaultMapper.toDomain(row);
        final decryptedValue = await _decrypt(domainItem.value);
        items.add(
          domain.VaultItem(
            id: domainItem.id,
            key: domainItem.key,
            value: decryptedValue,
            category: domainItem.category,
            projectId: domainItem.projectId,
            serverId: domainItem.serverId,
            isSynced: domainItem.isSynced,
            isDeleted: domainItem.isDeleted,
            createdAt: domainItem.createdAt,
          ),
        );
      }
      return items;
    });
  }

  @override
  Future<void> saveItem(domain.VaultItem item) async {
    // Encrypt value before saving to DB
    final encryptedValue = await _encrypt(item.value);

    // Create new object with encrypted value but same ID etc.
    final encryptedItem = domain.VaultItem(
      id: item.id,
      key: item.key,
      value: encryptedValue,
      category: item.category,
      projectId: item.projectId,
      serverId: item.serverId,
      isSynced: false, // Mark unsynced on change
      isDeleted: item.isDeleted,
      createdAt: item.createdAt,
    );

    await _db
        .into(_db.vaultItems)
        .insertOnConflictUpdate(VaultMapper.toCompanion(encryptedItem));
  }

  @override
  Future<void> deleteItem(String id) async {
    // Soft Delete for sync
    await (_db.update(_db.vaultItems)..where((tbl) => tbl.id.equals(id))).write(
      VaultItemsCompanion(
        isDeleted: const Value(true),
        isSynced: const Value(false),
      ),
    );
  }
}

final vaultRepositoryProvider = Provider<VaultRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return VaultRepositoryImpl(db);
});
