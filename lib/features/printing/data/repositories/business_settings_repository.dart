import '../../../../database/app_database.dart';

class BusinessSettingsRepository {
  BusinessSettingsRepository(this._db);

  final AppDatabase _db;

  Future<String?> getValue(String key) async {
    final row = await (_db.select(_db.businessSettings)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<Map<String, String>> getAllAsMap() async {
    final rows = await _db.select(_db.businessSettings).get();
    return {for (final r in rows) r.key: r.value};
  }

  Future<void> setValue(String key, String value) async {
    final existing = await (_db.select(_db.businessSettings)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    if (existing != null) {
      await _db.update(_db.businessSettings).replace(
            existing.copyWith(value: value, updatedAt: DateTime.now()).toCompanion(true),
          );
    } else {
      await _db.into(_db.businessSettings).insert(
            BusinessSettingsCompanion.insert(key: key, value: value),
          );
    }
  }

  Future<void> setAll(Map<String, String> map) async {
    for (final e in map.entries) {
      await setValue(e.key, e.value);
    }
  }
}
