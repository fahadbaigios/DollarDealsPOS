import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/database_provider.dart';
import '../../../../database/database_path_helper.dart';
import '../../../printing/data/repositories/business_settings_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/models/business_profile_settings.dart';
import '../../domain/models/system_preferences.dart';
import '../../domain/services/backup_restore_service.dart';
import '../../domain/services/database_maintenance_service.dart';

final businessSettingsRepositoryProvider = Provider<BusinessSettingsRepository>((ref) {
  return BusinessSettingsRepository(ref.watch(databaseProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final businessRepo = ref.watch(businessSettingsRepositoryProvider);
  return SettingsRepository(db, businessRepo);
});

final businessProfileSettingsProvider =
    FutureProvider.autoDispose<BusinessProfileSettings>((ref) {
  return ref.watch(settingsRepositoryProvider).getBusinessProfile();
});

final systemPreferencesProvider =
    FutureProvider.autoDispose<SystemPreferences>((ref) {
  return ref.watch(settingsRepositoryProvider).getSystemPreferences();
});

final printerSettingsListProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) {
  return ref.watch(settingsRepositoryProvider).getAllPrinters();
});

final defaultPrinterProvider = FutureProvider.autoDispose<dynamic>((ref) {
  return ref.watch(settingsRepositoryProvider).getDefaultPrinter();
});

final databasePathProvider = FutureProvider.autoDispose<String>((ref) {
  return getDatabasePath();
});

final backupRestoreServiceProvider = Provider<BackupRestoreService>((ref) {
  return BackupRestoreService(
    getDatabasePath,
    () async {
      final db = ref.read(databaseProvider);
      await db.close();
    },
    () async {
      ref.invalidate(databaseProvider);
    },
    onBeforeBackup: () async {
      final db = ref.read(databaseProvider);
      // Flush WAL contents into the main file so the plain file copy
      // below captures every committed transaction.
      await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
    },
  );
});

final backupListProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final service = ref.watch(backupRestoreServiceProvider);
  return service.listBackups();
});

final databaseMaintenanceServiceProvider =
    Provider<DatabaseMaintenanceService>((ref) {
  return DatabaseMaintenanceService(ref.watch(databaseProvider));
});
