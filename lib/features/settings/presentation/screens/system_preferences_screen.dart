import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../products/presentation/widgets/page_header.dart';
import '../../domain/models/system_preferences.dart';
import '../providers/settings_providers.dart';

/// System behavior preferences.
class SystemPreferencesScreen extends ConsumerStatefulWidget {
  const SystemPreferencesScreen({super.key});

  @override
  ConsumerState<SystemPreferencesScreen> createState() =>
      _SystemPreferencesScreenState();
}

class _SystemPreferencesScreenState extends ConsumerState<SystemPreferencesScreen> {
  bool _allowNegativeStock = false;
  bool _autoPrintAfterSale = false;
  bool _confirmBeforeCompletingSale = false;
  bool _hasPopulated = false;

  void _populateFrom(SystemPreferences p) {
    _allowNegativeStock = p.allowNegativeStock;
    _autoPrintAfterSale = p.autoPrintAfterSale;
    _confirmBeforeCompletingSale = p.confirmBeforeCompletingSale;
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(systemPreferencesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'System Preferences',
          actions: [
            TextButton.icon(
              onPressed: () => context.goNamed(RouteNames.settings),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => _save(context),
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save'),
            ),
          ],
        ),
        Expanded(
          child: prefsAsync.when(
            data: (prefs) {
              if (!_hasPopulated) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _populateFrom(prefs);
                    _hasPopulated = true;
                  }
                });
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SwitchListTile(
                        title: const Text('Allow negative stock'),
                        subtitle: const Text(
                          'Allow sales when stock would go below zero',
                        ),
                        value: _allowNegativeStock,
                        onChanged: (v) =>
                            setState(() => _allowNegativeStock = v),
                      ),
                      SwitchListTile(
                        title: const Text('Auto print after sale'),
                        subtitle: const Text(
                          'Automatically print receipt when sale is completed',
                        ),
                        value: _autoPrintAfterSale,
                        onChanged: (v) =>
                            setState(() => _autoPrintAfterSale = v),
                      ),
                      SwitchListTile(
                        title: const Text('Confirm before completing sale'),
                        subtitle: const Text(
                          'Show confirmation dialog before finalizing sale',
                        ),
                        value: _confirmBeforeCompletingSale,
                        onChanged: (v) =>
                            setState(() => _confirmBeforeCompletingSale = v),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  Future<void> _save(BuildContext context) async {
    final prefs = await ref.read(systemPreferencesProvider.future);

    await ref.read(settingsRepositoryProvider).saveSystemPreferences(
          prefs.copyWith(
            allowNegativeStock: _allowNegativeStock,
            autoPrintAfterSale: _autoPrintAfterSale,
            confirmBeforeCompletingSale: _confirmBeforeCompletingSale,
          ),
        );

    ref.invalidate(systemPreferencesProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('System preferences saved')),
      );
    }
  }
}
