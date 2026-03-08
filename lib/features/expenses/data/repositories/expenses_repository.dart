import 'package:drift/drift.dart';

import '../../../../database/app_database.dart';

class ExpensesRepository {
  ExpensesRepository(this._db);

  final AppDatabase _db;

  Stream<List<Expense>> watchAll() {
    return (_db.select(_db.expenses)
          ..orderBy([(t) => OrderingTerm.desc(t.expenseDate)]))
        .watch();
  }

  Stream<List<Expense>> watchFiltered({
    String? searchQuery,
    int? categoryId,
    DateTime? from,
    DateTime? to,
  }) {
    return (_db.select(_db.expenses)
          ..where((t) {
            Expression<bool> cond = const Constant(true);
            if (searchQuery != null && searchQuery.trim().isNotEmpty) {
              final q = searchQuery.trim().toLowerCase();
              cond = cond &
                  (t.title.lower().like('%$q%') |
                      (t.notes.isNotNull() & t.notes.like('%$q%')));
            }
            if (categoryId != null) {
              cond = cond & t.expenseCategoryId.equals(categoryId);
            }
            if (from != null) {
              cond = cond & t.expenseDate.isBiggerOrEqualValue(from);
            }
            if (to != null) {
              final end = DateTime(to.year, to.month, to.day, 23, 59, 59);
              cond = cond & t.expenseDate.isSmallerOrEqualValue(end);
            }
            return cond;
          })
          ..orderBy([(t) => OrderingTerm.desc(t.expenseDate)]))
        .watch();
  }

  Future<Expense?> getById(int id) async {
    return (_db.select(_db.expenses)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> create({
    required String title,
    required int expenseCategoryId,
    required double amount,
    required DateTime expenseDate,
    int? paymentMethodId,
    String? referenceNumber,
    String? notes,
    int? createdBy,
  }) async {
    return _db.into(_db.expenses).insert(
          ExpensesCompanion.insert(
            title: Value(title),
            expenseCategoryId: expenseCategoryId,
            amount: amount,
            expenseDate: expenseDate,
            paymentMethodId: paymentMethodId == null
                ? const Value.absent()
                : Value(paymentMethodId),
            referenceNumber: referenceNumber == null || referenceNumber.trim().isEmpty
                ? const Value.absent()
                : Value(referenceNumber.trim()),
            notes: notes == null || notes.trim().isEmpty
                ? const Value.absent()
                : Value(notes.trim()),
            createdBy: createdBy == null ? const Value.absent() : Value(createdBy),
          ),
        );
  }

  Future<bool> update({
    required int id,
    required String title,
    required int expenseCategoryId,
    required double amount,
    required DateTime expenseDate,
    int? paymentMethodId,
    String? referenceNumber,
    String? notes,
  }) async {
    final existing = await getById(id);
    if (existing == null) return false;
    final ref = referenceNumber?.trim();
    final n = notes?.trim();
    return _db.update(_db.expenses).replace(
          existing.copyWith(
            title: title,
            expenseCategoryId: expenseCategoryId,
            amount: amount,
            expenseDate: expenseDate,
            paymentMethodId: Value(paymentMethodId),
            referenceNumber: Value(ref?.isEmpty ?? true ? null : ref),
            notes: Value(n?.isEmpty ?? true ? null : n),
          ).toCompanion(true),
        );
  }

  Future<bool> delete(int id) async {
    final n = await (_db.delete(_db.expenses)
          ..where((t) => t.id.equals(id)))
        .go();
    return n > 0;
  }

  Future<double> getTotalInRange(DateTime from, DateTime to) async {
    final rows = await (_db.select(_db.expenses)
          ..where((t) =>
              t.expenseDate.isBiggerOrEqualValue(from) &
              t.expenseDate.isSmallerOrEqualValue(to)))
        .get();
    return rows.fold<double>(0.0, (sum, e) => sum + e.amount);
  }
}
