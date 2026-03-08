import 'package:drift/drift.dart';

import '../../../../database/app_database.dart';

class SuppliersRepository {
  SuppliersRepository(this._db);

  final AppDatabase _db;

  Stream<List<Supplier>> watchAll() {
    return (_db.select(_db.suppliers)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  }

  Stream<List<Supplier>> search(String query) {
    if (query.trim().isEmpty) return watchAll();
    final q = query.trim().toLowerCase();
    return (_db.select(_db.suppliers)
          ..where((t) =>
              t.name.lower().like('%$q%') |
              (t.phone.isNotNull() & t.phone.like('%$q%')) |
              (t.contactPerson.isNotNull() & t.contactPerson.like('%$q%')) |
              (t.email.isNotNull() & t.email.like('%$q%')))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<List<Supplier>> getAll() async {
    return (_db.select(_db.suppliers)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  }

  Future<Supplier?> getById(int id) async {
    return (_db.select(_db.suppliers)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> create({
    required String name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    return _db.into(_db.suppliers).insert(
          SuppliersCompanion.insert(
            name: name,
            contactPerson: Value(contactPerson),
            phone: Value(phone),
            email: Value(email),
            address: Value(address),
            notes: Value(notes),
          ),
        );
  }

  Future<bool> update({
    required int id,
    required String name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? notes,
    bool? isActive,
  }) async {
    final existing = await getById(id);
    if (existing == null) return false;
    final updated = existing.copyWith(
      name: name,
      contactPerson: Value(contactPerson),
      phone: Value(phone),
      email: Value(email),
      address: Value(address),
      notes: Value(notes),
      isActive: isActive ?? existing.isActive,
      updatedAt: DateTime.now(),
    );
    return _db.update(_db.suppliers).replace(updated.toCompanion(true));
  }

  Future<bool> setActiveStatus(int id, bool isActive) async {
    final existing = await getById(id);
    if (existing == null) return false;
    return _db.update(_db.suppliers).replace(existing.copyWith(isActive: isActive).toCompanion(true));
  }
}
