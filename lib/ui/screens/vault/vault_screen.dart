import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers.dart';
import '../../../data/repositories/vault_repository_impl.dart';
import '../../../data/services/sync_service.dart';
import '../../../domain/models/vault_item.dart';
import '../../widgets/bento_card.dart';

class VaultScreen extends ConsumerWidget {
  final String? categoryFilter;

  const VaultScreen({super.key, this.categoryFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultStream = ref.watch(vaultRepositoryProvider).getAllItems();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          categoryFilter != null ? '$categoryFilter Vault' : 'Developer Vault',
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () =>
                showAddEditDialog(context, ref, null, categoryFilter),
          ),
        ],
      ),
      body: StreamBuilder<List<VaultItem>>(
        stream: vaultStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          var items = snapshot.data ?? [];

          // Filter if category is provided
          if (categoryFilter != null) {
            items = items.where((i) => i.category == categoryFilter).toList();
          }

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.shield,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  const Text('Vault is safe... and empty.'),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        showAddEditDialog(context, ref, null, categoryFilter),
                    icon: const Icon(LucideIcons.plus),
                    label: const Text('Add Secret'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _VaultItemCard(item: item, ref: ref);
            },
          );
        },
      ),
    );
  }

  static void showAddEditDialog(
    BuildContext context,
    WidgetRef ref, [
    VaultItem? existingItem,
    String? defaultCategory,
  ]) {
    final keyController = TextEditingController(text: existingItem?.key);
    final valueController = TextEditingController(text: existingItem?.value);
    final categoryController = TextEditingController(
      text: existingItem?.category ?? defaultCategory,
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingItem == null ? 'Add Secret' : 'Edit Secret'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: keyController,
                decoration: const InputDecoration(
                  labelText: 'Key (e.g. API Key)',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: valueController,
                decoration: const InputDecoration(labelText: 'Value (Secret)'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                obscureText: true, // Initially obscured
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category (Project Name)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (existingItem != null) {
                // Delete confirmation
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('⚠️ PERINGATAN KEAMANAN'),
                    content: const Text(
                      'Apakah Anda yakin? Item ini akan dihapus secara permanen demi keamanan dan tidak dapat dipulihkan lagi.\n\nPastikan Anda sudah membackup jika diperlukan.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () async {
                          await ref
                              .read(vaultRepositoryProvider)
                              .deleteItem(existingItem.id);
                          // Trigger sync to update server immediately (Soft Delete)
                          ref.read(syncServiceProvider).syncUp();

                          if (context.mounted) {
                            Navigator.pop(context); // Close confirm
                            Navigator.pop(context); // Close edit
                          }
                        },
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              } else {
                Navigator.pop(context);
              }
            },
            child: Text(
              existingItem == null ? 'Cancel' : 'Delete',
              style: TextStyle(
                color: existingItem != null
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
            ),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newItem = VaultItem(
                  id: existingItem?.id ?? const Uuid().v4(),
                  key: keyController.text,
                  value: valueController.text,
                  category: categoryController.text.trim().isEmpty
                      ? null
                      : categoryController.text.trim(),
                  projectId:
                      existingItem?.projectId ??
                      (defaultCategory != null
                          ? null
                          : null), // Handle projectId if passed
                  createdAt: existingItem?.createdAt ?? DateTime.now(),
                );
                await ref.read(vaultRepositoryProvider).saveItem(newItem);
                // Trigger sync to update server immediately
                ref.read(syncServiceProvider).syncUp();

                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _VaultItemCard extends StatefulWidget {
  final VaultItem item;
  final WidgetRef ref;

  const _VaultItemCard({required this.item, required this.ref});

  @override
  State<_VaultItemCard> createState() => _VaultItemCardState();
}

class _VaultItemCardState extends State<_VaultItemCard> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: BentoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.key,
                  size: 20,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.item.key,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.edit2, size: 16),
                  onPressed: () => VaultScreen.showAddEditDialog(
                    context,
                    widget.ref,
                    widget.item,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                setState(() {
                  _revealed = !_revealed;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _revealed ? widget.item.value : '•' * 20,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontFamily: _revealed ? 'Monospace' : null,
                          letterSpacing: _revealed ? 0 : 2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _revealed ? LucideIcons.eyeOff : LucideIcons.eye,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _revealed = !_revealed;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.copy, size: 20),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: widget.item.value),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied to clipboard!'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
