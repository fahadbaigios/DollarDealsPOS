import 'package:drift/drift.dart';

import '../../../../database/app_database.dart';

class ReceiptsRepository {
  ReceiptsRepository(this._db);

  final AppDatabase _db;

  Future<Receipt?> getBySaleId(int saleId) async {
    return (_db.select(_db.receipts)
          ..where((t) => t.saleId.equals(saleId)))
        .getSingleOrNull();
  }

  Future<void> incrementPrintedCount(int saleId) async {
    final receipt = await getBySaleId(saleId);
    if (receipt == null) return;
    final now = DateTime.now();
    await (_db.update(_db.receipts)
          ..where((t) => t.saleId.equals(saleId)))
        .write(
      ReceiptsCompanion(
        printedCount: Value(receipt.printedCount + 1),
        lastPrintedAt: Value(now),
      ),
    );
  }

  Future<Receipt> getOrCreateForSale(int saleId, String receiptContent) async {
    var receipt = await getBySaleId(saleId);
    if (receipt == null) {
      await _db.into(_db.receipts).insert(
            ReceiptsCompanion.insert(
              saleId: saleId,
              receiptContent: receiptContent,
              printedCount: const Value(0),
            ),
          );
      receipt = await getBySaleId(saleId);
    }
    return receipt!;
  }
}
