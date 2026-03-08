import 'package:drift/drift.dart';

import '../../../../database/app_database.dart';

class ExpenseCategoriesRepository {
  ExpenseCategoriesRepository(this._db);

  final AppDatabase _db;

  Stream<List<ExpenseCategory>> watchAll() {
    return (_db.select(_db.expenseCategories)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<List<ExpenseCategory>> getAll() async {
    return (_db.select(_db.expenseCategories)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<List<ExpenseCategory>> getActive() async {
    return (_db.select(_db.expenseCategories)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<ExpenseCategory?> getById(int id) async {
    return (_db.select(_db.expenseCategories)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<ExpenseCategory?> getByName(String name, {int? excludeId}) async {
    final n = name.trim().toLowerCase();
    return (_db.select(_db.expenseCategories)
          ..where((t) =>
              t.name.lower().equals(n) &
              (excludeId == null ? const Constant(true) : t.id.isNotValue(excludeId))))
        .getSingleOrNull();
  }

  Future<int> create(String name, {String? description}) async {
    return _db.into(_db.expenseCategories).insert(
          ExpenseCategoriesCompanion.insert(
            name: name,
            description: description == null ? const Value.absent() : Value(description),
          ),
        );
  }

  Future<bool> update(int id, String name, {String? description, bool? isActive}) async {
    final existing = await getById(id);
    if (existing == null) return false;
    return _db.update(_db.expenseCategories).replace(
          existing.copyWith(
            name: name,
            description: Value(description ?? existing.description),
            isActive: isActive ?? existing.isActive,
          ).toCompanion(true),
        );
  }

  Future<bool> setActiveStatus(int id, bool isActive) async {
    final existing = await getById(id);
    if (existing == null) return false;
    return _db.update(_db.expenseCategories).replace(
          existing.copyWith(isActive: isActive).toCompanion(true),
        );
  }

  Future<bool> delete(int id) async {
    final used = await (_db.select(_db.expenses)
          ..where((t) => t.expenseCategoryId.equals(id)))
        .get();
    if (used.isNotEmpty) return false;
    final n = await (_db.delete(_db.expenseCategories)
          ..where((t) => t.id.equals(id)))
        .go();
    return n > 0;
  }
}
