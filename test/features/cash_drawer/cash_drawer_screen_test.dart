import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_dollar_deals_inventory_system/database/app_database.dart';
import 'package:one_dollar_deals_inventory_system/features/cash_drawer/data/repositories/cash_drawer_repository.dart';
import 'package:one_dollar_deals_inventory_system/features/cash_drawer/domain/models/cash_drawer_summary.dart';
import 'package:one_dollar_deals_inventory_system/features/cash_drawer/presentation/providers/cash_drawer_providers.dart';
import 'package:one_dollar_deals_inventory_system/features/cash_drawer/presentation/screens/cash_drawer_screen.dart';

class _RecordingCashDrawerRepository extends CashDrawerRepository {
  _RecordingCashDrawerRepository(super.db);

  double? addedAmount;

  @override
  Future<void> addCashIn({required double amount, String? note}) async {
    addedAmount = amount;
  }
}

void main() {
  testWidgets('cash in dialog safely saves a multi-digit amount', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = _RecordingCashDrawerRepository(db);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cashDrawerRepositoryProvider.overrideWithValue(repository),
          cashDrawerSummaryProvider.overrideWith(
            (ref) async => const CashDrawerSummary(
              balanceMinor: 0,
              todayCashSalesMinor: 0,
              todayCashInMinor: 0,
              todayCashOutMinor: 0,
            ),
          ),
          cashDrawerActivityProvider.overrideWith(
            (ref) async => <CashDrawerMovement>[],
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: CashDrawerScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cash In'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('cash-drawer-amount-field')),
      '10000',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add Cash'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(repository.addedAmount, 10000);
  });
}
