import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'database_path_helper.dart';

/// Creates a desktop-friendly SQLite connection.
///
/// Database lives in the app-support directory (see [getDatabasePath]) and
/// is opened with WAL journaling for good desktop write performance.
LazyDatabase createDatabaseConnection() {
  return LazyDatabase(() async {
    await migrateLegacyDatabaseIfNeeded();

    final path = await getDatabasePath();
    final file = File(path);

    return NativeDatabase.createInBackground(
      file,
      setup: (rawDb) {
        // WAL avoids creating/fsyncing/deleting a separate rollback-journal
        // file on every write - the default (DELETE) journal mode is a
        // major source of slowness on Windows, especially when the DB
        // folder is touched by antivirus/cloud-sync file watchers.
        rawDb.execute('PRAGMA journal_mode=WAL;');
        // NORMAL is safe with WAL (only fsyncs at checkpoints, not every
        // commit) and is dramatically faster than the default FULL.
        rawDb.execute('PRAGMA synchronous=NORMAL;');
        // Use memory for temp tables/indices used during sorts & joins.
        rawDb.execute('PRAGMA temp_store=MEMORY;');
        // Drift does not enforce FK constraints unless explicitly enabled.
        rawDb.execute('PRAGMA foreign_keys=ON;');
      },
    );
  });
}
