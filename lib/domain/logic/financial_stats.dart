import '../models/invoice.dart';

class FinancialStats {
  /// Aggregates paid invoices by day for a specific month.
  /// Returns a map where key is day (1-31) and value is total amount.
  static Map<int, double> getMonthlyStats(
    List<Invoice> invoices,
    int year,
    int month,
  ) {
    final stats = <int, double>{};
    // Initialize all days with 0
    final daysInMonth = DateTime(year, month + 1, 0).day;
    for (var i = 1; i <= daysInMonth; i++) {
      stats[i] = 0.0;
    }

    final paidInvoices = invoices.where((inv) => inv.status == 'Paid');
    for (var inv in paidInvoices) {
      // Use paidAt if available, otherwise createdAt
      // Assuming createdAt is close enough if paidAt is null,
      // but ideally we should track payment date.
      // For now using createdAt as a proxy if needed, or strictly filtering for that month

      // Strict check: Invoice must logically fall in this month.
      // Using dueDate might be more relevant for projections, but for "Revenue" usually it's payment date.
      // Since we don't have paidAt in the model shown previously, let's use createdAt or dueDate.
      // Let's rely on createdAt for "Billed In" logic or assume Paid means it counts.
      // Actually, looking at the model, let's use createdAt to group them into months/years.

      if (inv.createdAt.year == year && inv.createdAt.month == month) {
        final day = inv.createdAt.day;
        stats[day] = (stats[day] ?? 0) + inv.amount;
      }
    }
    return stats;
  }

  /// Aggregates paid invoices by month for a specific year.
  /// Returns a map where key is month (1-12) and value is total amount.
  static Map<int, double> getYearlyStats(List<Invoice> invoices, int year) {
    final stats = <int, double>{};
    for (var i = 1; i <= 12; i++) {
      stats[i] = 0.0;
    }

    final paidInvoices = invoices.where((inv) => inv.status == 'Paid');
    for (var inv in paidInvoices) {
      if (inv.createdAt.year == year) {
        final month = inv.createdAt.month;
        stats[month] = (stats[month] ?? 0) + inv.amount;
      }
    }
    return stats;
  }
}
