import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:collection/collection.dart';

import '../../../core/providers.dart';
import '../../../domain/models/task.dart';
import '../../../domain/models/project.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  bool _isGroupedByProject = false;

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(allTasksStreamProvider);
    final projectsAsync = ref.watch(projectsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Tasks'),
        actions: [
          IconButton(
            icon: Icon(
              _isGroupedByProject ? LucideIcons.layers : LucideIcons.list,
              color: _isGroupedByProject
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            tooltip: _isGroupedByProject ? 'Ungroup' : 'Group by Project',
            onPressed: () {
              setState(() {
                _isGroupedByProject = !_isGroupedByProject;
              });
            },
          ),
        ],
      ),
      body: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.checkCircle, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No tasks found'),
                ],
              ),
            );
          }

          if (_isGroupedByProject) {
            return projectsAsync.when(
              data: (projects) => _buildGroupedList(context, tasks, projects),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            );
          }

          return _buildFlatList(context, tasks, ref);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading tasks: $err')),
      ),
    );
  }

  Widget _buildFlatList(BuildContext context, List<Task> tasks, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return _TaskItemCard(task: tasks[index]);
      },
    );
  }

  Widget _buildGroupedList(
    BuildContext context,
    List<Task> tasks,
    List<Project> projects,
  ) {
    // Map Project ID to Project Name for easy lookup
    final projectMap = {for (var p in projects) p.id: p.name};

    // Group tasks by projectId
    final groups = groupBy(tasks, (t) => t.projectId);

    // Sort keys (Project IDs) based on Project Name
    final sortedProjectIds = groups.keys.toList()
      ..sort((a, b) {
        final nameA = projectMap[a] ?? 'Unknown Project';
        final nameB = projectMap[b] ?? 'Unknown Project';
        return nameA.compareTo(nameB);
      });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedProjectIds.length,
      itemBuilder: (context, index) {
        final projectId = sortedProjectIds[index];
        final groupTasks = groups[projectId] ?? [];
        final projectName = projectMap[projectId] ?? 'Unknown Project';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 4),
              child: Row(
                children: [
                  const Icon(LucideIcons.folder, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    projectName,
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
                      '${groupTasks.length}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
            ...groupTasks.map((task) => _TaskItemCard(task: task)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _TaskItemCard extends ConsumerWidget {
  final Task task;

  const _TaskItemCard({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (val) {
            final updatedTask = task.copyWith(
              isCompleted: val ?? false,
              lastUpdated: DateTime.now(),
              isSynced: false,
            );
            ref.read(projectRepositoryProvider).updateTask(updatedTask);
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: task.description != null
            ? Text(
                task.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
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
              ref.read(projectRepositoryProvider).deleteTask(task.id);
            }
          },
        ),
      ),
    );
  }
}
