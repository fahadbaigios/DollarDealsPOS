import 'package:drift/drift.dart';

import '../../../../database/app_database.dart';

class CategoriesRepository {
  CategoriesRepository(this._db);

  final AppDatabase _db;

  Stream<List<Category>> watchAll() {
    return (_db.select(_db.categories)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  }

  Stream<List<Category>> search(String query) {
    if (query.trim().isEmpty) return watchAll();
    final q = query.trim().toLowerCase();
    return (_db.select(_db.categories)
          ..where((t) => t.name.lower().like('%$q%') | (t.description.isNotNull() & t.description.like('%$q%')))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<List<Category>> getAll() async {
    return (_db.select(_db.categories)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  }

  Future<Category?> getById(int id) async {
    return (_db.select(_db.categories)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<Category?> getByName(String name, {int? excludeId}) async {
    final n = name.trim().toLowerCase();
    return (_db.select(_db.categories)
          ..where((t) => t.name.lower().equals(n) & (excludeId == null ? const Constant(true) : t.id.isNotValue(excludeId))))
        .getSingleOrNull();
  }

  Future<int> create(String name, {String? description}) async {
    return _db.into(_db.categories).insert(
          CategoriesCompanion.insert(
            name: name,
            description: description == null ? const Value.absent() : Value(description),
          ),
        );
  }

  Future<bool> update(int id, String name, {String? description, bool? isActive}) async {
    final existing = await getById(id);
    if (existing == null) return false;
    final updated = existing.copyWith(
      name: name,
      description: Value(description ?? existing.description),
      isActive: isActive ?? existing.isActive,
    );
    return _db.update(_db.categories).replace(updated.toCompanion(true));
  }

  Future<bool> setActiveStatus(int id, bool isActive) async {
    final existing = await getById(id);
    if (existing == null) return false;
    return _db.update(_db.categories).replace(existing.copyWith(isActive: isActive).toCompanion(true));
  }
}
