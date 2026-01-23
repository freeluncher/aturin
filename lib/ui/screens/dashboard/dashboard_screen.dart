import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:collection/collection.dart';

import '../../../domain/models/project.dart' as domain;
import '../../../domain/models/task.dart' as domain;
import '../../../domain/models/invoice.dart' as domain;
import '../../../domain/logic/project_analytics.dart'; // Logic Extension

import '../../../core/providers.dart';
import '../../widgets/bento_card.dart';
import '../projects/project_list_screen.dart';
import '../tasks/task_list_screen.dart';
import '../projects/add_edit_project_screen.dart';
import '../vault/vault_screen.dart';
import '../../widgets/connectivity_indicator.dart';
import '../tasks/add_edit_task_bottom_sheet.dart';
import '../financial/financial_screen.dart';
import '../projects/project_detail_screen.dart';
import '../../../core/providers/dashboard_config_provider.dart';
import 'customize_dashboard_sheet.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 900) {
              return _DesktopLayout(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() => _selectedIndex = index);
                },
              );
            } else {
              return _MobileLayout(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() => _selectedIndex = index);
                },
              );
            }
          },
        ),
        const ConnectivityIndicator(),
      ],
    );
  }
}

class _DesktopLayout extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const _DesktopLayout({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 12.0,
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/aturin-logo.png',
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  FloatingActionButton.extended(
                    heroTag: 'desktop_nav_fab',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddEditProjectScreen(),
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.plus),
                    label: const Text('Proyek Baru'),
                    elevation: 0,
                  ),
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(LucideIcons.layoutDashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(LucideIcons.folder),
                label: Text('Projects'),
              ),
              NavigationRailDestination(
                icon: Icon(LucideIcons.checkSquare),
                label: Text('Tasks'),
              ),
              NavigationRailDestination(
                icon: Icon(LucideIcons.banknote),
                label: Text('Financial'),
              ),
              NavigationRailDestination(
                icon: Icon(LucideIcons.shield),
                label: Text('Brankas'),
              ),
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: IconButton(
                    icon: const Icon(LucideIcons.logOut),
                    tooltip: 'Logout',
                    onPressed: () async {
                      final auth = ref.read(authRepositoryProvider);
                      final db = ref.read(databaseProvider);
                      await db.clearAllData();
                      await auth.signOut();
                    },
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: _buildContent(selectedIndex)),
        ],
      ),
    );
  }

  Widget _buildContent(int index) {
    switch (index) {
      case 0:
        return _DashboardHome();
      case 1:
        return const ProjectListScreen();
      case 2:
        return const TaskListScreen();
      case 3:
        return const FinancialScreen();
      case 4:
        return const VaultScreen();
      default:
        return _DashboardHome();
    }
  }
}

class _MobileLayout extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const _MobileLayout({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/aturin-logo.png',
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            const Text('Atur.in'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            tooltip: 'Sync Now',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Syncing in background...')),
              );
              ref.read(syncServiceProvider).syncUp();
            },
          ),
          // Customize Action
          if (selectedIndex == 0)
            IconButton(
              icon: const Icon(LucideIcons.slidersHorizontal),
              tooltip: 'Customize Dashboard',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const CustomizeDashboardSheet(),
                );
              },
            ),
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () async {
              final auth = ref.read(authRepositoryProvider);
              final db = ref.read(databaseProvider);
              await db.clearAllData();
              await auth.signOut();
            },
          ),
        ],
      ),
      floatingActionButton: selectedIndex == 0 || selectedIndex == 1
          ? FloatingActionButton(
              heroTag: 'mobile_dashboard_fab',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => const AddEditProjectScreen(),
                  ),
                );
              },
              child: const Icon(LucideIcons.plus),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(LucideIcons.layoutDashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.folder),
            label: 'Projects',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.checkSquare),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.banknote),
            label: 'Finance',
          ),
          NavigationDestination(icon: Icon(LucideIcons.shield), label: 'Vault'),
        ],
      ),
      body: _buildContent(selectedIndex),
    );
  }

  Widget _buildContent(int index) {
    switch (index) {
      case 0:
        return _DashboardHome();
      case 1:
        return const ProjectListScreen();
      case 2:
        return const TaskListScreen();
      case 3:
        return const FinancialScreen();
      case 4:
        return const VaultScreen();
      default:
        return _DashboardHome();
    }
  }
}

