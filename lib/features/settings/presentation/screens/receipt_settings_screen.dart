import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../products/presentation/widgets/page_header.dart';
import '../../domain/models/business_profile_settings.dart';
import '../../domain/models/system_preferences.dart';
import '../providers/settings_providers.dart';

/// Receipt-specific configuration (footer, toggles).
class ReceiptSettingsScreen extends ConsumerStatefulWidget {
  const ReceiptSettingsScreen({super.key});

  @override
  ConsumerState<ReceiptSettingsScreen> createState() => _ReceiptSettingsScreenState();
}

class _ReceiptSettingsScreenState extends ConsumerState<ReceiptSettingsScreen> {
  late TextEditingController _footerController;
  bool _showPhone = true;
  bool _showTaxNumber = true;
  bool _autoPrintAfterSale = false;
  bool _hasPopulated = false;

  @override
  void initState() {
    super.initState();
    _footerController = TextEditingController();
  }

  @override
  void dispose() {
    _footerController.dispose();
    super.dispose();
  }

  void _populateFrom(BusinessProfileSettings profile, SystemPreferences prefs) {
    _footerController.text = profile.receiptFooter;
    _showPhone = prefs.showPhoneOnReceipt;
    _showTaxNumber = prefs.showTaxNumberOnReceipt;
    _autoPrintAfterSale = prefs.autoPrintAfterSale;
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(businessProfileSettingsProvider);
    final prefsAsync = ref.watch(systemPreferencesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Receipt Settings',
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
          child: profileAsync.when(
            data: (profile) {
              return prefsAsync.when(
                data: (prefs) {
                  if (!_hasPopulated) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _populateFrom(profile, prefs);
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
                          TextFormField(
                            controller: _footerController,
                            decoration: const InputDecoration(
                              labelText: 'Receipt Footer',
                              hintText: 'Thank you for your business!',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 24),
                          SwitchListTile(
                            title: const Text('Show business phone on receipt'),
                            value: _showPhone,
                            onChanged: (v) => setState(() => _showPhone = v),
                          ),
                          SwitchListTile(
                            title: const Text('Show tax number on receipt'),
                            value: _showTaxNumber,
                            onChanged: (v) => setState(() => _showTaxNumber = v),
                          ),
                          SwitchListTile(
                            title: const Text('Auto print after sale'),
                            value: _autoPrintAfterSale,
                            onChanged: (v) => setState(() => _autoPrintAfterSale = v),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
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
    final profile = await ref.read(businessProfileSettingsProvider.future);
    final prefs = await ref.read(systemPreferencesProvider.future);

    await ref.read(settingsRepositoryProvider).saveBusinessProfile(
          profile.copyWith(receiptFooter: _footerController.text.trim()),
        );
    await ref.read(settingsRepositoryProvider).saveSystemPreferences(
          prefs.copyWith(
            showPhoneOnReceipt: _showPhone,
            showTaxNumberOnReceipt: _showTaxNumber,
            autoPrintAfterSale: _autoPrintAfterSale,
          ),
        );

    ref.invalidate(businessProfileSettingsProvider);
    ref.invalidate(systemPreferencesProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt settings saved')),
      );
    }
  }
}
