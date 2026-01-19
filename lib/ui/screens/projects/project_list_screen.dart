import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:collection/collection.dart'; // For groupBy

import '../../../core/providers.dart';
import '../../../domain/models/project.dart';
import '../../widgets/bento_card.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/filter_chips.dart';
import 'add_edit_project_screen.dart';
import 'project_detail_screen.dart';

// View State Providers
final projectSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);
final projectStatusFilterProvider = StateProvider.autoDispose<int?>(
  (ref) => null,
);
final projectGroupByStatusProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsStream = ref.watch(projectRepositoryProvider).getProjects();
    final searchQuery = ref.watch(projectSearchQueryProvider);
    final statusFilter = ref.watch(projectStatusFilterProvider);
    final isGrouped = ref.watch(projectGroupByStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            icon: Icon(
              isGrouped ? LucideIcons.layers : LucideIcons.list,
              color: isGrouped ? Theme.of(context).colorScheme.primary : null,
            ),
            tooltip: isGrouped ? 'Ungroup' : 'Group by Status',
            onPressed: () {
              ref.read(projectGroupByStatusProvider.notifier).state =
                  !isGrouped;
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Project>>(
        stream: projectsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          var projects = snapshot.data ?? [];

          // 1. Filter by Status (Memory)
          if (statusFilter != null) {
            projects = projects.where((p) => p.status == statusFilter).toList();
          }

          // 2. Filter by Search Query (Memory)
          if (searchQuery.isNotEmpty) {
            final query = searchQuery.toLowerCase();
            projects = projects.where((p) {
              return p.name.toLowerCase().contains(query) ||
                  p.description.toLowerCase().contains(query) ||
                  (p.clientName?.toLowerCase().contains(query) ?? false);
            }).toList();
          }

          return Column(
            children: [
              // Search & Filter Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSearchBar(
                      hintText: 'Search projects, clients...',
                      onChanged: (val) {
                        ref.read(projectSearchQueryProvider.notifier).state =
                            val;
                      },
                    ),
                    const SizedBox(height: 12),
                    FilterChips<int>(
                      selectedValue: statusFilter,
                      onSelected: (val) {
                        ref.read(projectStatusFilterProvider.notifier).state =
                            val;
                      },
                      options: const {
                        0: 'Planning',
                        1: 'Active',
                        2: 'Testing',
                        3: 'Completed',
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Project List
              Expanded(
                child: projects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.folderOpen,
                              size: 48,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No projects found',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      )
                    : isGrouped
                    ? _buildGroupedList(context, projects, ref)
                    : _buildFlatList(projects),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'project_list_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditProjectScreen()),
          );
        },
        child: const Icon(LucideIcons.plus),
      ),
    );
  }

  Widget _buildFlatList(List<Project> projects) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: projects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _ProjectCard(project: projects[index]);
      },
    );
  }

  Widget _buildGroupedList(
    BuildContext context,
    List<Project> projects,
    WidgetRef ref,
  ) {
    // Determine sort/group order: Planning -> Active -> Testing -> Completed
    final groups = groupBy(projects, (p) => p.status);
    final sortedKeys = groups.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final status = sortedKeys[index];
        final groupProjects = groups[status] ?? [];
        if (groupProjects.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 8),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(status),
                    size: 18,
                    color: _getStatusColor(context, status),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusLabel(status),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: _getStatusColor(context, status),
                      fontWeight: FontWeight.bold,
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
                      '${groupProjects.length}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
            ...groupProjects.map(
              (project) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ProjectCard(project: project),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Color _getStatusColor(BuildContext context, int status) {
    switch (status) {
      case 0: // Planning
        return Colors.blue;
      case 1: // Active
        return Colors.orange;
      case 2: // Testing
        return Colors.purple;
      case 3: // Completed
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(int status) {
    switch (status) {
      case 0:
        return 'Planning';
      case 1:
        return 'Active';
      case 2:
        return 'Testing';
      case 3:
        return 'Completed';
      default:
        return 'Unknown';
    }
  }

  IconData _getStatusIcon(int status) {
    switch (status) {
      case 0:
        return LucideIcons.fileText;
      case 1:
        return LucideIcons.rocket;
      case 2:
        return LucideIcons.flaskConical;
      case 3:
        return LucideIcons.checkCircle;
      default:
        return LucideIcons.helpCircle;
    }
  }
}

class _ProjectCard extends ConsumerWidget {
  final Project project;

  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parent = context.findAncestorWidgetOfExactType<ProjectListScreen>();

    return BentoCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProjectDetailScreen(project: project),
          ),
        );
      },
      title: project.name,
      icon: LucideIcons.folder,
      trailing: Material(
        color: Colors.transparent,
        child: PopupMenuButton<int>(
          tooltip: 'Change Status',
          borderRadius: BorderRadius.circular(12),
          initialValue: project.status,
          onSelected: (newStatus) async {
            if (newStatus != project.status) {
              final updatedProject = project.copyWith(status: newStatus);
              await ref
                  .read(projectRepositoryProvider)
                  .updateProject(updatedProject);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 0, child: Text('📝 Planning')),
            const PopupMenuItem(value: 1, child: Text('🚀 Active')),
            const PopupMenuItem(value: 2, child: Text('🧪 Testing')),
            const PopupMenuItem(value: 3, child: Text('✅ Completed')),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(context, project.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getStatusColor(context, project.status),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(project.status),
                  size: 14,
                  color: _getStatusColor(context, project.status),
                ),
                const SizedBox(width: 4),
                Text(
                  _getStatusLabel(project.status),
                  style: TextStyle(
                    color: _getStatusColor(context, project.status),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (project.clientName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(LucideIcons.user, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    project.clientName!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Define helpers here or import them?
  // Since _ProjectCard is in the same file as Private helpers of ProjectListScreen, it cannot access private members of another class easily unless they are top level or static.
  // To avoid duplication, I will make the helper methods static or top-level, OR just copy them.
  // Actually, I can just make them top-level private functions in the file.

  Color _getStatusColor(BuildContext context, int status) {
    switch (status) {
      case 0: // Planning
        return Colors.blue;
      case 1: // Active
        return Colors.orange;
      case 2: // Testing
        return Colors.purple;
      case 3: // Completed
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(int status) {
    switch (status) {
      case 0:
        return 'Planning';
      case 1:
        return 'Active';
      case 2:
        return 'Testing';
      case 3:
        return 'Completed';
      default:
        return 'Unknown';
    }
  }

  IconData _getStatusIcon(int status) {
    switch (status) {
      case 0:
        return LucideIcons.fileText;
      case 1:
        return LucideIcons.rocket;
      case 2:
        return LucideIcons.flaskConical;
      case 3:
        return LucideIcons.checkCircle;
      default:
        return LucideIcons.helpCircle;
    }
  }
}
