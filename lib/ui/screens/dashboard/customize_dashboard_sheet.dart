import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/providers/dashboard_config_provider.dart';

class CustomizeDashboardSheet extends ConsumerWidget {
  const CustomizeDashboardSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(dashboardConfigProvider);
    final theme = Theme.of(context);

    final visibleItems = config.visibleSectionIds;
    final hiddenItems = config.hiddenSectionIds;

    const sectionTitles = {
      'featured_project': 'Featured Project',
      'todays_tasks': "Today's Tasks",
      'financial_overview': 'Financial Overview',
      'workload_summary': 'Workload Summary',
    };

    const sectionIcons = {
      'featured_project': LucideIcons.star,
      'todays_tasks': LucideIcons.calendarCheck,
      'financial_overview': LucideIcons.trendingUp,
      'workload_summary': LucideIcons.barChart2,
    };

    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Customize Dashboard',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref
                        .read(dashboardConfigProvider.notifier)
                        .resetToDefaults();
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Drag to reorder visible items.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),

          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (visibleItems.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Text(
                        'VISIBLE',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: visibleItems.length,
                      onReorder: (oldIndex, newIndex) {
                        ref
                            .read(dashboardConfigProvider.notifier)
                            .reorder(oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final id = visibleItems[index];
                        return ListTile(
                          key: ValueKey(id),
                          leading: Icon(
                            sectionIcons[id] ?? LucideIcons.box,
                            size: 20,
                          ),
                          title: Text(sectionTitles[id] ?? id),
                          trailing: IconButton(
                            icon: const Icon(LucideIcons.eyeOff, size: 20),
                            onPressed: () {
                              ref
                                  .read(dashboardConfigProvider.notifier)
                                  .toggleVisibility(id);
                            },
                          ),
                        );
                      },
                    ),
                  ],

                  if (hiddenItems.isNotEmpty) ...[
                    const Divider(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Text(
                        'HIDDEN',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.outline,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: hiddenItems.length,
                      itemBuilder: (context, index) {
                        final id = hiddenItems[index];
                        return ListTile(
                          leading: Icon(
                            sectionIcons[id] ?? LucideIcons.box,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          title: Text(
                            sectionTitles[id] ?? id,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(LucideIcons.eye, size: 20),
                            color: theme.colorScheme.primary,
                            onPressed: () {
                              ref
                                  .read(dashboardConfigProvider.notifier)
                                  .toggleVisibility(id);
                            },
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
