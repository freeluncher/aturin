import 'package:drift/drift.dart';
import '../../domain/models/invoice.dart' as domain;
import '../../domain/repositories/invoice_repository.dart';
import '../local/app_database.dart';
import '../mappers/invoice_mapper.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final AppDatabase _db;

  InvoiceRepositoryImpl(this._db);

  @override
  Stream<List<domain.Invoice>> getAllInvoices() {
    return (_db.select(_db.invoices)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm(expression: t.dueDate, mode: OrderingMode.asc),
          ]))
        .watch()
        .map((rows) => rows.map(InvoiceMapper.toDomain).toList());
  }

  @override
  Stream<List<domain.Invoice>> getInvoicesByProject(String projectId) {
    return (_db.select(_db.invoices)
          ..where(
            (t) => t.projectId.equals(projectId) & t.isDeleted.equals(false),
          )
          ..orderBy([
            (t) => OrderingTerm(expression: t.dueDate, mode: OrderingMode.asc),
          ]))
        .watch()
        .map((rows) => rows.map(InvoiceMapper.toDomain).toList());
  }

  @override
  Future<void> createInvoice(domain.Invoice invoice) async {
    await _db.into(_db.invoices).insert(InvoiceMapper.toCompanion(invoice));
  }

  @override
  Future<void> updateInvoice(domain.Invoice invoice) async {
    // When updating locally, mark isSynced = false so it syncs up later
    final updatedInvoice = invoice.copyWith(isSynced: false);
    await (_db.update(_db.invoices)..where((t) => t.id.equals(invoice.id)))
        .write(InvoiceMapper.toCompanion(updatedInvoice));
  }

  @override
  Future<void> deleteInvoice(String id) async {
    // Soft delete
    await (_db.update(_db.invoices)..where((t) => t.id.equals(id))).write(
      const InvoicesCompanion(isDeleted: Value(true), isSynced: Value(false)),
    );
  }

  @override
  Future<domain.Invoice?> getInvoiceById(String id) async {
    final driftInvoice = await (_db.select(
      _db.invoices,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    return driftInvoice != null ? InvoiceMapper.toDomain(driftInvoice) : null;
  }
}
