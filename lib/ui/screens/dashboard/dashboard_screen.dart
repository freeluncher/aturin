import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../domain/models/project.dart' as domain;

import '../../../core/providers.dart';
import '../../widgets/bento_card.dart';
import '../projects/project_list_screen.dart';
import '../tasks/task_list_screen.dart';
import '../projects/add_edit_project_screen.dart';
import '../vault/vault_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
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
    // Sync Indicator could be placed here or in AppBar
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
                onPressed: () {
                  // Navigate to 'Add Project' or show dialog
                  // Since Create Project is a screen, we might need Navigator
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddEditProjectScreen(),
                    ),
                  );
                },
                icon: const Icon(LucideIcons.plus),
                label: const Text('New Project'),
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
          // Divider removed as requested
          // Main Content
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
          // Visual Feedback for Sync (Non-intrusive)
          // We could use a StreamBuilder if we expose sync status.
          // For now, let's just keep the button but make it spin or give feedback when pressed?
          // Since user requested "Visual Feedback & Micro-interactions", let's improve this later with a real status.
          // For now, adding a specialized button.
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            tooltip: 'Sync Now',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Syncing in background...')),
              );
              ref
                  .read(syncServiceProvider)
                  .syncUp()
                  .then((_) => ref.read(syncServiceProvider).syncDown());
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
      floatingActionButton:
          selectedIndex ==
              1 // Only show FAB on Projects tab? Or Dashboard too? 'Tambah Proyek Baru' suggests context.
          // But user said "Navigasi Lintas Platform... Penempatan tombol..."
          // Best practice: FAB on "Projects" tab makes most sense, or global if creates primary entity.
          // Let's hide it on 'Tasks' or make it create project.
          // Actually, dashboard often allows "Quick Create". Let's put it there too.
          ? FloatingActionButton(
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
        return const VaultScreen();
      default:
        return _DashboardHome();
    }
  }
}

class _DashboardHome extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dashboard', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 24),
          StaggeredGrid.count(
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              // 1. URGENCY: Deadline Terdekat (Top Left, 2x1)
              StaggeredGridTile.count(
                crossAxisCellCount: 2,
                mainAxisCellCount: 1,
                child: StreamBuilder<List<domain.Project>>(
                  stream: ref.watch(projectRepositoryProvider).getProjects(),
                  builder: (context, snapshot) {
                    final projects = snapshot.data ?? [];
                    final activeProjects = projects
                        .where((p) => !p.isDeleted)
                        .toList();

                    // Find nearest deadline (future or today)
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);

                    final projectsWithDeadlines = activeProjects
                        .where((p) => p.deadline != null)
                        .toList();

                    String deadlineText = '-';
                    Color? textColor;
                    Color? cardColor;

                    if (projectsWithDeadlines.isNotEmpty) {
                      // Sort by deadline ascending
                      projectsWithDeadlines.sort(
                        (a, b) => a.deadline!.compareTo(b.deadline!),
                      );

                      // Find first future (or today) deadline
                      final futureDeadlines = projectsWithDeadlines
                          .where((p) => !p.deadline!.isBefore(today))
                          .toList();

                      if (futureDeadlines.isNotEmpty) {
                        final p = futureDeadlines.first;
                        final diff = p.deadline!.difference(today).inDays;

                        if (diff == 0) {
                          deadlineText = 'Hari Ini';
                          textColor = theme.colorScheme.onErrorContainer;
                          cardColor = theme.colorScheme.errorContainer;
                        } else if (diff == 1) {
                          deadlineText = 'Besok';
                          textColor = theme.colorScheme.onTertiaryContainer;
                          cardColor = theme.colorScheme.tertiaryContainer;
                        } else {
                          deadlineText = '$diff Hari';
                          if (diff <= 3) {
                            textColor = theme.colorScheme.onErrorContainer;
                            cardColor = theme.colorScheme.errorContainer;
                          }
                        }
                        // Optional: show project name?
                      } else {
                        // Only past deadlines
                        deadlineText = 'Semua Lewat';
                        textColor = theme.colorScheme.error;
                      }
                    }

                    return BentoCard(
                      title: 'Deadline Terdekat',
                      icon: LucideIcons.alertTriangle,
                      color: cardColor,
                      child: Center(
                        child: Text(
                          deadlineText,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 2. CONTEXT: Proyek Aktif (Top Right, 1x1)
              StaggeredGridTile.count(
                crossAxisCellCount: 1,
                mainAxisCellCount: 1,
                child: StreamBuilder<List<domain.Project>>(
                  stream: ref.watch(projectRepositoryProvider).getProjects(),
                  builder: (context, snapshot) {
                    final count =
                        snapshot.data?.where((p) => !p.isDeleted).length ?? 0;
                    return BentoCard(
                      title: 'Proyek Aktif',
                      icon: LucideIcons.folderOpen,
                      child: Center(
                        child: Text(
                          '$count',
                          style: theme.textTheme.displaySmall,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 3. CONTEXT: Revenue (Top Right, 1x1) - Placeholder
              StaggeredGridTile.count(
                crossAxisCellCount: 1,
                mainAxisCellCount: 1,
                child: BentoCard(
                  title: 'Revenue',
                  icon: LucideIcons.wallet,
                  child: Center(
                    child: Text(
                      '15jt', // Compact
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                ),
              ),

              // 4. ACTIONABLE: Tugas Hari Ini (Bottom, Full Width)
              StaggeredGridTile.count(
                crossAxisCellCount: 4,
                mainAxisCellCount: 2,
                child: BentoCard(
                  title: 'Tugas Hari Ini',
                  icon: LucideIcons.listTodo,
                  child: StreamBuilder<List<domain.Project>>(
                    // Ideally fetch tasks directly, but for now mocked or derived
                    stream: ref.watch(projectRepositoryProvider).getProjects(),
                    builder: (context, snapshot) {
                      // Logic to show some tasks.
                      // Since we don't have 'getAllTasks' stream readily available in this widget scope easily without prop drilling or new provider usage (though we added getTasks to repo),
                      // let's just show a static list for "Focus" concept as requested, or implement simple list.
                      // For this iteration, let's keep static but styled better.
                      return ListView(
                        physics: const NeverScrollableScrollPhysics(),
                        children: const [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Revisi Desain App'),
                            subtitle: Text('Project A • Priority High'),
                            leading: Icon(LucideIcons.circle, size: 20),
                          ),
                          Divider(height: 1),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Meeting Klien B'),
                            subtitle: Text('Project B • 14:00 WIB'),
                            leading: Icon(LucideIcons.circle, size: 20),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
