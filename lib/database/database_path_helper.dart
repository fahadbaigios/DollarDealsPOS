import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Centralized database path logic.
/// Must match database_connection.dart.
const String databaseFileName = 'pos_database.sqlite';

/// Returns the full path to the database file.
///
/// The database lives in the app's *support* directory (e.g.
/// `%APPDATA%\<app>` on Windows, `Application Support/<app>` on macOS) -
/// NOT the Documents folder. On Windows, "Documents" is very commonly
/// redirected/synced by OneDrive, which locks and re-uploads the sqlite
/// file on every write and causes severe, worsening slowdowns as the
/// database grows. App-support directories are never cloud-synced.
Future<String> getDatabasePath() async {
  final dbFolder = await getApplicationSupportDirectory();
  return p.join(dbFolder.path, databaseFileName);
}

/// Returns the directory containing the database.
Future<String> getDatabaseDirectory() async {
  final dbFolder = await getApplicationSupportDirectory();
  return dbFolder.path;
}

/// The old (pre-migration) database path, kept only so existing installs
/// can be migrated automatically. Do not use for new reads/writes.
Future<String> getLegacyDatabasePath() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  return p.join(dbFolder.path, databaseFileName);
}

/// Backups are intentionally kept under Documents (not app-support) so
/// users can easily find them and copy them to a USB drive / cloud folder
/// on demand. This is a one-shot copy operation, not a live-write target,
/// so it does not suffer from the same OneDrive/antivirus contention issue.
Future<String> getBackupDirectory() async {
  final base = await getApplicationDocumentsDirectory();
  final backupDir = p.join(base.path, 'backups');
  return backupDir;
}

/// Ensures backup directory exists.
Future<String> ensureBackupDirectory() async {
  final dir = await getBackupDirectory();
  await Directory(dir).create(recursive: true);
  return dir;
}

/// One-time migration: if a database already exists at the old Documents
/// location (from a previous version of the app) and no database exists
/// yet at the new app-support location, move it over.
///
/// Safe to call on every startup - it's a cheap no-op once migrated.
Future<void> migrateLegacyDatabaseIfNeeded() async {
  final newPath = await getDatabasePath();
  final newFile = File(newPath);
  if (await newFile.exists()) return;

  final legacyPath = await getLegacyDatabasePath();
  final legacyFile = File(legacyPath);
  if (!await legacyFile.exists()) return;

  final newDir = Directory(p.dirname(newPath));
  await newDir.create(recursive: true);

  try {
    await legacyFile.rename(newPath);
  } on FileSystemException {
    // rename() can fail across volumes/drives - fall back to copy+delete.
    await legacyFile.copy(newPath);
    await legacyFile.delete();
  }

  // Bring along SQLite's WAL/SHM sidecar files if present, so no
  // committed-but-not-checkpointed data is left behind.
  for (final suffix in ['-wal', '-shm', '-journal']) {
    final sidecar = File('$legacyPath$suffix');
    if (await sidecar.exists()) {
      final newSidecar = File('$newPath$suffix');
      try {
        await sidecar.rename(newSidecar.path);
      } on FileSystemException {
        await sidecar.copy(newSidecar.path);
        await sidecar.delete();
      }
    }
  }
}
