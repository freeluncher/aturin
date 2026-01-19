import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/providers.dart';
import '../../../domain/models/project.dart';
import '../../widgets/bento_card.dart';
import 'add_edit_project_screen.dart';
import 'project_detail_screen.dart';

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsStream = ref.watch(projectRepositoryProvider).getProjects();

    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
      body: StreamBuilder<List<Project>>(
        stream: projectsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final projects = snapshot.data ?? [];

          if (projects.isEmpty) {
            return const Center(child: Text('No projects yet. Create one!'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final project = projects[index];
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
                        final updatedProject = project.copyWith(
                          status: newStatus,
                          // lastUpdated updated automatically by repo/DB logic now
                        );
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          context,
                          project.status,
                        ).withOpacity(0.1),
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
                  child: Text(
                    project.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              );
            },
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

  Color _getStatusColor(BuildContext context, int status) {
    switch (status) {
      case 0: // Planning
        return Colors.blue;
      case 1: // Active
        return Colors.green;
      case 2: // Testing
        return Colors.orange;
      case 3: // Completed
        return Colors.grey;
      default:
        return Theme.of(context).colorScheme.primary;
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
