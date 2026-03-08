import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../../database/database_path_helper.dart';

/// Result of a backup operation.
class BackupResult {
  const BackupResult({
    required this.success,
    this.path,
    this.error,
  });

  final bool success;
  final String? path;
  final String? error;
}

/// Result of a restore operation.
class RestoreResult {
  const RestoreResult({
    required this.success,
    this.error,
  });

  final bool success;
  final String? error;
}

/// Service for database backup and restore.
class BackupRestoreService {
  BackupRestoreService(this._getDbPath, this._onBeforeRestore, this._onAfterRestore);

  final Future<String> Function() _getDbPath;
  final Future<void> Function() _onBeforeRestore;
  final Future<void> Function() _onAfterRestore;

  /// Creates backup filename: pos-backup-2026-03-08-14-30.sqlite
  static String backupFileName() {
    final now = DateTime.now();
    final y = now.year;
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final h = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    return 'pos-backup-$y-$m-$d-$h-$min.sqlite';
  }

  /// Creates a backup of the database.
  /// Saves to app documents/backups/ folder.
  Future<BackupResult> createBackup() async {
    try {
      final dbPath = await _getDbPath();
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        return const BackupResult(success: false, error: 'Database file not found');
      }

      final backupDir = await ensureBackupDirectory();
      final backupPath = p.join(backupDir, backupFileName());
      await dbFile.copy(backupPath);

      return BackupResult(success: true, path: backupPath);
    } catch (e) {
      return BackupResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Creates a backup to a user-selected path (caller provides the path).
  Future<BackupResult> createBackupToPath(String destPath) async {
    try {
      final dbPath = await _getDbPath();
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        return const BackupResult(success: false, error: 'Database file not found');
      }
      await dbFile.copy(destPath);
      return BackupResult(success: true, path: destPath);
    } catch (e) {
      return BackupResult(success: false, error: e.toString());
    }
  }

  /// Restores database from a backup file.
  /// Must call _onBeforeRestore (close DB) before replacing file.
  /// Must call _onAfterRestore (invalidate providers) after.
  Future<RestoreResult> restoreFromPath(String backupPath) async {
    try {
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        return const RestoreResult(success: false, error: 'Backup file not found');
      }
      if (await backupFile.length() == 0) {
        return const RestoreResult(success: false, error: 'Backup file is empty');
      }

      final dbPath = await _getDbPath();

      await _onBeforeRestore();

      await backupFile.copy(dbPath);

      await _onAfterRestore();

      return const RestoreResult(success: true);
    } catch (e) {
      await _onAfterRestore();
      return RestoreResult(success: false, error: e.toString());
    }
  }

  /// Lists backup files in the default backup directory.
  Future<List<File>> listBackups() async {
    final dir = await getBackupDirectory();
    final directory = Directory(dir);
    if (!await directory.exists()) return [];
    final entities = await directory.list().toList();
    return entities
        .whereType<File>()
        .where((f) => f.path.endsWith('.sqlite'))
        .toList();
  }
}
