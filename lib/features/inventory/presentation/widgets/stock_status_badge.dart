import 'package:flutter/material.dart';

/// Badge for stock status: Normal, Low Stock, Out of Stock, Inactive.
class StockStatusBadge extends StatelessWidget {
  const StockStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _statusStyle(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  static (String label, Color color) _statusStyle(String status) {
    switch (status) {
      case 'normal':
        return ('Normal', Colors.green);
      case 'low_stock':
        return ('Low Stock', Colors.orange);
      case 'out_of_stock':
        return ('Out of Stock', Colors.red);
      case 'inactive':
        return ('Inactive', Colors.grey);
      default:
        return (status, Colors.grey);
    }
  }
}
