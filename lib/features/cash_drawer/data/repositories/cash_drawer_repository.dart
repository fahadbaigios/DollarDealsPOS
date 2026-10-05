import 'package:drift/drift.dart';

import '../../../../database/app_database.dart';
import '../../domain/cash_drawer_constants.dart';
import '../../domain/models/cash_drawer_summary.dart';

class CashDrawerRepository {
  CashDrawerRepository(this._db);

  static const cashInType = CashDrawerMovementTypes.cashIn;
  static const cashSaleType = CashDrawerMovementTypes.cashSale;
  static const cashOutType = CashDrawerMovementTypes.cashOut;

  final AppDatabase _db;

  Future<CashDrawerSummary> getSummary({DateTime? now}) async {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final tomorrow = today.add(const Duration(days: 1));
    final table = _db.cashDrawerMovements;

    final values = await Future.wait<int>([
      _sumWhere(table.movementType.isIn([cashInType, cashSaleType])),
      _sumWhere(table.movementType.equals(cashOutType)),
      _sumWhere(
        table.movementType.equals(cashSaleType) &
            table.createdAt.isBiggerOrEqualValue(today) &
            table.createdAt.isSmallerThanValue(tomorrow),
      ),
      _sumWhere(
        table.movementType.equals(cashInType) &
            table.createdAt.isBiggerOrEqualValue(today) &
            table.createdAt.isSmallerThanValue(tomorrow),
      ),
      _sumWhere(
        table.movementType.equals(cashOutType) &
            table.createdAt.isBiggerOrEqualValue(today) &
            table.createdAt.isSmallerThanValue(tomorrow),
      ),
    ]);

    return CashDrawerSummary(
      balanceMinor: values[0] - values[1],
      todayCashSalesMinor: values[2],
      todayCashInMinor: values[3],
      todayCashOutMinor: values[4],
    );
  }

  Future<int> _sumWhere(Expression<bool> predicate) async {
    final total = _db.cashDrawerMovements.amountMinor.sum();
    final row =
        await (_db.selectOnly(_db.cashDrawerMovements)
              ..addColumns([total])
              ..where(predicate))
            .getSingle();
    return row.read(total) ?? 0;
  }

  Future<List<CashDrawerMovement>> getRecentActivity({int limit = 100}) {
    return (_db.select(_db.cashDrawerMovements)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  Future<void> addCashIn({required double amount, String? note}) async {
    final amountMinor = _toMinorUnits(amount);
    await _db
        .into(_db.cashDrawerMovements)
        .insert(
          CashDrawerMovementsCompanion.insert(
            movementType: cashInType,
            amountMinor: amountMinor,
            note: _optionalNote(note),
          ),
        );
  }

  Future<void> addCashOut({required double amount, String? note}) {
    final amountMinor = _toMinorUnits(amount);
    return _db.transaction(() async {
      final summary = await getSummary();
      if (amountMinor > summary.balanceMinor) {
        throw StateError('Cash out cannot be more than the drawer balance.');
      }
      await _db
          .into(_db.cashDrawerMovements)
          .insert(
            CashDrawerMovementsCompanion.insert(
              movementType: cashOutType,
              amountMinor: amountMinor,
              note: _optionalNote(note),
            ),
          );
    });
  }

  int _toMinorUnits(double amount) {
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError('Amount must be greater than zero.');
    }
    return (amount * 100).round();
  }

  Value<String> _optionalNote(String? note) {
    final normalized = note?.trim();
    return normalized == null || normalized.isEmpty
        ? const Value.absent()
        : Value(normalized);
  }
}