class _DashboardHome extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch streams
    final allProjects = ref.watch(projectsStreamProvider);
    final allTasks = ref.watch(allTasksStreamProvider);
    final allInvoices = ref.watch(allInvoicesStreamProvider); // Watch Invoices
    final isOnlineAsync = ref.watch(connectivityStreamProvider);
    final isOnline = isOnlineAsync.value ?? false;

    return RefreshIndicator(
      onRefresh: () async {
        // Invalidate all data providers to trigger refresh
        ref.invalidate(projectsStreamProvider);
        ref.invalidate(allTasksStreamProvider);
        ref.invalidate(allInvoicesStreamProvider);
        ref.invalidate(connectivityStreamProvider);

        // Wait a bit for streams to update
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: allProjects.when(
        data: (projects) {
          return allTasks.when(
            data: (tasks) {
              return allInvoices.when(
                data: (invoices) {
                  return _buildDashboardContent(
                    context,
                    ref, // Pass ref to function
                    projects,
                    tasks,
                    invoices,
                    isOnline,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) =>
                    Center(child: Text('Error loading invoices: $e')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error loading tasks: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading projects: $e')),
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    WidgetRef ref, // Added ref parameter
    List<domain.Project> projects,
    List<domain.Task> tasks,
    List<domain.Invoice> invoices,
    bool isOnline,
  ) {
    final theme = Theme.of(context);
    final activeProjects = projects
        .where((p) => !p.isDeleted && p.status != 3)
        .toList();

    // --- 0. Today's Tasks Logic ---
    final todayTasks =
        tasks.where((t) {
          if (t.isCompleted || t.isDeleted || t.dueDate == null) return false;
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final taskDate = DateTime(
            t.dueDate!.year,
            t.dueDate!.month,
            t.dueDate!.day,
          );
          return taskDate.isAtSameMomentAs(today);
        }).toList()..sort(
          (a, b) => b.priority.compareTo(a.priority),
        ); // High priority first

    // --- 1. Featured Project Logic ---
    domain.Project? featuredProject;
    double maxUrgency = -999;

    for (var p in activeProjects) {
      final pTasks = tasks.where((t) => t.projectId == p.id).toList();
      final urgency = p.getUrgencyScore(pTasks);
      if (urgency > maxUrgency) {
        maxUrgency = urgency;
        featuredProject = p;
      }
    }

    // Default project for Quick Add (Featured -> First Active -> First Available)
    final defaultProjectId =
        featuredProject?.id ??
        (activeProjects.isNotEmpty
            ? activeProjects.first.id
            : (projects.isNotEmpty ? projects.first.id : null));

    // --- 2. Financial Overview Logic ---
    double totalEarned = 0;
    double totalPending = 0;
    double totalCollected = 0;
    double outstanding = 0;

    for (var p in projects.where((p) => !p.isDeleted)) {
      final pTasks = tasks.where((t) => t.projectId == p.id).toList();
      final pInvoices = invoices.where((i) => i.projectId == p.id).toList();
      final financials = p.getFinancials(pTasks, invoices: pInvoices);

      totalEarned += financials.earned;
      totalPending += financials.pending;
      totalCollected += financials.collected;
      outstanding += financials.outstanding;
    }

    // --- 3. Workload Summary Logic ---
    final pendingTasksCount = tasks
        .where((t) => !t.isCompleted && !t.isDeleted)
        .length;
    final completedTasksCount = tasks
        .where((t) => t.isCompleted && !t.isDeleted)
        .length;

    // --- 4. Connectivity Status ---
    final syncStatusText = isOnline ? 'Terhubung ke Cloud' : 'Mode Offline';
    final syncColor = isOnline ? Colors.green : Colors.grey;
    final syncIcon = isOnline ? LucideIcons.cloud : LucideIcons.cloudOff;

    // Responsive Layout Decision
    return LayoutBuilder(
      builder: (context, box) {
        final isDesktop = box.maxWidth > 900;

        // --- Widget Construction ---

        // Featured Card
        Widget featuredCard;
        if (featuredProject != null) {
          final pTasks = tasks
              .where((t) => t.projectId == featuredProject!.id)
              .toList();
          final health = featuredProject.getHealth(pTasks);

          // Health Badge
          Color healthColor;
          String healthText;
          switch (health) {
            case ProjectHealthStatus.onTrack:
              healthColor = Colors.green;
              healthText = 'On Track';
              break;
            case ProjectHealthStatus.atRisk:
              healthColor = Colors.orange;
              healthText = 'At Risk';
              break;
            case ProjectHealthStatus.behindSchedule:
              healthColor = Colors.red;
              healthText = 'Behind';
              break;
          }

          // Remaining Days Logic
          int remainingDays = 0;
          bool isCritical = false;
          if (featuredProject.deadline != null) {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            remainingDays = featuredProject.deadline!.difference(today).inDays;
            if (remainingDays < 3 && remainingDays >= 0) isCritical = true;
          }

          final deadlineText = featuredProject.deadline == null
              ? 'No Deadline'
              : (remainingDays < 0
                    ? 'Overdue ${remainingDays.abs()} hari'
                    : 'Sisa $remainingDays Hari');

          final deadlineColor = (remainingDays < 0 || isCritical)
              ? theme.colorScheme.error
              : theme.colorScheme.onSurfaceVariant;

          featuredCard = BentoCard(
            title: 'Featured Project',
            icon: LucideIcons.star,
            // Phase 3: Urgency-based elevation and border
            elevation: _getProjectUrgencyElevation(featuredProject, pTasks),
            borderColor: _isProjectCritical(featuredProject)
                ? theme.colorScheme.error
                : null,
            borderWidth: _isProjectCritical(featuredProject) ? 2.0 : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  featuredProject.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: healthColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: healthColor),
                      ),
                      child: Text(
                        healthText,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: healthColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(LucideIcons.clock, size: 14, color: deadlineColor),
                    const SizedBox(width: 4),
                    Text(
                      deadlineText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: deadlineColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Phase 3: Overdue badge
                    if (remainingDays < 0) ...[
                      const SizedBox(width: 8),
                      _buildOverdueBadge(context, remainingDays.abs()),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: pTasks.isEmpty
                      ? 0
                      : pTasks.where((t) => t.isCompleted).length /
                            pTasks.length,
                  borderRadius: BorderRadius.circular(4),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${pTasks.where((t) => t.isCompleted).length} / ${pTasks.length} Tasks Completed',
                  style: theme.textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProjectDetailScreen(project: featuredProject!),
                          ),
                        );
                      },
                      icon: const Icon(LucideIcons.eye, size: 16),
                      label: const Text('View Details'),
                    ),
                  ],
                ),
              ],
            ),
          );
        } else {
          featuredCard = BentoCard(
            title: 'Featured Project',
            icon: LucideIcons.star,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.folderPlus,
                    size: 48,
                    color: theme.colorScheme.outline.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No Active Projects',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddEditProjectScreen(),
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('Create Project'),
                  ),
                ],
              ),
            ),
          );
        }

        // Today's Tasks Card
        final displayTasks = isDesktop
            ? (todayTasks.length > 5 ? todayTasks.take(5).toList() : todayTasks)
            : (todayTasks.length > 3
                  ? todayTasks.take(3).toList()
                  : todayTasks);
        final hasMore = isDesktop
            ? todayTasks.length > 5
            : todayTasks.length > 3;

        // Phase 3: Calculate overdue tasks count
        final overdueTasksCount = todayTasks
            .where(
              (t) =>
                  !t.isCompleted &&
                  t.dueDate != null &&
                  t.dueDate!.isBefore(DateTime.now()),
            )
            .length;

        final todayTasksCard = BentoCard(
          title: "Today's Tasks",
          icon: LucideIcons.calendarCheck,
          // Phase 3: Show badge if there are overdue tasks
          trailing: overdueTasksCount > 0
              ? _buildSmallBadge(context, overdueTasksCount)
              : null,
          child: todayTasks.isEmpty
              // Phase 3: Improved empty state
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.checkCircle2,
                        size: 48,
                        color: Colors.green.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All Caught Up!',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.outline,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No tasks due today',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayTasks.length + (hasMore ? 1 : 0),
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (index == displayTasks.length) {
                      // "View All" footer
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextButton.icon(
                          onPressed: () {
                            // Navigate to Tasks tab (index 2)
                            // Need to access parent state
                            // Since we're in a nested widget, we'll navigate to TaskListScreen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TaskListScreen(),
                              ),
                            );
                          },
                          icon: const Icon(LucideIcons.arrowRight, size: 16),
                          label: Text('View All ${todayTasks.length} Tasks'),
                        ),
                      );
                    }
                    final t = displayTasks[index];
                    Color priorityColor;
                    switch (t.priority) {
                      case 2:
                        priorityColor = Colors.red;
                        break;
                      case 0:
                        priorityColor = Colors.green;
                        break;
                      default:
                        priorityColor = Colors.orange;
                    }
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      leading: Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: priorityColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      title: Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        projects
                                .firstWhereOrNull((p) => p.id == t.projectId)
                                ?.name ??
                            '-',
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: Checkbox(
                        value: t.isCompleted,
                        onChanged: (val) async {
                          if (val != null) {
                            try {
                              // Capture repository before async gap
                              final repository = ref.read(
                                projectRepositoryProvider,
                              );
                              final updated = t.copyWith(isCompleted: val);
                              await repository.updateTask(updated);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      val ? 'Task completed!' : 'Task reopened',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to update task: $e'),
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.error,
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
        );

        // Financial Card (Cash Flow Overview)
        final financialCard = InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FinancialScreen()),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: BentoCard(
            title: 'Cash Flow Overview',
            icon: LucideIcons.trendingUp,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Income vs Budget',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatCurrency(totalCollected),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      'of ${_formatCurrency(totalEarned + totalPending)}', // Using Total Budget approximation
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: (totalEarned + totalPending) > 0
                      ? (totalCollected / (totalEarned + totalPending))
                      : 0,
                  borderRadius: BorderRadius.circular(4),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        LucideIcons.alertCircle,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Siap Ditagih',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        Text(
                          _formatCurrency(outstanding),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

        // Workload Card
        final workloadCard = BentoCard(
          title: 'Workload Summary',
          icon: LucideIcons.barChart2,
          trailing: IconButton(
            icon: const Icon(LucideIcons.plusCircle, size: 20),
            tooltip: 'Quick Add Task',
            onPressed: defaultProjectId != null
                ? () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) =>
                          AddEditTaskBottomSheet(projectId: defaultProjectId),
                    );
                  }
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                '$pendingTasksCount',
                'Pending',
                Colors.orange,
              ),
              Container(
                width: 1,
                height: 40,
                color: theme.colorScheme.outlineVariant,
              ),
              _buildStatItem(
                context,
                '$completedTasksCount',
                'Done',
                Colors.green,
              ),
            ],
          ),
        );

        // Sync Status Bar
        final syncBar = Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: syncColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: syncColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(syncIcon, size: 16, color: syncColor),
              const SizedBox(width: 8),
              Text(
                syncStatusText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: syncColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (!isOnline)
                Text(
                  'Data disimpan lokal',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
            ],
          ),
        );

        // Dynamic Layout Logic
        final config = ref.watch(dashboardConfigProvider);
        final widgetMap = {
          'featured_project': SizedBox(
            height: isDesktop ? null : 240,
            child: featuredCard,
          ),
          'todays_tasks': SizedBox(
            height: isDesktop ? null : (todayTasks.isEmpty ? 200 : 250),
            child: todayTasksCard,
          ),
          'financial_overview': SizedBox(
            height: isDesktop ? null : 210,
            child: financialCard,
          ),
          'workload_summary': SizedBox(
            height: isDesktop ? null : 160,
            child: workloadCard,
          ),
        };

        // Desktop Layout (Bento Grid)
        if (isDesktop) {
          final isVisible = config.visibleSectionIds;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                StaggeredGrid.count(
                  crossAxisCount: 3, // 3 columns
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 24,
                  children: [
                    // Featured Project: Big (2x2)
                    if (isVisible.contains('featured_project'))
                      StaggeredGridTile.count(
                        crossAxisCellCount: 2,
                        mainAxisCellCount: 1,
                        child: featuredCard,
                      ),
                    // Today's Tasks: Medium (1x2)
                    if (isVisible.contains('todays_tasks'))
                      StaggeredGridTile.count(
                        crossAxisCellCount: 1,
                        mainAxisCellCount: 1,
                        child: todayTasksCard,
                      ),
                    // Financial: Medium (1x1)
                    if (isVisible.contains('financial_overview'))
                      StaggeredGridTile.count(
                        crossAxisCellCount: 1,
                        mainAxisCellCount: 1,
                        child: financialCard,
                      ),
                    // Workload: Medium (1x1)
                    if (isVisible.contains('workload_summary'))
                      StaggeredGridTile.count(
                        crossAxisCellCount: 1,
                        mainAxisCellCount: 1,
                        child: workloadCard,
                      ),
                    // Sync: Full Width (3x0.3)
                    StaggeredGridTile.count(
                      crossAxisCellCount: 3,
                      mainAxisCellCount: 0.3,
                      child: syncBar,
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        // Mobile Layout (Dynamic List)
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Render Visible Items in Order
              for (final id in config.visibleSectionIds) ...[
                if (widgetMap.containsKey(id)) ...[
                  widgetMap[id]!,
                  const SizedBox(height: 16),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return amount.toStringAsFixed(0);
  }

  // Phase 3: Urgency-based elevation
  double _getProjectUrgencyElevation(
    domain.Project? project,
    List<domain.Task> tasks,
  ) {
    if (project == null || project.deadline == null) return 2.0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final remainingDays = project.deadline!.difference(today).inDays;

    if (remainingDays < 0) return 8.0; // Overdue - highest elevation
    if (remainingDays < 3) return 6.0; // Critical (< 3 days)
    if (remainingDays < 7) return 4.0; // Warning (< 7 days)
    return 2.0; // Normal
  }

  // Phase 3: Check if project is critical (for border color)
  bool _isProjectCritical(domain.Project? project) {
    if (project == null || project.deadline == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final remainingDays = project.deadline!.difference(today).inDays;

    return remainingDays < 3; // Critical if < 3 days or overdue
  }

  // Phase 3: Overdue badge widget
  Widget _buildOverdueBadge(BuildContext context, int overdueCount) {
    if (overdueCount <= 0) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.error,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.alertCircle, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '$overdueCount Day${overdueCount > 1 ? "s" : ""} Overdue',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Phase 3: Small badge for card trailing (task count)
  Widget _buildSmallBadge(BuildContext context, int count) {
    if (count <= 0) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.error,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
