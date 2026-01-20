import '../models/invoice.dart';

abstract class InvoiceRepository {
  Stream<List<Invoice>> getAllInvoices();
  Stream<List<Invoice>> getInvoicesByProject(String projectId);
  Future<void> createInvoice(Invoice invoice);
  Future<void> updateInvoice(Invoice invoice);
  Future<void> deleteInvoice(String id);
  Future<Invoice?> getInvoiceById(String id);
}
