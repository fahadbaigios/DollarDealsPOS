import 'package:drift/drift.dart';

import '../../../../database/app_database.dart';
import '../../domain/models/cart_item.dart';
import '../../domain/models/held_cart_full.dart';
import '../../domain/models/held_cart_summary.dart';

/// Repository for "hold cart" (a.k.a. park sale) - lets a cashier stash
/// the current in-progress cart to serve another customer, then resume it
/// later exactly where it left off.
class HeldCartsRepository {
  HeldCartsRepository(this._db);

  final AppDatabase _db;

  /// Saves [items] plus the in-progress order state as a new held cart.
  /// Returns the new held cart's id.
  Future<int> holdCart({
    required List<CartItem> items,
    String? label,
    int? customerId,
    int? paymentMethodId,
    double orderDiscount = 0,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('Cannot hold an empty cart');
    }

    return _db.transaction(() async {
      final trimmedLabel = label?.trim();
      final id = await _db.into(_db.heldCarts).insert(
            HeldCartsCompanion.insert(
              label: (trimmedLabel == null || trimmedLabel.isEmpty)
                  ? const Value.absent()
                  : Value(trimmedLabel),
              customerId:
                  customerId == null ? const Value.absent() : Value(customerId),
              paymentMethodId: paymentMethodId == null
                  ? const Value.absent()
                  : Value(paymentMethodId),
              orderDiscount: Value(orderDiscount),
            ),
          );

      for (final item in items) {
        await _db.into(_db.heldCartItems).insert(
              HeldCartItemsCompanion.insert(
                heldCartId: id,
                productId: item.product.id,
                quantity: item.quantity,
                unitCost: item.unitCost,
                unitPrice: item.unitPrice,
                itemDiscount: Value(item.itemDiscount),
                itemTax: Value(item.itemTax),
              ),
            );
      }

      return id;
    });
  }

  /// Watches all currently held carts (newest first) as lightweight
  /// summaries, for the "resume hold" list. The held-carts table is
  /// expected to stay tiny (a handful of concurrently parked sales at
  /// most), so resolving item counts/totals per-cart in Dart is simpler
  /// and safer than a SQL aggregate join here.
  Stream<List<HeldCartSummary>> watchAll() async* {
    await for (final carts in (_db.select(_db.heldCarts)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()) {
      if (carts.isEmpty) {
        yield [];
        continue;
      }

      final summaries = <HeldCartSummary>[];
      for (final cart in carts) {
        final items = await (_db.select(_db.heldCartItems)
              ..where((t) => t.heldCartId.equals(cart.id)))
            .get();
        final total = items.fold<double>(
          0,
          (sum, i) => sum + (i.quantity * i.unitPrice - i.itemDiscount + i.itemTax),
        );
        final discounted = (total - cart.orderDiscount).clamp(0.0, double.infinity);

        String? customerName;
        if (cart.customerId != null) {
          final customer = await (_db.select(_db.customers)
                ..where((t) => t.id.equals(cart.customerId!)))
              .getSingleOrNull();
          customerName = customer?.name;
        }

        summaries.add(HeldCartSummary(
          id: cart.id,
          label: cart.label ?? 'Hold #${cart.id}',
          itemCount: items.length,
          totalAmount: discounted,
          createdAt: cart.createdAt,
          customerName: customerName,
        ));
      }
      yield summaries;
    }
  }

  /// Loads full detail for resuming a held cart into the active POS cart.
  /// Products deleted since the cart was held are skipped rather than
  /// failing the whole resume; their names/ids are reported back so the
  /// caller can inform the cashier.
  Future<HeldCartFull?> getFull(int id) async {
    final cart = await (_db.select(_db.heldCarts)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (cart == null) return null;

    final itemRows = await (_db.select(_db.heldCartItems)
          ..where((t) => t.heldCartId.equals(id)))
        .get();

    final items = <CartItem>[];
    final skipped = <String>[];

    for (final row in itemRows) {
      final product = await (_db.select(_db.products)
            ..where((t) => t.id.equals(row.productId)))
          .getSingleOrNull();
      if (product == null) {
        skipped.add('Product #${row.productId}');
        continue;
      }
      final unit = await (_db.select(_db.units)
            ..where((t) => t.id.equals(product.unitId)))
          .getSingleOrNull();
      items.add(CartItem(
        product: product,
        unitName: unit?.name ?? 'pc',
        quantity: row.quantity,
        unitCost: row.unitCost,
        unitPrice: row.unitPrice,
        itemDiscount: row.itemDiscount,
        itemTax: row.itemTax,
      ));
    }

    return HeldCartFull(
      id: cart.id,
      label: cart.label ?? 'Hold #${cart.id}',
      customerId: cart.customerId,
      paymentMethodId: cart.paymentMethodId,
      orderDiscount: cart.orderDiscount,
      items: items,
      skippedItemNames: skipped,
    );
  }

  /// Deletes a held cart and its items (items cascade automatically).
  /// Used both to discard a hold and to "consume" one when it's resumed.
  Future<void> delete(int id) async {
    await (_db.delete(_db.heldCarts)..where((t) => t.id.equals(id))).go();
  }
}
