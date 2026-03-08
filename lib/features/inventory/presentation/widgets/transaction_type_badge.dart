import 'package:flutter/material.dart';

/// Badge for inventory transaction type with color coding.
class TransactionTypeBadge extends StatelessWidget {
  const TransactionTypeBadge({
    super.key,
    required this.transactionType,
    this.compact = false,
  });

  final String transactionType;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _typeStyle(transactionType);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  static (String label, Color color) _typeStyle(String type) {
    switch (type) {
      case 'purchase':
        return ('Purchase', Colors.green);
      case 'sale':
        return ('Sale', Colors.blue);
      case 'return_in':
        return ('Return In', Colors.teal);
      case 'return_out':
        return ('Return Out', Colors.orange);
      case 'adjustment_in':
        return ('Adjust In', Colors.green.shade700);
      case 'adjustment_out':
        return ('Adjust Out', Colors.red.shade700);
      default:
        return (type, Colors.grey);
    }
  }
}
