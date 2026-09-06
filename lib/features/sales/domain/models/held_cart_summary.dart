/// Lightweight summary of a held cart, used for the "resume hold" list.
class HeldCartSummary {
  const HeldCartSummary({
    required this.id,
    required this.label,
    required this.itemCount,
    required this.totalAmount,
    required this.createdAt,
    this.customerName,
  });

  final int id;
  final String label;
  final int itemCount;
  final double totalAmount;
  final DateTime createdAt;
  final String? customerName;
}
