import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/services/database_provider.dart';
import '../../../../core/services/seed_service.dart';
import '../../../products/presentation/widgets/page_header.dart';

/// Settings home screen with navigation cards.
class SettingsHomeScreen extends ConsumerWidget {
  const SettingsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeader(title: 'Settings'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _SettingsCard(
                  icon: Icons.store_outlined,
                  title: 'Business Profile',
                  subtitle: 'Business name, address, tax, currency',
                  onTap: () => context.goNamed(RouteNames.businessProfile),
                ),
                _SettingsCard(
                  icon: Icons.receipt_long_outlined,
                  title: 'Receipt Settings',
                  subtitle: 'Footer, phone, tax number on receipt',
                  onTap: () => context.goNamed(RouteNames.receiptSettings),
                ),
                _SettingsCard(
                  icon: Icons.print_outlined,
                  title: 'Printer Settings',
                  subtitle: 'Printer name, paper width, copies',
                  onTap: () => context.goNamed(RouteNames.printerSettings),
                ),
                _SettingsCard(
                  icon: Icons.tune_outlined,
                  title: 'System Preferences',
                  subtitle: 'Stock, print, confirmations',
                  onTap: () => context.goNamed(RouteNames.systemPreferences),
                ),
                _SettingsCard(
                  icon: Icons.backup_outlined,
                  title: 'Backup & Restore',
                  subtitle: 'Backup database, restore from backup',
                  onTap: () => context.goNamed(RouteNames.backupRestore),
                ),
                _SettingsCard(
                  icon: Icons.speed_outlined,
                  title: 'Database Maintenance',
                  subtitle: 'Optimize database (VACUUM + ANALYZE)',
                  onTap: () => context.goNamed(RouteNames.databaseMaintenance),
                ),
              ],
            ),
          ),
        ),
        _SettingsFooter(ref: ref),
      ],
    );
  }
}

class _SettingsFooter extends ConsumerWidget {
  const _SettingsFooter({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${AppConstants.appName} v${AppConstants.appVersion}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () async {
              final seedService = SeedService(this.ref.read(databaseProvider));
              final result = await seedService.seedDemoData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.success
                        ? (result.message ?? 'Demo data seeded.')
                        : (result.error ?? result.message ?? 'Failed')),
                    backgroundColor: result.success
                        ? null
                        : Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            child: const Text('Seed Demo Data'),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 260,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
