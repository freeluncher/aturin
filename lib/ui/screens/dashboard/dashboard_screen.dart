import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/providers.dart';
import '../../widgets/bento_card.dart';
import '../projects/project_list_screen.dart';
import '../tasks/task_list_screen.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: theme.colorScheme.surface,
            child: Column(
              children: [
                const SizedBox(height: 32),
                Text(
                  'Atur.in',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                _SidebarItem(
                  icon: LucideIcons.layoutDashboard,
                  label: 'Dashboard',
                  isActive: selectedIndex == 0,
                  onTap: () => onDestinationSelected(0),
                ),
                _SidebarItem(
                  icon: LucideIcons.folder,
                  label: 'Projects',
                  isActive: selectedIndex == 1,
                  onTap: () => onDestinationSelected(1),
                ),
                _SidebarItem(
                  icon: LucideIcons.checkSquare,
                  label: 'Tasks',
                  isActive: selectedIndex == 2,
                  onTap: () => onDestinationSelected(2),
                ),
                _SidebarItem(
                  icon: LucideIcons.refreshCw,
                  label: 'Sync Data',
                  onTap: () {
                    ref
                        .read(syncServiceProvider)
                        .syncUp()
                        .then((_) => ref.read(syncServiceProvider).syncDown());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Syncing data...')),
                    );
                  },
                ),
                const Spacer(),
                _SidebarItem(
                  icon: LucideIcons.logOut,
                  label: 'Logout',
                  onTap: () async {
                    final auth = ref.read(authRepositoryProvider);
                    final db = ref.read(databaseProvider);
                    await db.clearAllData();
                    await auth.signOut();
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
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
            onPressed: () {
              ref
                  .read(syncServiceProvider)
                  .syncUp()
                  .then((_) => ref.read(syncServiceProvider).syncDown());
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Syncing data...')));
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
            mainAxisSpacing: 24,
            crossAxisSpacing: 24,
            children: [
              StaggeredGridTile.count(
                crossAxisCellCount: 2,
                mainAxisCellCount: 2,
                child: BentoCard(
                  title: 'Pendapatan Bulan Ini',
                  icon: LucideIcons.wallet,
                  child: Center(
                    child: Text(
                      'Rp 15.000.000',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontSize:
                            24, // Adjust for mobile if needed, but displayMedium is responsive often
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              StaggeredGridTile.count(
                crossAxisCellCount: 2,
                mainAxisCellCount: 1,
                child: BentoCard(
                  // We can link this to Projects tab if we had access to controller,
                  // but effectively it's just info for now.
                  // Or we can invoke onDestinationSelected if we passed it down.
                  // For simplicity, let's keep it informational or link via Navigator if separate screen needed.
                  // BUT goal is Tabs. So maybe just Text for now.
                  title: 'Proyek Aktif',
                  icon: LucideIcons.briefcase,
                  child: Center(
                    child: Text('5', style: theme.textTheme.displaySmall),
                  ),
                ),
              ),
              StaggeredGridTile.count(
                crossAxisCellCount: 2,
                mainAxisCellCount: 1,
                child: BentoCard(
                  title: 'Deadline Terdekat',
                  icon: LucideIcons.clock,
                  child: Center(
                    child: Text(
                      '2 Hari',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ),
              // Full width for tasks summary
              StaggeredGridTile.count(
                crossAxisCellCount: 4,
                mainAxisCellCount: 2,
                child: BentoCard(
                  title: 'Daftar Tugas Hari Ini',
                  icon: LucideIcons.listTodo,
                  child: ListView(
                    physics:
                        const NeverScrollableScrollPhysics(), // Nested in single child view
                    children: const [
                      ListTile(
                        title: Text('Revisi Desain App'),
                        leading: Icon(LucideIcons.checkCircle),
                      ),
                      ListTile(
                        title: Text('Meeting Klien A'),
                        leading: Icon(LucideIcons.circle),
                      ),
                      ListTile(
                        title: Text('Push Code Backend'),
                        leading: Icon(LucideIcons.circle),
                      ),
                    ],
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

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isActive ? theme.colorScheme.primary.withOpacity(0.1) : null,
        onTap: onTap ?? () {},
      ),
    );
  }
}
