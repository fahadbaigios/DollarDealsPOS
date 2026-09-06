import 'cart_item.dart';

/// Full detail of a held cart, used to restore it into the active POS cart.
class HeldCartFull {
  const HeldCartFull({
    required this.id,
    required this.label,
    required this.customerId,
    required this.paymentMethodId,
    required this.orderDiscount,
    required this.items,
    this.skippedItemNames = const [],
  });

  final int id;
  final String label;
  final int? customerId;
  final int? paymentMethodId;
  final double orderDiscount;
  final List<CartItem> items;

  /// Names/ids of items that were on this held cart but could no longer be
  /// restored (e.g. the product was deleted since it was held) and were
  /// dropped rather than failing the whole resume.
  final List<String> skippedItemNames;
}
