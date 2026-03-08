import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Centralized database path logic.
/// Must match database_connection.dart.
const String databaseFileName = 'pos_database.sqlite';

/// Returns the full path to the database file.
Future<String> getDatabasePath() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  return p.join(dbFolder.path, databaseFileName);
}

/// Returns the directory containing the database (for backup location).
Future<String> getDatabaseDirectory() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  return dbFolder.path;
}

/// Returns the backup directory path (subfolder of app documents).
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
