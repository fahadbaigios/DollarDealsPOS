import 'package:drift/drift.dart';

import '../../../../database/app_database.dart';

class UnitsRepository {
  UnitsRepository(this._db);

  final AppDatabase _db;

  Stream<List<Unit>> watchAll() {
    return (_db.select(_db.units)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  }

  Future<List<Unit>> getAll() async {
    return (_db.select(_db.units)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  }

  Future<Unit?> getById(int id) async {
    return (_db.select(_db.units)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<Unit?> getByName(String name, {int? excludeId}) async {
    final n = name.trim().toLowerCase();
    return (_db.select(_db.units)
          ..where((t) => t.name.lower().equals(n) & (excludeId == null ? const Constant(true) : t.id.isNotValue(excludeId))))
        .getSingleOrNull();
  }

  Future<Unit?> getBySymbol(String symbol, {int? excludeId}) async {
    final s = symbol.trim().toLowerCase();
    return (_db.select(_db.units)
          ..where((t) => t.symbol.lower().equals(s) & (excludeId == null ? const Constant(true) : t.id.isNotValue(excludeId))))
        .getSingleOrNull();
  }

  Future<int> create(String name, String symbol) async {
    return _db.into(_db.units).insert(
          UnitsCompanion.insert(name: name, symbol: symbol),
        );
  }

  Future<bool> update(int id, String name, String symbol) async {
    final existing = await getById(id);
    if (existing == null) return false;
    return _db.update(_db.units).replace(existing.copyWith(name: name, symbol: symbol).toCompanion(true));
  }
}
