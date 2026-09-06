import 'package:drift/drift.dart';

import 'held_carts_table.dart';
import 'products_table.dart';

/// Line items belonging to a [HeldCarts] entry. Deleted automatically when
/// the parent held cart is deleted (discarded or resumed).
class HeldCartItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get heldCartId =>
      integer().references(HeldCarts, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().references(Products, #id)();
  RealColumn get quantity => real()();
  RealColumn get unitCost => real()();
  RealColumn get unitPrice => real()();
  RealColumn get itemDiscount => real().withDefault(const Constant(0))();
  RealColumn get itemTax => real().withDefault(const Constant(0))();
}
