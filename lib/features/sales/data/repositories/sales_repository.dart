import 'package:drift/drift.dart';

import '../../../../database/app_database.dart';

class SalesRepository {
  SalesRepository(this._db);

  final AppDatabase _db;

  Stream<List<Sale>> watchAll() {
    return (_db.select(_db.sales)
          ..orderBy([(t) => OrderingTerm.desc(t.saleDate)]))
        .watch();
  }

  Stream<List<Sale>> search({
    String? query,
    DateTime? from,
    DateTime? to,
  }) {
    if ((query == null || query.trim().isEmpty) && from == null && to == null) {
      return watchAll();
    }
    return (_db.select(_db.sales)
          ..where((t) {
            Expression<bool> cond = const Constant(true);
            if (query != null && query.trim().isNotEmpty) {
              final q = query.trim().toLowerCase();
              cond = cond & t.invoiceNumber.lower().like('%$q%');
            }
            if (from != null) {
              cond = cond & t.saleDate.isBiggerOrEqualValue(from);
            }
            if (to != null) {
              final end = DateTime(to.year, to.month, to.day, 23, 59, 59);
              cond = cond & t.saleDate.isSmallerOrEqualValue(end);
            }
            return cond;
          })
          ..orderBy([(t) => OrderingTerm.desc(t.saleDate)]))
        .watch();
  }

  Future<Sale?> getById(int id) async {
    return (_db.select(_db.sales)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<SaleItem>> getSaleItems(int saleId) async {
    return (_db.select(_db.saleItems)
          ..where((t) => t.saleId.equals(saleId)))
        .get();
  }

  Future<String?> getLastInvoiceNumber() async {
    final last = await (_db.select(_db.sales)
          ..orderBy([(t) => OrderingTerm.desc(t.id)])
          ..limit(1))
        .getSingleOrNull();
    return last?.invoiceNumber;
  }

  Future<int> getNextInvoiceSequence() async {
    final last = await getLastInvoiceNumber();
    if (last == null) return 1;
    final parts = last.split('-');
    if (parts.length >= 3) {
      final seq = int.tryParse(parts.last);
      if (seq != null) return seq + 1;
    }
    return 1;
  }
}
