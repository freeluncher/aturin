import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/providers.dart';
import '../../domain/models/project.dart';
import '../../domain/models/task.dart';
import '../widgets/bento_card.dart';
import 'add_edit_task_bottom_sheet.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksStream = ref
        .watch(projectRepositoryProvider)
        .getTasks(project.id);

    return Scaffold(
      appBar: AppBar(title: Text(project.name)),
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
                final activeTasks = tasks.where((t) => !t.isDeleted).toList();

                if (activeTasks.isEmpty) {
                  return const Center(child: Text('No tasks found.'));
                }

                return ListView.builder(
                  itemCount: activeTasks.length,
                  itemBuilder: (context, index) {
                    final task = activeTasks[index];
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
                        onPressed: () {
                          ref
                              .read(projectRepositoryProvider)
                              .deleteTask(task.id);
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
