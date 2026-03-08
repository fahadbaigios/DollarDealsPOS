import 'package:flutter/material.dart';

import '../../../../database/database_constants.dart';

class PaymentStatusBadge extends StatelessWidget {
  const PaymentStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = _getStatusStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  (String, Color) _getStatusStyle(String s) {
    switch (s) {
      case DatabaseConstants.paymentStatusPaid:
        return ('Paid', Colors.green);
      case DatabaseConstants.paymentStatusPartial:
        return ('Partial', Colors.orange);
      default:
        return ('Unpaid', Colors.grey);
    }
  }
}
