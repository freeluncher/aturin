import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers.dart';
import '../../../domain/models/project.dart';
import '../../../domain/models/task.dart';
import '../../../domain/extensions/project_extensions.dart'; // Import extension
import '../../widgets/bento_card.dart';
import '../tasks/add_edit_task_bottom_sheet.dart';
import '../financial/add_edit_invoice_sheet.dart';
import 'project_invoices_screen.dart'; // Moved here
import 'add_edit_project_screen.dart';
import '../vault/vault_screen.dart';
// Unused imports removed

class ProjectDetailScreen extends ConsumerWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch latest project data to ensure updates (e.g. status change) are reflected immediately
    // If not found (deleted), pop or show error.
    final projectStream = ref.watch(projectRepositoryProvider).getProjects();

    return StreamBuilder<List<Project>>(
      stream: projectStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );

        // Find current project
        final currentProject = snapshot.data!.firstWhere(
          (p) => p.id == project.id,
          orElse: () => project, // Fallback if not found (deleted)
        );

        if (currentProject.isDeleted) {
          // Handle deleted case gracefully if needed, for now just show fallback
          return const Scaffold(body: Center(child: Text("Project Deleted")));
        }

        final tasksStream = ref
            .watch(projectRepositoryProvider)
            .getTasks(currentProject.id);

        return Scaffold(
          body: LayoutBuilder(
            builder: (context, constraints) {
              // Use separate layouts for Desktop vs Mobile if needed,
              // but Bento Grid is responsive by nature.
              // We will use a SingleChildScrollView + Column/Grid combination.
              final isDesktop = constraints.maxWidth > 800;

              return Row(
                children: [
                  // Sidebar for Desktop (Tech Stack & Vault)
                  if (isDesktop)
                    SizedBox(
                      width: 300,
                      child: _SidePanel(project: currentProject),
                    ),

                  // Main Content
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        // App Bar
                        SliverAppBar.large(
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentProject.name,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (currentProject.clientName != null)
                                Text(
                                  'Client: ${currentProject.clientName}',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                            ],
                          ),
                          actions: [
                            _StatusBadge(status: currentProject.status),
                            IconButton(
                              icon: const Icon(LucideIcons.pencil),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddEditProjectScreen(
                                      project: currentProject,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.trash2),
                              onPressed: () =>
                                  _confirmDelete(context, ref, currentProject),
                            ),
                          ],
                        ),

                        // Bento Overview
                        SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: StreamBuilder<List<Task>>(
                            stream: tasksStream,
                            builder: (context, taskSnapshot) {
                              final tasks = taskSnapshot.data ?? [];
                              return SliverToBoxAdapter(
                                child: StaggeredGrid.count(
                                  crossAxisCount: isDesktop
                                      ? 3
                                      : 1, // 3 columns on desktop, 1 on mobile
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  children: [
                                    // 1. Progress
                                    _buildProgressCard(
                                      context,
                                      currentProject,
                                      tasks,
                                    ),
                                    // 2. Urgency
                                    _buildUrgencyCard(context, currentProject),
                                    // 3. Finance
                                    _buildFinanceCard(context, currentProject),
                                    // Tech Stack (Mobile Only)
                                    if (!isDesktop)
                                      _buildTechStackCard(
                                        context,
                                        currentProject,
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        // Tasks Header
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Tasks",
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (_) => AddEditTaskBottomSheet(
                                        projectId: currentProject.id,
                                      ),
                                    );
                                  },
                                  icon: const Icon(LucideIcons.plus),
                                  label: const Text("Add Task"),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Task List
                        StreamBuilder<List<Task>>(
                          stream: tasksStream,
                          builder: (context, taskSnapshot) {
                            if (!taskSnapshot.hasData)
                              return const SliverToBoxAdapter(
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            final tasks = taskSnapshot.data!;
                            if (tasks.isEmpty) {
                              return const SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(
                                  child: Text("No tasks yet. Get started!"),
                                ),
                              );
                            }
                            return SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final task = tasks[index];
                                return _TaskItem(
                                  task: task,
                                  ref: ref,
                                  project: currentProject,
                                );
                              }, childCount: tasks.length),
                            );
                          },
                        ),

                        const SliverPadding(
                          padding: EdgeInsets.only(bottom: 80),
                        ), // Bottom padding
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProgressCard(
    BuildContext context,
    Project project,
    List<Task> tasks,
  ) {
    final progress = project.calculateProgress(tasks);
    final percent = (progress * 100).toStringAsFixed(0);

    return BentoCard(
      child: Row(
        children: [
          CircularProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            strokeCap: StrokeCap.round,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "$percent%",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${tasks.where((t) => t.isCompleted).length}/${tasks.length} Completed",
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyCard(BuildContext context, Project project) {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(LucideIcons.clock, color: project.urgencyColor),
              const SizedBox(width: 8),
              Text("Deadline", style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            project.urgencyText,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: project.urgencyColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            project.deadline?.toString().split(' ')[0] ?? '-',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceCard(BuildContext context, Project project) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProjectInvoicesScreen(
              projectId: project.id,
              projectName: project.name,
            ),
          ),
        );
      },
      child: BentoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.dollarSign, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      "Finance",
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => _showAddInvoiceDialog(context, project.id),
                  icon: const Icon(LucideIcons.plusCircle, size: 16),
                  tooltip: 'Create Invoice',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Financial Overview", // Replaced static text with generic title, as logic now uses Stream
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              "Budget: Rp ${project.totalBudget.toStringAsFixed(0)}",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechStackCard(BuildContext context, Project project) {
    final techs = project.parsedTechStack;
    if (techs.isEmpty) return const SizedBox.shrink();

    return BentoCard(
      title: "Tech Stack",
      icon: LucideIcons.code,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: techs
            .map(
              (t) => Chip(
                label: Text(t, style: const TextStyle(fontSize: 12)),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            )
            .toList(),
      ),
    );
  }

  void _showAddInvoiceDialog(BuildContext context, String projectId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          AddEditInvoiceSheet(preselectedProjectId: projectId),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
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
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await ref.read(projectRepositoryProvider).deleteProject(project.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class _SidePanel extends StatelessWidget {
  final Project project;
  const _SidePanel({required this.project});

  @override
  Widget build(BuildContext context) {
    final techs = project.parsedTechStack;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(
          left: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Details", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),

          if (techs.isNotEmpty) ...[
            Text("Tech Stack", style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: techs.map((t) => Chip(label: Text(t))).toList(),
            ),
            const Divider(height: 32),
          ],

          Text("Actions", style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(LucideIcons.fileText),
            title: const Text("Invoices"),
            subtitle: const Text("View & Manage"),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: Theme.of(context).colorScheme.surface,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProjectInvoicesScreen(
                    projectId: project.id,
                    projectName: project.name,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(LucideIcons.shield),
            title: const Text("Open Vault"),
            subtitle: const Text("View Secrets"),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: Theme.of(context).colorScheme.surface,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VaultScreen(categoryFilter: project.name),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final int status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;
    switch (status) {
      case 0:
        text = "Planning";
        color = Colors.blue;
        break;
      case 1:
        text = "Active";
        color = Colors.orange;
        break;
      case 2:
        text = "Testing";
        color = Colors.purple;
        break;
      case 3:
        text = "Completed";
        color = Colors.green;
        break;
      default:
        text = "Unknown";
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final Task task;
  final WidgetRef ref;
  final Project project;

  const _TaskItem({
    required this.task,
    required this.ref,
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
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
          ref.read(projectRepositoryProvider).updateTask(updatedTask);
        },
      ),
      title: Text(
        task.title,
        style: TextStyle(
          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          color: task.isCompleted
              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
              : null,
        ),
      ),
      subtitle: task.description != null && task.description!.isNotEmpty
          ? Text(task.description!)
          : null,
      trailing: IconButton(
        icon: const Icon(LucideIcons.trash2, size: 16),
        onPressed: () async {
          // ... delete logic existing ...
          ref.read(projectRepositoryProvider).deleteTask(task.id);
        },
      ),
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (_) =>
              AddEditTaskBottomSheet(projectId: project.id, task: task),
        );
      },
    );
  }
}
