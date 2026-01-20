import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';

import '../../../core/providers.dart';
import '../../../domain/models/vault_item.dart';
import '../../widgets/bento_card.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/filter_chips.dart';

class VaultScreen extends ConsumerStatefulWidget {
  final String? categoryFilter;

  const VaultScreen({super.key, this.categoryFilter});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();

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
                      (defaultCategory != null ? null : null),
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

class _VaultScreenState extends ConsumerState<VaultScreen> {
  String _searchQuery = '';
  String? _categoryFilter;
  bool _isGrouped = false;

  @override
  void initState() {
    super.initState();
    // Use initial filter from widget if provided
    if (widget.categoryFilter != null) {
      _categoryFilter = widget.categoryFilter;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vaultStream = ref.watch(vaultRepositoryProvider).getAllItems();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.categoryFilter != null
              ? '${widget.categoryFilter} Vault'
              : 'Brankas Data',
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isGrouped ? LucideIcons.layers : LucideIcons.list,
              color: _isGrouped ? Theme.of(context).colorScheme.primary : null,
            ),
            tooltip: _isGrouped ? 'Ungroup' : 'Group by Category',
            onPressed: () {
              setState(() {
                _isGrouped = !_isGrouped;
              });
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () => VaultScreen.showAddEditDialog(
              context,
              ref,
              null,
              widget.categoryFilter,
            ),
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
          final allCategories = items
              .map((e) => e.category)
              .where((c) => c != null)
              .toSet()
              .toList()
              .cast<String>();
          allCategories.sort();

          // 1. Initial Widget Filter (if restricted mode)
          if (widget.categoryFilter != null) {
            items = items
                .where((i) => i.category == widget.categoryFilter)
                .toList();
          }

          // 2. User Selected Filter
          if (_categoryFilter != null && widget.categoryFilter == null) {
            items = items.where((i) => i.category == _categoryFilter).toList();
          }

          // 3. Search Filter
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            items = items.where((i) {
              return i.key.toLowerCase().contains(query) ||
                  (i.category?.toLowerCase().contains(query) ?? false);
            }).toList();
          }

          return Column(
            children: [
              if (widget.categoryFilter == null) ...[
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Column(
                    children: [
                      AppSearchBar(
                        hintText: 'Search secrets, keys...',
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      FilterChips<String>(
                        selectedValue: _categoryFilter,
                        onSelected: (val) {
                          setState(() {
                            _categoryFilter = val;
                          });
                        },
                        options: {for (var c in allCategories) c: c},
                        allLabel: 'All Categories',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.shield,
                              size: 64,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            const Text('No secrets found.'),
                            if (_searchQuery.isEmpty && _categoryFilter == null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: FilledButton.tonalIcon(
                                  onPressed: () =>
                                      VaultScreen.showAddEditDialog(
                                        context,
                                        ref,
                                        null,
                                        widget.categoryFilter,
                                      ),
                                  icon: const Icon(LucideIcons.plus),
                                  label: const Text('Add Secret'),
                                ),
                              ),
                          ],
                        ),
                      )
                    : _isGrouped
                    ? _buildGroupedList(context, items)
                    : _buildFlatList(items),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFlatList(List<VaultItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _VaultItemCard(item: item, ref: ref);
      },
    );
  }

  Widget _buildGroupedList(BuildContext context, List<VaultItem> items) {
    final groups = groupBy(items, (i) => i.category ?? 'Uncategorized');
    final sortedKeys = groups.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final category = sortedKeys[index];
        final groupItems = groups[category] ?? [];
        if (groupItems.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 4),
              child: Row(
                children: [
                  Icon(
                    category == 'Uncategorized'
                        ? LucideIcons.helpCircle
                        : LucideIcons.folderKey,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${groupItems.length}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
            ...groupItems.map((item) => _VaultItemCard(item: item, ref: ref)),
            const SizedBox(height: 8),
          ],
        );
      },
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.key,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.item.category != null)
                        Text(
                          widget.item.category!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                    ],
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
