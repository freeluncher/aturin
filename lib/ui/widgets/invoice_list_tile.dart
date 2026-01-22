import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../domain/models/invoice.dart' as domain;

class InvoiceListTile extends StatelessWidget {
  final domain.Invoice invoice;
  final VoidCallback onTap;
  final bool isOverdue;

  const InvoiceListTile({
    super.key,
    required this.invoice,
    required this.onTap,
    this.isOverdue = false,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy');

    Color statusColor;
    if (isOverdue) {
      statusColor = Colors.red;
    } else {
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
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isOverdue ? 2 : 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isOverdue
              ? Colors.red
              : Theme.of(context).colorScheme.outlineVariant,
          width: isOverdue ? 2 : 1,
        ),
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
            if (isOverdue)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'OVERDUE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
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
