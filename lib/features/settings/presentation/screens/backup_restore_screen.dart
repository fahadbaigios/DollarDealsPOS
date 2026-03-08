import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../../../core/constants/route_names.dart';
import '../../../../core/services/database_provider.dart';
import '../../../products/presentation/widgets/page_header.dart';
import '../providers/settings_providers.dart';

/// Backup and restore database screen.
class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  bool _isBackingUp = false;
  bool _isRestoring = false;
  String? _lastBackupPath;
  DateTime? _lastBackupTime;

  @override
  Widget build(BuildContext context) {
    final dbPathAsync = ref.watch(databasePathProvider);
    final backupsAsync = ref.watch(backupListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Backup & Restore',
          actions: [
            TextButton.icon(
              onPressed: () => context.goNamed(RouteNames.settings),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back'),
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                dbPathAsync.when(
                  data: (path) => _InfoCard(
                    title: 'Database Location',
                    child: SelectableText(path, style: const TextStyle(fontFamily: 'monospace')),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => Text('Error: $e'),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Backup',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Save a copy of the database to the backups folder.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            FilledButton.icon(
                              onPressed: _isBackingUp ? null : () => _createBackup(context),
                              icon: _isBackingUp
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.backup, size: 18),
                              label: Text(_isBackingUp ? 'Backing up...' : 'Backup Now'),
                            ),
                          ],
                        ),
                        if (_lastBackupPath != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Last backup: $_lastBackupPath',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        if (_lastBackupTime != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'At ${DateFormat.yMd().add_Hm().format(_lastBackupTime!)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Restore from Backup',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Replace current database with a backup. All current data will be lost.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                        const SizedBox(height: 16),
                        backupsAsync.when(
                          data: (backups) {
                            if (backups.isEmpty) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FilledButton.tonalIcon(
                                    onPressed: _isRestoring ? null : () => _restoreFromFilePicker(context),
                                    icon: _isRestoring
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.folder_open, size: 18),
                                    label: const Text('Choose backup file...'),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No backups in default folder.',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...backups.map<Widget>((f) {
                                  final file = f as File;
                                  final name = p.basename(file.path);
                                  final stat = file.statSync();
                                  final modified = stat.modified;
                                  return ListTile(
                                    leading: const Icon(Icons.insert_drive_file),
                                    title: Text(name),
                                    subtitle: Text(
                                      DateFormat.yMd().add_Hm().format(modified),
                                    ),
                                    trailing: FilledButton.tonal(
                                      onPressed: _isRestoring
                                          ? null
                                          : () => _restoreFromPath(context, file.path),
                                      child: const Text('Restore'),
                                    ),
                                  );
                                }),
                                const Divider(),
                                TextButton.icon(
                                  onPressed: _isRestoring ? null : () => _restoreFromFilePicker(context),
                                  icon: const Icon(Icons.folder_open, size: 18),
                                  label: const Text('Choose another file...'),
                                ),
                              ],
                            );
                          },
                          loading: () => const CircularProgressIndicator(),
                          error: (e, _) => Text('Error: $e'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _createBackup(BuildContext context) async {
    setState(() => _isBackingUp = true);
    try {
      final service = ref.read(backupRestoreServiceProvider);
      final result = await service.createBackup();
      if (!context.mounted) return;
      setState(() {
        _isBackingUp = false;
        if (result.success) {
          _lastBackupPath = result.path;
          _lastBackupTime = DateTime.now();
          ref.invalidate(backupListProvider);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.success
                  ? 'Backup created: ${p.basename(result.path ?? '')}'
                  : 'Backup failed: ${result.error}',
            ),
            backgroundColor: result.success ? null : Theme.of(context).colorScheme.error,
          ),
        );
    } catch (e) {
      if (!context.mounted) return;
      setState(() => _isBackingUp = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _restoreFromFilePicker(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['sqlite'],
      dialogTitle: 'Select backup file',
    );
    if (result != null && result.files.single.path != null) {
      await _restoreFromPath(context, result.files.single.path!);
    }
  }

  Future<void> _restoreFromPath(BuildContext context, String backupPath) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Database'),
        content: const Text(
          'This will replace all current data with the backup. '
          'This action cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    setState(() => _isRestoring = true);
    try {
      final service = ref.read(backupRestoreServiceProvider);
      final result = await service.restoreFromPath(backupPath);
      if (!context.mounted) return;
      setState(() => _isRestoring = false);
      ref.invalidate(backupListProvider);
      ref.invalidate(databasePathProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? 'Database restored successfully. Please restart the app.'
                : 'Restore failed: ${result.error}',
          ),
          backgroundColor: result.success ? null : Theme.of(context).colorScheme.error,
        ),
      );
      if (result.success) {
        ref.invalidate(databaseProvider);
      }
    } catch (e) {
      if (!context.mounted) return;
      setState(() => _isRestoring = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
