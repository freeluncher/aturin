import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/invoice.dart' as domain;
import 'add_edit_invoice_sheet.dart'; // Added
import '../../widgets/invoice_list_tile.dart'; // Shared Widget
import '../../../core/providers.dart';

class FinancialScreen extends ConsumerStatefulWidget {
  const FinancialScreen({super.key});

  @override
  ConsumerState<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends ConsumerState<FinancialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatus = 'All';
  String _searchQuery = '';
  String _sortBy = 'dueDate'; // 'dueDate', 'amount', 'createdAt'
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  bool _isOverdue(domain.Invoice invoice) {
    if (invoice.status == 'Paid') return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return invoice.dueDate.isBefore(today);
  }

  List<domain.Invoice> _filterInvoices(List<domain.Invoice> invoices) {
    var filtered = invoices;

    // Apply status filter
    if (_selectedStatus != 'All') {
      if (_selectedStatus == 'Overdue') {
        filtered = filtered.where((inv) => _isOverdue(inv)).toList();
      } else {
        filtered = filtered
            .where((inv) => inv.status == _selectedStatus)
            .toList();
      }
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((inv) {
        return inv.title.toLowerCase().contains(query) ||
            inv.projectId.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  List<domain.Invoice> _sortInvoices(List<domain.Invoice> invoices) {
    final sorted = [...invoices];
    switch (_sortBy) {
      case 'amount':
        sorted.sort((a, b) => b.amount.compareTo(a.amount)); // High to low
        break;
      case 'createdAt':
        sorted.sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
        ); // Recent first
        break;
      case 'dueDate':
      default:
        sorted.sort((a, b) => a.dueDate.compareTo(b.dueDate)); // Earliest first
    }
    return sorted;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'Invoices'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddInvoiceSheet(context),
        icon: const Icon(LucideIcons.plus),
        label: const Text('Add Invoice'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSummaryTab(ref), _buildInvoicesTab(ref)],
      ),
    );
  }

  void _showAddInvoiceSheet(BuildContext context, [domain.Invoice? invoice]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddEditInvoiceSheet(invoice: invoice),
    );
  }

