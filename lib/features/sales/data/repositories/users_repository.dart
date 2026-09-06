import '../../../../database/app_database.dart';

class UsersRepository {
  UsersRepository(this._db);

  final AppDatabase _db;

  Future<User?> getFirstActiveUser() async {
    return (_db.select(_db.users)
          ..where((t) => t.isActive.equals(true))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<User?> getById(int id) async {
    return (_db.select(_db.users)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<User>> getByIds(Iterable<int> ids) async {
    final idList = ids.toSet().toList();
    if (idList.isEmpty) return [];
    return (_db.select(_db.users)..where((t) => t.id.isIn(idList))).get();
  }
}
