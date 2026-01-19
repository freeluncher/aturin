import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../widgets/bento_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return const _DesktopLayout();
        } else {
          return const _MobileLayout();
        }
      },
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar Placeholder
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
                  isActive: true,
                ),
                _SidebarItem(icon: LucideIcons.folder, label: 'Projects'),
                _SidebarItem(icon: LucideIcons.checkSquare, label: 'Tasks'),
                const Spacer(),
                _SidebarItem(icon: LucideIcons.settings, label: 'Settings'),
                const SizedBox(height: 32),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
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
                              style: theme.textTheme.displayMedium,
                            ),
                          ),
                        ),
                      ),
                      StaggeredGridTile.count(
                        crossAxisCellCount: 1,
                        mainAxisCellCount: 1,
                        child: BentoCard(
                          title: 'Proyek Aktif',
                          icon: LucideIcons.briefcase,
                          child: Center(
                            child: Text(
                              '5',
                              style: theme.textTheme.displaySmall,
                            ),
                          ),
                        ),
                      ),
                      StaggeredGridTile.count(
                        crossAxisCellCount: 1,
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
                      StaggeredGridTile.count(
                        crossAxisCellCount: 4,
                        mainAxisCellCount: 2,
                        child: BentoCard(
                          title: 'Daftar Tugas Hari Ini',
                          icon: LucideIcons.listTodo,
                          child: ListView(
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
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Atur.in')),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            BentoCard(
              title: 'Pendapatan Bulan Ini',
              icon: LucideIcons.wallet,
              height: 200,
              child: Center(
                child: Text(
                  'Rp 15.000.000',
                  style: theme.textTheme.headlineMedium,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: BentoCard(
                    title: 'Proyek Aktif',
                    icon: LucideIcons.briefcase,
                    height: 150,
                    child: Center(
                      child: Text('5', style: theme.textTheme.headlineSmall),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: BentoCard(
                    title: 'Deadline',
                    icon: LucideIcons.clock,
                    height: 150,
                    child: Center(
                      child: Text(
                        '2 Hari',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            BentoCard(
              title: 'Daftar Tugas Hari Ini',
              icon: LucideIcons.listTodo,
              height: 300,
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
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
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.isActive = false,
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
        tileColor: isActive
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : null,
        onTap: () {},
      ),
    );
  }
}
