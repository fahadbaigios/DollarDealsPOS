import 'package:drift/drift.dart';

import '../../../../database/app_database.dart';
class PurchasesRepository {
  PurchasesRepository(this._db);

  final AppDatabase _db;

  Stream<List<Purchase>> watchAll() {
    return (_db.select(_db.purchases)
          ..orderBy([(t) => OrderingTerm.desc(t.purchaseDate)]))
        .watch();
  }

  Stream<List<Purchase>> search(
    String query, {
    DateTime? from,
    DateTime? to,
  }) {
    if (query.trim().isEmpty && from == null && to == null) {
      return watchAll();
    }

    return (_db.select(_db.purchases)
          ..where((t) {
            Expression<bool> cond = const Constant(true);
            if (query.trim().isNotEmpty) {
              final q = query.trim().toLowerCase();
              cond = cond &
                  (t.invoiceNumber.like('%$q%') | t.notes.like('%$q%'));
            }
            if (from != null) {
              cond = cond & t.purchaseDate.isBiggerOrEqualValue(from);
            }
            if (to != null) {
              final endOfDay =
                  DateTime(to.year, to.month, to.day, 23, 59, 59);
              cond = cond &
                  t.purchaseDate.isSmallerOrEqualValue(endOfDay);
            }
            return cond;
          })
          ..orderBy([(t) => OrderingTerm.desc(t.purchaseDate)]))
        .watch();
  }

  Future<Purchase?> getById(int id) async {
    return (_db.select(_db.purchases)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<PurchaseItem>> getPurchaseItems(int purchaseId) async {
    return (_db.select(_db.purchaseItems)
          ..where((t) => t.purchaseId.equals(purchaseId)))
        .get();
  }

  Future<String?> getLastInvoiceNumber() async {
    final last = await (_db.select(_db.purchases)
          ..where((t) => t.invoiceNumber.isNotNull())
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
