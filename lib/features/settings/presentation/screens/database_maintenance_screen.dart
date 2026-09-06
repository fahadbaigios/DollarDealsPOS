import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../products/presentation/widgets/page_header.dart';
import '../providers/settings_providers.dart';

/// Database maintenance: VACUUM + ANALYZE to reclaim space and refresh stats.
class DatabaseMaintenanceScreen extends ConsumerStatefulWidget {
  const DatabaseMaintenanceScreen({super.key});

  @override
  ConsumerState<DatabaseMaintenanceScreen> createState() =>
      _DatabaseMaintenanceScreenState();
}

class _DatabaseMaintenanceScreenState
    extends ConsumerState<DatabaseMaintenanceScreen> {
  bool _isOptimizing = false;
  String? _lastResultMessage;

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Future<void> _optimizeDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Optimize Database'),
        content: const Text(
          'This will compact the database file and refresh query statistics. '
          'It may take a few seconds. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Optimize'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isOptimizing = true;
      _lastResultMessage = null;
    });

    try {
      final result =
          await ref.read(databaseMaintenanceServiceProvider).optimize();

      if (!mounted) return;

      if (result.success) {
        final before = result.sizeBeforeBytes;
        final after = result.sizeAfterBytes;
        final reclaimed = result.bytesReclaimed;
        var message = 'Database optimized successfully.';
        if (before != null && after != null) {
          message =
              'Database optimized. Size: ${_formatBytes(before)} → ${_formatBytes(after)}';
          if (reclaimed != null && reclaimed > 0) {
            message += ' (${_formatBytes(reclaimed)} reclaimed)';
          }
        }
        setState(() => _lastResultMessage = message);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } else {
        final error = result.error ?? 'Optimization failed';
        setState(() => _lastResultMessage = error);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isOptimizing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbPathAsync = ref.watch(databasePathProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Database Maintenance',
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
                  data: (path) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Database Location',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            path,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
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
                          'Optimize Database',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Runs WAL checkpoint, VACUUM, and ANALYZE. '
                          'This reclaims unused space from deleted/updated rows '
                          'and helps SQLite choose faster query plans. '
                          'Recommended once a month on busy tills, or if the '
                          'app feels slower after long use.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _isOptimizing ? null : _optimizeDatabase,
                          icon: _isOptimizing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.speed),
                          label: Text(
                            _isOptimizing
                                ? 'Optimizing...'
                                : 'Optimize Database',
                          ),
                        ),
                        if (_lastResultMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _lastResultMessage!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
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
}
