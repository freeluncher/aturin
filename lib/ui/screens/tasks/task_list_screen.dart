import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';

import '../../../core/providers.dart';
import '../../../domain/models/task.dart';
import '../../../domain/models/project.dart';
import 'add_edit_task_bottom_sheet.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All'; // All, Today, Upcoming, Overdue, Completed

  // Note: We'll keep the existing Grouping Mode toggles as well,
  // but "Smart Grouping" (Date) might become the default or an option.
  // 0: Date (Smart), 1: Project, 2: Priority, 3: None
  int _groupingMode = 0;

  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleTask(Task task) {
    final updated = task.copyWith(
      isCompleted: !task.isCompleted,
      lastUpdated: DateTime.now(),
      isSynced: false,
    );
    ref.read(projectRepositoryProvider).updateTask(updated);
  }

  void _deleteTask(Task task) {
    ref.read(projectRepositoryProvider).deleteTask(task.id);

    // Keep it explicit for high visibility
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF03DAC6), // As requested
        content: const Text(
          'Task deleted',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.normal),
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.black,
          onPressed: () {
            ref.read(projectRepositoryProvider).updateTask(task);
          },
        ),
      ),
    );
  }

  List<Task> _filterTasks(List<Task> tasks) {
    return tasks.where((t) {
      // 1. Search Query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesTitle = t.title.toLowerCase().contains(q);
        final matchesDesc = t.description?.toLowerCase().contains(q) ?? false;
        if (!matchesTitle && !matchesDesc) return false;
      }

      // 2. Chip Filters
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      switch (_selectedFilter) {
        case 'Completed':
          return t.isCompleted;
        case 'Overdue':
          if (t.isCompleted || t.dueDate == null) return false;
          final due = DateTime(
            t.dueDate!.year,
            t.dueDate!.month,
            t.dueDate!.day,
          );
          return due.isBefore(today);
        case 'Today':
          if (t.isCompleted || t.dueDate == null) return false;
          final due = DateTime(
            t.dueDate!.year,
            t.dueDate!.month,
            t.dueDate!.day,
          );
          return due.isAtSameMomentAs(today);
        case 'Upcoming':
          if (t.isCompleted || t.dueDate == null) return false;
          final due = DateTime(
            t.dueDate!.year,
            t.dueDate!.month,
            t.dueDate!.day,
          );
          return due.isAfter(today);
        default: // 'All' - Show active tasks (not completed) by default?
          // Or show everything? usually 'All' means active in Todo apps.
          // Let's toggle: 'All' -> Active, 'Completed' -> Completed.
          if (_selectedFilter == 'All') return !t.isCompleted;
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(allTasksStreamProvider);
    final projectsAsync = ref.watch(projectsStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            title: const Text('Tasks'),
            floating: true,
            pinned: true,
            forceElevated: innerBoxIsScrolled,
            actions: [
              PopupMenuButton<int>(
                icon: const Icon(
                  LucideIcons.arrowUpDown,
                ), // Better icon for sorting/grouping
                tooltip: 'Group by',
                onSelected: (val) => setState(() => _groupingMode = val),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 0,
                    child: Row(
                      children: [
                        Icon(LucideIcons.calendar, size: 18),
                        SizedBox(width: 8),
                        Text('Group by Date'),
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
                        Icon(LucideIcons.flag, size: 18),
                        SizedBox(width: 8),
                        Text('Group by Priority'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 3,
                    child: Row(
                      children: [
                        Icon(LucideIcons.list, size: 18),
                        SizedBox(width: 8),
                        Text('No Grouping'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(
                120,
              ), // Search + Chips + Padding
              child: Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search tasks...',
                        prefixIcon: const Icon(LucideIcons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All Active',
                          isSelected: _selectedFilter == 'All',
                          onTap: () => setState(() => _selectedFilter = 'All'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Today',
                          isSelected: _selectedFilter == 'Today',
                          onTap: () =>
                              setState(() => _selectedFilter = 'Today'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Upcoming',
                          isSelected: _selectedFilter == 'Upcoming',
                          onTap: () =>
                              setState(() => _selectedFilter = 'Upcoming'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Overdue',
                          isSelected: _selectedFilter == 'Overdue',
                          onTap: () =>
                              setState(() => _selectedFilter = 'Overdue'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Completed',
                          isSelected: _selectedFilter == 'Completed',
                          onTap: () =>
                              setState(() => _selectedFilter = 'Completed'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: tasksAsync.when(
          data: (allTasks) {
            final filteredTasks = _filterTasks(allTasks);

            if (filteredTasks.isEmpty) {
              return _buildEmptyState(theme);
            }

            return projectsAsync.when(
              data: (projects) =>
                  _buildTaskContent(context, filteredTasks, projects),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => const AddEditTaskBottomSheet(),
          );
        },
        child: const Icon(LucideIcons.plus),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    if (_searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.searchX, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No results for "$_searchQuery"',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    // Contextual Empty States based on Filter
    String message = 'No tasks found';
    IconData icon = LucideIcons.checkCircle2;

    switch (_selectedFilter) {
      case 'Today':
        message = 'No tasks due today!';
        break;
      case 'Overdue':
        message = 'Great job! No overdue tasks.';
        icon = LucideIcons.thumbsUp;
        break;
      case 'Completed':
        message = 'No completed tasks yet.';
        icon = LucideIcons.listTodo;
        break;
      case 'All':
        message = 'You\'re all caught up!';
        icon = LucideIcons.partyPopper;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskContent(
    BuildContext context,
    List<Task> tasks,
    List<Project> projects,
  ) {
    // 0: Date, 1: Project, 2: Priority, 3: None
    switch (_groupingMode) {
      case 0:
        return _buildGroupedByDate(context, tasks, projects);
      case 1:
        return _buildGroupedByProject(context, tasks, projects);
      case 2:
        return _buildGroupedByPriority(context, tasks, projects);
      default:
        return _buildFlatList(context, tasks, projects);
    }
  }

  // --- Grouping Implementations ---

  Widget _buildFlatList(
    BuildContext context,
    List<Task> tasks,
    List<Project> projects,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), // Bottom pad for FAB
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final project = projects.firstWhereOrNull(
          (p) => p.id == task.projectId,
        );
        return _TaskItemCard(
          task: task,
          projectName: project?.name,
          key: ValueKey(task.id),
          onToggleComplete: () => _toggleTask(task),
          onDelete: () => _deleteTask(task),
        );
      },
    );
  }

  Widget _buildGroupedByDate(
    BuildContext context,
    List<Task> tasks,
    List<Project> projects,
  ) {
    // Buckets: Overdue, Today, Tomorrow, Next 7 Days, Later, No Date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeek = today.add(const Duration(days: 7));

    final groups = groupBy<Task, String>(tasks, (task) {
      if (task.dueDate == null) return 'No Date';
      final d = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );

      if (d.isBefore(today)) return 'Overdue';
      if (d.isAtSameMomentAs(today)) return 'Today';
      if (d.isAtSameMomentAs(tomorrow)) return 'Tomorrow';
      if (d.isBefore(nextWeek)) return 'Next 7 Days';
      return 'Later';
    });

    // Custom Sort Order
    final sortOrder = [
      'Overdue',
      'Today',
      'Tomorrow',
      'Next 7 Days',
      'Later',
      'No Date',
    ];
    final sortedKeys = groups.keys.toList()
      ..sort((a, b) => sortOrder.indexOf(a).compareTo(sortOrder.indexOf(b)));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final key = sortedKeys[index];
        final groupTasks = groups[key] ?? [];

        Color headerColor;
        if (key == 'Overdue')
          headerColor = Colors.red;
        else if (key == 'Today')
          headerColor = Colors.amber.shade700;
        else
          headerColor = Theme.of(context).colorScheme.primary;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGroupHeader(context, key, groupTasks.length, headerColor),
            ...groupTasks.map((t) {
              final p = projects.firstWhereOrNull(
                (proj) => proj.id == t.projectId,
              );
              return _TaskItemCard(
                task: t,
                projectName: p?.name,
                key: ValueKey(t.id),
                onToggleComplete: () => _toggleTask(t),
                onDelete: () => _deleteTask(t),
              );
            }),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  // Reuse logic for Project & Priority but adapted to new signature
  Widget _buildGroupedByProject(
    BuildContext context,
    List<Task> tasks,
    List<Project> projects,
  ) {
    final projectMap = {for (var p in projects) p.id: p.name};
    final groups = groupBy(tasks, (t) => t.projectId);
    final sortedKeys = groups.keys.toList()
      ..sort((a, b) => (projectMap[a] ?? 'Z').compareTo(projectMap[b] ?? 'Z'));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final pid = sortedKeys[index];
        final groupTasks = groups[pid]!;
        final name = projectMap[pid] ?? 'Unknown Project';

        return Column(
          children: [
            _buildGroupHeader(context, name, groupTasks.length, null),
            ...groupTasks.map(
              (t) => _TaskItemCard(
                task: t,
                projectName: name,
                key: ValueKey(t.id),
                onToggleComplete: () => _toggleTask(t),
                onDelete: () => _deleteTask(t),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildGroupedByPriority(
    BuildContext context,
    List<Task> tasks,
    List<Project> projects,
  ) {
    final groups = groupBy(tasks, (t) => t.priority);
    final sortedKeys = groups.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // High to Low

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final priority = sortedKeys[index];
        final groupTasks = groups[priority]!;

        String label;
        Color color;
        switch (priority) {
          case 2:
            label = 'High Priority';
            color = Colors.red;
            break;
          case 1:
            label = 'Medium Priority';
            color = Colors.orange;
            break;
          default:
            label = 'Low Priority';
            color = Colors.green;
        }

        return Column(
          children: [
            _buildGroupHeader(context, label, groupTasks.length, color),
            ...groupTasks.map((t) {
              final p = projects.firstWhereOrNull(
                (pro) => pro.id == t.projectId,
              );
              return _TaskItemCard(
                task: t,
                projectName: p?.name,
                key: ValueKey(t.id),
                onToggleComplete: () => _toggleTask(t),
                onDelete: () => _deleteTask(t),
              );
            }),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildGroupHeader(
    BuildContext context,
    String title,
    int count,
    Color? color,
  ) {
    final theme = Theme.of(context);
    final headerColor = color ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: headerColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: headerColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                color: headerColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _TaskItemCard extends StatelessWidget {
  final Task task;
  final String? projectName;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;

  const _TaskItemCard({
    super.key,
    required this.task,
    this.projectName,
    required this.onToggleComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine Status & Color based on Priority
    Color priorityColor;
    switch (task.priority) {
      case 2:
        priorityColor = Colors.redAccent;
        break; // High
      case 0:
        priorityColor = Colors.green;
        break; // Low
      default:
        priorityColor = Colors.orange; // Medium
    }

    // Format Due Date
    String? deadlineText;
    Color? deadlineColor;
    if (task.dueDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final listDate = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );

      if (listDate.isBefore(today) && !task.isCompleted) {
        deadlineColor = theme.colorScheme.error; // Overdue
        deadlineText =
            'Overdue'; // Simpler text for compacted view, or formatted date
        deadlineText = DateFormat(
          'MMM d',
        ).format(task.dueDate!); // Keep formatting
      } else if (listDate.isAtSameMomentAs(today)) {
        deadlineColor = Colors.amber.shade700;
        deadlineText = 'Today';
      } else {
        deadlineColor = theme.colorScheme.outline;
        deadlineText = DateFormat('MMM d').format(task.dueDate!);
      }
    }

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.checkCircle2, color: Colors.green.shade700),
            const SizedBox(width: 8),
            Text(
              'Complete',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Icon(LucideIcons.trash2, color: Colors.red.shade700),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe Right -> Complete
          onToggleComplete();
          return false; // Snap back, let stream update list
        } else {
          // Swipe Left -> Delete
          return true; // Allow dismiss
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          // Delete
          onDelete();
        }
      },
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        color: theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        clipBehavior: Clip.antiAlias, // For the left strip
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Priority Strip
              Container(width: 4, color: priorityColor),
              // Main Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    decoration: task.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: task.isCompleted
                                        ? theme.colorScheme.outline
                                        : null,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (task.description != null &&
                                    task.description!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      task.description!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.outline,
                                          ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Checkbox (Optional, kept for explicit action)
                          Transform.scale(
                            scale: 0.9,
                            child: Checkbox(
                              visualDensity: VisualDensity.compact,
                              value: task.isCompleted,
                              shape: CircleBorder(),
                              activeColor: priorityColor,
                              onChanged: (val) => onToggleComplete(),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Footer Metadata
                      Row(
                        children: [
                          if (projectName != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.folder,
                                    size: 10,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    projectName!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],

                          if (deadlineText != null) ...[
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.clock,
                                  size: 12,
                                  color: deadlineColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  deadlineText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: deadlineColor,
                                    fontWeight:
                                        deadlineColor == theme.colorScheme.error
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
