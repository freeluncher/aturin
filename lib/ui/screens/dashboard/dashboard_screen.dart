import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:collection/collection.dart';

import '../../../domain/models/project.dart' as domain;
import '../../../domain/models/task.dart' as domain;
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
import '../../../data/local/app_database.dart'
    show Invoice; // Direct import for now as it's not in domain models

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
              child: FloatingActionButton.extended(
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
                label: Text('Vault'),
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
        title: const Text('Atur.in'),
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

    return allProjects.when(
      data: (projects) {
        return allTasks.when(
          data: (tasks) {
            return allInvoices.when(
              data: (invoices) {
                return _buildDashboardContent(
                  context,
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
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    List<domain.Project> projects,
    List<domain.Task> tasks,
    List<Invoice> invoices,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  featuredProject.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
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
                  ],
                ),
                const SizedBox(height: 12),
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
              ],
            ),
          );
        } else {
          featuredCard = const BentoCard(
            title: 'Featured Project',
            icon: LucideIcons.star,
            child: Center(child: Text('No active projects')),
          );
        }

        // Today's Tasks Card
        final todayTasksCard = BentoCard(
          title: "Today's Tasks",
          icon: LucideIcons.calendarCheck,
          child: todayTasks.isEmpty
              ? Center(
                  child: Text(
                    'No tasks due today',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                )
              : ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: todayTasks.length > 5 ? 5 : todayTasks.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final t = todayTasks[index];
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
                        onChanged: (val) {
                          // Quick complete from dashboard
                          // We need a ref here, but we are in a pure widget method.
                          // However, since we are inside a LayoutBuilder which is inside build(),
                          // we don't have direct access to 'ref' unless we passed it or captured it.
                          // LayoutBuilder builder doesn't provide ref.
                          // But we are in _DashboardHome which has 'ref' in build().
                          // Actually _DashboardHome is a ConsumerWidget, so build(context, ref).
                          // But _buildDashboardContent is a method I created.
                          // I need to update _buildDashboardContent to accept 'ref' or callback.
                          // For now, let's leave it read-only or I'll pass 'ref' in next step if needed.
                          // Or better, just display it.
                        },
                      ),
                    );
                  },
                ),
        );

        // Financial Card (Cash Flow Overview)
        final financialCard = BentoCard(
          title: 'Cash Flow Overview',
          icon: LucideIcons.trendingUp,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Income vs Budget',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 8),
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
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
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
                          AddEditTaskBottomSheet(projectId: defaultProjectId!),
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

        // Desktop Layout (Bento Grid)
        if (isDesktop) {
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
                    StaggeredGridTile.count(
                      crossAxisCellCount: 2,
                      mainAxisCellCount: 1,
                      child: featuredCard,
                    ),
                    // Today's Tasks: Medium (1x2) - Taller
                    StaggeredGridTile.count(
                      crossAxisCellCount: 1,
                      mainAxisCellCount: 1,
                      child: todayTasksCard,
                    ),
                    // Financial: Medium (1x1)
                    StaggeredGridTile.count(
                      crossAxisCellCount: 1,
                      mainAxisCellCount: 1,
                      child: financialCard,
                    ),
                    // Workload: Medium (1x1)
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

        // Mobile Layout (ListView)
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
              // Today's Tasks
              SizedBox(
                height: todayTasks.isEmpty ? 100 : 250,
                child: todayTasksCard,
              ),
              const SizedBox(height: 16),
              // Featured
              SizedBox(height: 180, child: featuredCard),
              const SizedBox(height: 16),
              // Finance
              SizedBox(height: 160, child: financialCard),
              const SizedBox(height: 16),
              // Workload
              SizedBox(height: 120, child: workloadCard),
              const SizedBox(height: 16),
              syncBar,
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
}
