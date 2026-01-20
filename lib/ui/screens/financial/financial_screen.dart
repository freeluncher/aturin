import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/invoice.dart' as domain;
import 'add_edit_invoice_sheet.dart'; // Added
import '../../../core/providers.dart';

class FinancialScreen extends ConsumerStatefulWidget {
  const FinancialScreen({super.key});

  @override
  ConsumerState<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends ConsumerState<FinancialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    // TODO: Implement advanced summary logic (Month vs Month)
    // For now showing the same overall stats
    final invoicesAsync = ref.watch(allInvoicesStreamProvider);

    return invoicesAsync.when(
      data: (invoices) {
        double totalPaid = 0;
        double totalUnpaid = 0;

        for (var inv in invoices) {
          if (inv.status == 'Paid') {
            totalPaid += inv.amount;
          } else if (inv.status == 'Sent') {
            totalUnpaid += inv.amount;
          }
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildSummaryCard(
                'Total Revenue (Paid)',
                totalPaid,
                Colors.green,
                LucideIcons.checkCircle,
              ),
              const SizedBox(height: 16),
              _buildSummaryCard(
                'Outstanding (Unpaid)',
                totalUnpaid,
                Colors.orange,
                LucideIcons.alertCircle,
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
        // Sort by due date
        final sortedInvoices = [...invoices];
        sortedInvoices.sort((a, b) => a.dueDate.compareTo(b.dueDate));

        if (sortedInvoices.isEmpty) {
          return const Center(child: Text('No invoices found'));
        }

        return ListView.builder(
          itemCount: sortedInvoices.length,
          itemBuilder: (context, index) {
            final invoice = sortedInvoices[index];
            return _InvoiceListTile(
              invoice: invoice,
              onTap: () => _showAddInvoiceSheet(context, invoice),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

// ...

class _InvoiceListTile extends StatelessWidget {
  final domain.Invoice invoice;
  final VoidCallback onTap;

  const _InvoiceListTile({required this.invoice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy');

    Color statusColor;
    switch (invoice.status) {
      case 'Paid':
        statusColor = Colors.green;
        break;
      case 'Sent':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(LucideIcons.fileText, color: statusColor, size: 20),
        ),
        title: Text(
          invoice.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Due: ${dateFormat.format(invoice.dueDate)}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyFormat.format(invoice.amount),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                invoice.status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
