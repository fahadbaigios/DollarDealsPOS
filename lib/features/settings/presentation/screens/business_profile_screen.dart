import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../products/presentation/widgets/page_header.dart';
import '../../domain/models/business_profile_settings.dart';
import '../providers/settings_providers.dart';

/// Business profile settings form.
class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  ConsumerState<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends ConsumerState<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _taxController;
  late TextEditingController _currencyCodeController;
  late TextEditingController _currencySymbolController;
  late TextEditingController _footerController;
  late TextEditingController _taxRateController;
  bool _taxEnabled = false;
  bool _hasPopulated = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _taxController = TextEditingController();
    _currencyCodeController = TextEditingController(text: 'USD');
    _currencySymbolController = TextEditingController(text: '\$');
    _footerController = TextEditingController();
    _taxRateController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _taxController.dispose();
    _currencyCodeController.dispose();
    _currencySymbolController.dispose();
    _footerController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  void _populateFrom(BusinessProfileSettings s) {
    _nameController.text = s.businessName;
    _addressController.text = s.address;
    _phoneController.text = s.phone;
    _emailController.text = s.email;
    _taxController.text = s.ntmOrTaxNumber;
    _currencyCodeController.text = s.currencyCode;
    _currencySymbolController.text = s.currencySymbol;
    _footerController.text = s.receiptFooter;
    _taxEnabled = s.taxEnabled;
    _taxRateController.text = s.defaultTaxRate.toString();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(businessProfileSettingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Business Profile',
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
              if (!_hasPopulated) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _populateFrom(profile);
                    _hasPopulated = true;
                  }
                });
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Form(
                  key: _formKey,
                  child: _FormContent(
                    nameController: _nameController,
                    addressController: _addressController,
                    phoneController: _phoneController,
                    emailController: _emailController,
                    taxController: _taxController,
                    currencyCodeController: _currencyCodeController,
                    currencySymbolController: _currencySymbolController,
                    footerController: _footerController,
                    taxRateController: _taxRateController,
                    taxEnabled: _taxEnabled,
                    onTaxEnabledChanged: (v) => setState(() => _taxEnabled = v),
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
    if (!_formKey.currentState!.validate()) return;

    final profile = BusinessProfileSettings(
      businessName: _nameController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      ntmOrTaxNumber: _taxController.text.trim(),
      currencyCode: _currencyCodeController.text.trim().isEmpty
          ? 'USD'
          : _currencyCodeController.text.trim(),
      currencySymbol: _currencySymbolController.text.trim().isEmpty
          ? '\$'
          : _currencySymbolController.text.trim(),
      receiptFooter: _footerController.text.trim(),
      taxEnabled: _taxEnabled,
      defaultTaxRate: double.tryParse(_taxRateController.text) ?? 0,
    );

    await ref.read(settingsRepositoryProvider).saveBusinessProfile(profile);
    ref.invalidate(businessProfileSettingsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business profile saved')),
      );
    }
  }
}

class _FormContent extends StatelessWidget {
  const _FormContent({
    required this.nameController,
    required this.addressController,
    required this.phoneController,
    required this.emailController,
    required this.taxController,
    required this.currencyCodeController,
    required this.currencySymbolController,
    required this.footerController,
    required this.taxRateController,
    required this.taxEnabled,
    required this.onTaxEnabledChanged,
  });

  final TextEditingController nameController;
  final TextEditingController addressController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController taxController;
  final TextEditingController currencyCodeController;
  final TextEditingController currencySymbolController;
  final TextEditingController footerController;
  final TextEditingController taxRateController;
  final bool taxEnabled;
  final ValueChanged<bool> onTaxEnabledChanged;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Business Name *',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Business name is required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: taxController,
            decoration: const InputDecoration(
              labelText: 'NTM / Tax Number',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: currencyCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Currency Code',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 80,
                child: TextFormField(
                  controller: currencySymbolController,
                  decoration: const InputDecoration(
                    labelText: 'Symbol',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: footerController,
            decoration: const InputDecoration(
              labelText: 'Receipt Footer',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Tax Enabled'),
            value: taxEnabled,
            onChanged: onTaxEnabledChanged,
          ),
          if (taxEnabled)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextFormField(
                controller: taxRateController,
                decoration: const InputDecoration(
                  labelText: 'Default Tax Rate (%)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final rate = double.tryParse(v ?? '') ?? -1;
                  return rate < 0 ? 'Tax rate must be >= 0' : null;
                },
              ),
            ),
        ],
      ),
    );
  }
}
