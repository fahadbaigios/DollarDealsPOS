import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_dollar_deals_inventory_system/database/app_database.dart';
import 'package:one_dollar_deals_inventory_system/features/cash_drawer/data/repositories/cash_drawer_repository.dart';
import 'package:one_dollar_deals_inventory_system/features/sales/data/repositories/customers_repository.dart';
import 'package:one_dollar_deals_inventory_system/features/sales/data/repositories/sales_repository.dart';
import 'package:one_dollar_deals_inventory_system/features/sales/data/repositories/users_repository.dart';
import 'package:one_dollar_deals_inventory_system/features/sales/domain/models/cart_item.dart';
import 'package:one_dollar_deals_inventory_system/features/sales/domain/services/sales_checkout_service.dart';

void main() {
  test(
    'cash in, cash sale, and daily cash out keep the change float',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final drawer = CashDrawerRepository(db);
      final sales = SalesCheckoutService(
        db,
        SalesRepository(db, CustomersRepository(db), UsersRepository(db)),
      );
      final paymentMethods = await db.select(db.paymentMethods).get();
      final cashId = paymentMethods
          .singleWhere((method) => method.name == 'Cash')
          .id;
      final cardId = paymentMethods
          .singleWhere((method) => method.name == 'Card')
          .id;

      final productId = await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              categoryId: 1,
              unitId: 1,
              name: 'Drawer Test Product',
              sku: 'DRAWER-TEST-1',
              costPrice: const Value(400),
              salePrice: const Value(750),
              stockQuantity: const Value(10),
            ),
          );
      final product = await (db.select(
        db.products,
      )..where((t) => t.id.equals(productId))).getSingle();

      await drawer.addCashIn(amount: 10000, note: 'Morning change');
      await sales.completeSale(
        items: [
          CartItem(
            product: product,
            unitName: 'pc',
            quantity: 1,
            unitCost: 400,
            unitPrice: 750,
          ),
        ],
        cashierId: 1,
        paymentMethodId: cashId,
        paidAmount: 1000,
      );

      var summary = await drawer.getSummary();
      expect(summary.balanceMinor, 1075000);
      expect(summary.todayCashSalesMinor, 75000);
      expect(summary.todayCashInMinor, 1000000);
      expect(summary.suggestedCashOutMinor, 75000);

      await sales.completeSale(
        items: [
          CartItem(
            product: product,
            unitName: 'pc',
            quantity: 1,
            unitCost: 400,
            unitPrice: 500,
          ),
        ],
        cashierId: 1,
        paymentMethodId: cardId,
        paidAmount: 500,
      );

      summary = await drawer.getSummary();
      expect(summary.balanceMinor, 1075000);
      expect(summary.todayCashSalesMinor, 75000);

      final history = await SalesRepository(
        db,
        CustomersRepository(db),
        UsersRepository(db),
      ).searchPaginated(page: 0, pageSize: 50);
      expect(
        history.paymentMethodNamesBySaleId.values.toSet(),
        containsAll(<String>{'Cash', 'Card'}),
      );

      await drawer.addCashOut(amount: 750, note: 'Daily cash out');
      summary = await drawer.getSummary();
      expect(summary.balanceMinor, 1000000);
      expect(summary.todayCashOutMinor, 75000);
      expect(summary.suggestedCashOutMinor, 0);

      final activity = await drawer.getRecentActivity();
      expect(activity, hasLength(3));
      expect(
        activity.where(
          (movement) =>
              movement.movementType == CashDrawerRepository.cashSaleType,
        ),
        hasLength(1),
      );
    },
  );

  test('cash out cannot exceed the expected drawer balance', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final drawer = CashDrawerRepository(db);

    await drawer.addCashIn(amount: 100);

    await expectLater(
      drawer.addCashOut(amount: 101),
      throwsA(isA<StateError>()),
    );
    expect((await drawer.getSummary()).balanceMinor, 10000);
  });

  test('migration replaces the discarded drawer schema safely', () async {
    final directory = await Directory.systemTemp.createTemp(
      'cash-drawer-migration-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final databaseFile = File('${directory.path}/app.sqlite');

    final oldDb = AppDatabase.forTesting(NativeDatabase(databaseFile));
    await oldDb.customSelect('SELECT 1').get();
    await oldDb.customStatement('DROP TABLE cash_drawer_movements;');
    await oldDb.customStatement('''
      CREATE TABLE cash_drawer_sessions (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT
      );
    ''');
    await oldDb.customStatement('''
      CREATE TABLE cash_denominations (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT
      );
    ''');
    await oldDb.customStatement('''
      CREATE TABLE cash_drawer_movements (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL REFERENCES cash_drawer_sessions(id),
        type TEXT NOT NULL,
        delta_minor INTEGER NOT NULL
      );
    ''');
    await oldDb.customStatement('''
      CREATE TABLE cash_drawer_movement_notes (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        movement_id INTEGER NOT NULL REFERENCES cash_drawer_movements(id),
        denomination_id INTEGER NOT NULL REFERENCES cash_denominations(id)
      );
    ''');
    await oldDb.customStatement('PRAGMA user_version = 12;');
    await oldDb.close();

    final migratedDb = AppDatabase.forTesting(NativeDatabase(databaseFile));
    addTearDown(migratedDb.close);
    final drawer = CashDrawerRepository(migratedDb);

    await drawer.addCashIn(amount: 10000, note: 'Morning change');

    final summary = await drawer.getSummary();
    expect(summary.balanceMinor, 1000000);
    final columns = await migratedDb
        .customSelect("PRAGMA table_info('cash_drawer_movements')")
        .get();
    expect(
      columns.map((row) => row.read<String>('name')),
      containsAll(<String>['movement_type', 'amount_minor']),
    );
  });
}
