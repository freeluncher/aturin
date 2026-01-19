import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/providers.dart';
import '../../../domain/models/project.dart';
import '../../../domain/models/task.dart';
import '../../widgets/bento_card.dart';
import '../tasks/add_edit_task_bottom_sheet.dart';
import 'add_edit_project_screen.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksStream = ref
        .watch(projectRepositoryProvider)
        .getTasks(project.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.pencil),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditProjectScreen(project: project),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Project'),
                  content: const Text(
                    'Are you sure you want to delete this project? This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await ref
                    .read(projectRepositoryProvider)
                    .deleteProject(project.id);
                if (context.mounted) Navigator.pop(context); // Go back to list
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Project Description
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: BentoCard(
              child: Text(
                project.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: tasksStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final tasks = snapshot.data ?? [];

                if (tasks.isEmpty) {
                  return const Center(child: Text('No tasks found.'));
                }

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return ListTile(
                      leading: Checkbox(
                        value: task.isCompleted,
                        onChanged: (val) {
                          final updatedTask = Task(
                            id: task.id,
                            projectId: task.projectId,
                            title: task.title,
                            description: task.description,
                            createdAt: task.createdAt,
                            lastUpdated: DateTime.now(),
                            isCompleted: val ?? false,
                            serverId: task.serverId,
                            isSynced: false,
                            isDeleted: task.isDeleted,
                          );
                          ref
                              .read(projectRepositoryProvider)
                              .updateTask(updatedTask);
                        },
                      ),
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      subtitle: task.description != null
                          ? Text(task.description!)
                          : null,
                      trailing: IconButton(
                        icon: const Icon(LucideIcons.trash2, size: 16),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Task'),
                              content: const Text('Delete this task?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            ref
                                .read(projectRepositoryProvider)
                                .deleteTask(task.id);
                          }
                        },
                      ),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (_) => AddEditTaskBottomSheet(
                            projectId: project.id,
                            task: task,
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (_) => AddEditTaskBottomSheet(projectId: project.id),
          );
        },
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
}
