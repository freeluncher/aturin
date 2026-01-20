import 'package:drift/drift.dart';
import '../../domain/models/invoice.dart' as domain;
import '../local/app_database.dart';

class InvoiceMapper {
  static domain.Invoice toDomain(Invoice driftInvoice) {
    return domain.Invoice(
      id: driftInvoice.id,
      projectId: driftInvoice.projectId,
      title: driftInvoice.title,
      amount: driftInvoice.amount,
      status: driftInvoice.status,
      dueDate: driftInvoice.dueDate,
      createdAt: driftInvoice.createdAt,
      serverId: driftInvoice.serverId,
      isSynced: driftInvoice.isSynced,
      isDeleted: driftInvoice.isDeleted,
    );
  }

  static InvoicesCompanion toCompanion(domain.Invoice invoice) {
    return InvoicesCompanion(
      id: Value(invoice.id),
      projectId: Value(invoice.projectId),
      title: Value(invoice.title),
      amount: Value(invoice.amount),
      status: Value(invoice.status),
      dueDate: Value(invoice.dueDate),
      createdAt: Value(invoice.createdAt),
      serverId: Value(invoice.serverId),
      isSynced: Value(invoice.isSynced),
      isDeleted: Value(invoice.isDeleted),
    );
  }
}
