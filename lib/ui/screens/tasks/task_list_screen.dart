import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';

import '../../../core/providers.dart';
import '../../../domain/models/task.dart';
import '../../../domain/models/project.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  // 0: None, 1: Project, 2: Priority
  int _groupingMode = 0;

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(allTasksStreamProvider);
    final projectsAsync = ref.watch(projectsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Tasks'),
        actions: [
          PopupMenuButton<int>(
            icon: Icon(
              _groupingMode == 0
                  ? LucideIcons.list
                  : (_groupingMode == 1
                        ? LucideIcons.folder
                        : LucideIcons.arrowUpCircle),
            ),
            tooltip: 'Group by',
            onSelected: (val) => setState(() => _groupingMode = val),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 0,
                child: Row(
                  children: [
                    Icon(LucideIcons.list, size: 18),
                    SizedBox(width: 8),
                    Text('No Grouping'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 1,
                child: Row(
                  children: [
                    Icon(LucideIcons.folder, size: 18),
                    SizedBox(width: 8),
                    Text('Group by Project'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 2,
                child: Row(
                  children: [
                    Icon(LucideIcons.arrowUpCircle, size: 18),
                    SizedBox(width: 8),
                    Text('Group by Priority'),
                  ],
                ),
              ),
            ],
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

          if (_groupingMode == 1) {
            return projectsAsync.when(
              data: (projects) =>
                  _buildGroupedByProjectList(context, tasks, projects),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            );
          } else if (_groupingMode == 2) {
            return projectsAsync.when(
              data: (projects) =>
                  _buildGroupedByPriorityList(context, tasks, projects),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            );
          }

          return projectsAsync.when(
            data: (projects) => _buildFlatList(context, tasks, projects, ref),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading tasks: $err')),
      ),
    );
  }

  Widget _buildFlatList(
    BuildContext context,
    List<Task> tasks,
    List<Project> projects,
    WidgetRef ref,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final project = projects.firstWhereOrNull(
          (p) => p.id == task.projectId,
        );
        return _TaskItemCard(task: task, projectName: project?.name);
      },
    );
  }

  Widget _buildGroupedByProjectList(
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
            ...groupTasks.map(
              (task) => _TaskItemCard(task: task, projectName: projectName),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildGroupedByPriorityList(
    BuildContext context,
    List<Task> tasks,
    List<Project> projects,
  ) {
    // Group tasks by priority
    final groups = groupBy(tasks, (t) => t.priority);

    // Sort keys: High (2) -> Medium (1) -> Low (0)
    final sortedPriorities = groups.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedPriorities.length,
      itemBuilder: (context, index) {
        final priority = sortedPriorities[index];
        final groupTasks = groups[priority] ?? [];

        String priorityLabel;
        Color priorityColor;
        switch (priority) {
          case 2:
            priorityLabel = 'High Priority';
            priorityColor = Colors.red;
            break;
          case 1:
            priorityLabel = 'Medium Priority';
            priorityColor = Colors.orange;
            break;
          case 0:
            priorityLabel = 'Low Priority';
            priorityColor = Colors.green;
            break;
          default:
            priorityLabel = 'Unknown';
            priorityColor = Colors.grey;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 4),
              child: Row(
                children: [
                  Icon(LucideIcons.flag, size: 18, color: priorityColor),
                  const SizedBox(width: 8),
                  Text(
                    priorityLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: priorityColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${groupTasks.length}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: priorityColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...groupTasks.map((task) {
              final project = projects.firstWhereOrNull(
                (p) => p.id == task.projectId,
              );
              return _TaskItemCard(task: task, projectName: project?.name);
            }),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _TaskItemCard extends ConsumerWidget {
  final Task task;
  final String? projectName;

  const _TaskItemCard({required this.task, this.projectName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine Status & Color based on Priority
    Color priorityColor;
    String priorityLabel;
    IconData priorityIcon;

    switch (task.priority) {
      case 2:
        priorityColor = Colors.red;
        priorityLabel = 'High';
        priorityIcon = LucideIcons.arrowUp;
        break;
      case 0:
        priorityColor = Colors.green;
        priorityLabel = 'Low';
        priorityIcon = LucideIcons.arrowDown;
        break;
      default:
        priorityColor = Colors.orange;
        priorityLabel = 'Med';
        priorityIcon = LucideIcons.minus;
    }

    // Format Due Date
    String? deadlineText;
    Color? deadlineColor;
    if (task.dueDate != null) {
      deadlineText = DateFormat('MMM d').format(task.dueDate!);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final listDate = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );

      if (listDate.isBefore(today) && !task.isCompleted) {
        deadlineColor = Colors.red; // Overdue
        deadlineText = '$deadlineText (Overdue)';
      } else if (listDate.isAtSameMomentAs(today)) {
        deadlineColor = Colors.amber; // Today
        deadlineText = 'Today';
      } else {
        deadlineColor = colorScheme.outline;
      }
    }

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              visualDensity: VisualDensity.compact,
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
                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: task.description != null && task.description!.isNotEmpty
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
            // Footer: Project, Priority, Deadline
            Padding(
              padding: const EdgeInsets.only(left: 64, right: 16, bottom: 4),
              child: Row(
                children: [
                  // Project Name (if exists)
                  if (projectName != null) ...[
                    Icon(
                      LucideIcons.folder,
                      size: 12,
                      color: colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      projectName!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.outline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Priority Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: priorityColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(priorityIcon, size: 10, color: priorityColor),
                        const SizedBox(width: 2),
                        Text(
                          priorityLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: priorityColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Deadline (if exists)
                  if (deadlineText != null) ...[
                    const Spacer(),
                    Icon(LucideIcons.clock, size: 12, color: deadlineColor),
                    const SizedBox(width: 4),
                    Text(
                      deadlineText,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: deadlineColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
