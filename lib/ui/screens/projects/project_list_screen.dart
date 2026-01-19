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
}
