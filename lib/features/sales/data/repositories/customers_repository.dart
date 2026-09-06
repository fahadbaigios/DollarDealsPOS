import 'package:drift/drift.dart';

import '../../../../database/app_database.dart';

class CustomersRepository {
  CustomersRepository(this._db);

  final AppDatabase _db;

  Future<List<Customer>> getAll() async {
    return (_db.select(_db.customers)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<List<Customer>> getActive() async {
    return (_db.select(_db.customers)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<List<Customer>> search(String query) async {
    if (query.trim().isEmpty) return getActive();
    final q = query.trim().toLowerCase();
    return (_db.select(_db.customers)
          ..where((t) =>
              t.isActive.equals(true) &
              (t.name.lower().like('%$q%') |
                  (t.phone.isNotNull() & t.phone.like('%$q%')) |
                  (t.email.isNotNull() & t.email.like('%$q%'))))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<Customer?> getById(int id) async {
    return (_db.select(_db.customers)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<Customer>> getByIds(Iterable<int> ids) async {
    final idList = ids.toSet().toList();
    if (idList.isEmpty) return [];
    return (_db.select(_db.customers)..where((t) => t.id.isIn(idList))).get();
  }
}
