import 'package:drift/drift.dart';

import '../../../../database/app_database.dart';

class PaymentMethodsRepository {
  PaymentMethodsRepository(this._db);

  final AppDatabase _db;

  Future<List<PaymentMethod>> getAll() async {
    return (_db.select(_db.paymentMethods)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<List<PaymentMethod>> getActive() async {
    return (_db.select(_db.paymentMethods)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<PaymentMethod?> getById(int id) async {
    return (_db.select(_db.paymentMethods)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }
}