  Widget _buildSummaryTab(WidgetRef ref) {
    final invoicesAsync = ref.watch(allInvoicesStreamProvider);

    return invoicesAsync.when(
      data: (invoices) {
        double totalPaid = 0;
        double totalUnpaid = 0;
        double totalOverdue = 0;
        int overdueCount = 0;

        for (var inv in invoices) {
          if (inv.status == 'Paid') {
            totalPaid += inv.amount;
          } else if (inv.status == 'Sent') {
            if (_isOverdue(inv)) {
              totalOverdue += inv.amount;
              overdueCount++;
            } else {
              totalUnpaid += inv.amount;
            }
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Overview header
              Row(
                children: [
                  const Icon(LucideIcons.pieChart, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Financial Overview',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${invoices.length} invoices',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSummaryCard(
                'Total Revenue (Paid)',
                totalPaid,
                Colors.green,
                LucideIcons.checkCircle,
              ),
              const SizedBox(height: 16),
              if (overdueCount > 0) ...[
                _buildSummaryCard(
                  'Overdue ($overdueCount)',
                  totalOverdue,
                  Colors.red,
                  LucideIcons.alertTriangle,
                ),
                const SizedBox(height: 16),
              ],
              _buildSummaryCard(
                'Outstanding (Unpaid)',
                totalUnpaid,
                Colors.orange,
                LucideIcons.clock,
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildSummaryCard(
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(amount),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoicesTab(WidgetRef ref) {
    final invoicesAsync = ref.watch(allInvoicesStreamProvider);

    return invoicesAsync.when(
      data: (invoices) {
        if (invoices.isEmpty) {
          return _buildEmptyState();
        }

        final filteredInvoices = _sortInvoices(_filterInvoices(invoices));

        return Column(
          children: [
            // Search bar and sort controls
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search invoices...',
                        prefixIcon: const Icon(LucideIcons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(LucideIcons.x),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: const Icon(LucideIcons.arrowUpDown),
                    tooltip: 'Sort by',
                    onSelected: (value) {
                      setState(() {
                        _sortBy = value;
                      });
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'dueDate',
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.calendar,
                              size: 18,
                              color: _sortBy == 'dueDate'
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Due Date',
                              style: TextStyle(
                                fontWeight: _sortBy == 'dueDate'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'amount',
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.dollarSign,
                              size: 18,
                              color: _sortBy == 'amount'
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Amount',
                              style: TextStyle(
                                fontWeight: _sortBy == 'amount'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'createdAt',
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.clock,
                              size: 18,
                              color: _sortBy == 'createdAt'
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Created Date',
                              style: TextStyle(
                                fontWeight: _sortBy == 'createdAt'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildFilterChips(invoices),
            Expanded(
              child: filteredInvoices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.searchX,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No invoices found',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Try a different search term'
                                : 'Try selecting a different filter',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    )
                  : _buildGroupedInvoiceList(filteredInvoices),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.fileText,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Invoices Yet',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first invoice to start\ntracking your payments',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showAddInvoiceSheet(context),
              icon: const Icon(LucideIcons.plus),
              label: const Text('Create Invoice'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(List<domain.Invoice> allInvoices) {
    final overdueCount = allInvoices.where((inv) => _isOverdue(inv)).length;
    final paidCount = allInvoices.where((inv) => inv.status == 'Paid').length;
    final sentCount = allInvoices.where((inv) => inv.status == 'Sent').length;
    final draftCount = allInvoices.where((inv) => inv.status == 'Draft').length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildFilterChip('All', allInvoices.length),
          const SizedBox(width: 8),
          if (overdueCount > 0)
            _buildFilterChip('Overdue', overdueCount, Colors.red),
          if (overdueCount > 0) const SizedBox(width: 8),
          _buildFilterChip('Sent', sentCount),
          const SizedBox(width: 8),
          _buildFilterChip('Paid', paidCount),
          const SizedBox(width: 8),
          _buildFilterChip('Draft', draftCount),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String status, int count, [Color? accentColor]) {
    final isSelected = _selectedStatus == status;
    final theme = Theme.of(context);

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(status),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.onPrimary.withValues(alpha: 0.3)
                    : (accentColor ?? theme.colorScheme.primary).withValues(
                        alpha: 0.15,
                      ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : (accentColor ?? theme.colorScheme.primary),
                ),
              ),
            ),
          ],
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _selectedStatus = status;
        });
      },
    );
  }

  Widget _buildGroupedInvoiceList(List<domain.Invoice> invoices) {
    // Group invoices by status
    final overdue = <domain.Invoice>[];
    final sent = <domain.Invoice>[];
    final paid = <domain.Invoice>[];
    final draft = <domain.Invoice>[];

    for (var invoice in invoices) {
      if (_isOverdue(invoice)) {
        overdue.add(invoice);
      } else if (invoice.status == 'Sent') {
        sent.add(invoice);
      } else if (invoice.status == 'Paid') {
        paid.add(invoice);
      } else {
        draft.add(invoice);
      }
    }

    // Sort each group by due date
    overdue.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    sent.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    paid.sort(
      (a, b) => b.dueDate.compareTo(a.dueDate),
    ); // Recent first for paid
    draft.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return ListView(
      children: [
        if (overdue.isNotEmpty) ...[
          _buildGroupHeader('Overdue', overdue.length, Colors.red),
          ...overdue.map(
            (inv) => InvoiceListTile(
              invoice: inv,
              onTap: () => _showAddInvoiceSheet(context, inv),
              isOverdue: true,
            ),
          ),
        ],
        if (sent.isNotEmpty) ...[
          _buildGroupHeader('Sent', sent.length, Colors.orange),
          ...sent.map(
            (inv) => InvoiceListTile(
              invoice: inv,
              onTap: () => _showAddInvoiceSheet(context, inv),
            ),
          ),
        ],
        if (paid.isNotEmpty) ...[
          _buildGroupHeader('Paid', paid.length, Colors.green),
          ...paid.map(
            (inv) => InvoiceListTile(
              invoice: inv,
              onTap: () => _showAddInvoiceSheet(context, inv),
            ),
          ),
        ],
        if (draft.isNotEmpty) ...[
          _buildGroupHeader('Draft', draft.length, Colors.grey),
          ...draft.map(
            (inv) => InvoiceListTile(
              invoice: inv,
              onTap: () => _showAddInvoiceSheet(context, inv),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGroupHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ...

// Internal _InvoiceListTile class removed. Please import and use the shared InvoiceListTile widget.
