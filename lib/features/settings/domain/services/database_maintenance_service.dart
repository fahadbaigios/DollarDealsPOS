import 'dart:io';

import '../../../../database/app_database.dart';
import '../../../../database/database_path_helper.dart';
import '../models/database_maintenance_result.dart';

/// Runs SQLite maintenance: checkpoint WAL, VACUUM, and ANALYZE.
class DatabaseMaintenanceService {
  DatabaseMaintenanceService(this._db);

  final AppDatabase _db;

  Future<DatabaseMaintenanceResult> optimize() async {
    try {
      final path = await getDatabasePath();
      final dbFile = File(path);
      final sizeBefore = await dbFile.exists() ? await dbFile.length() : 0;

      await _db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
      await _db.customStatement('VACUUM;');
      await _db.customStatement('ANALYZE;');

      final sizeAfter = await dbFile.exists() ? await dbFile.length() : 0;

      return DatabaseMaintenanceResult(
        success: true,
        sizeBeforeBytes: sizeBefore,
        sizeAfterBytes: sizeAfter,
      );
    } catch (e) {
      return DatabaseMaintenanceResult(
        success: false,
        error: e.toString(),
      );
    }
  }
}
