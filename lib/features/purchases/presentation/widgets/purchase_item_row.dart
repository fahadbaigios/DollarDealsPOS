import 'package:flutter/material.dart';

import '../../../../database/app_database.dart';

class PurchaseItemRow {
  PurchaseItemRow._();

  static Widget buildProductCell({
    required Product product,
    required List<Product> products,
    required ValueChanged<Product> onProductChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
      child: DropdownButtonFormField<Product>(
        value: product,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(),
        ),
        items: products
            .map((p) => DropdownMenuItem(
                  value: p,
                  child: Text(
                    '${p.name} (${p.sku})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
            .toList(),
        onChanged: (p) => p != null ? onProductChanged(p) : null,
      ),
    );
  }

  static Widget buildNumberCell({
    required double value,
    required ValueChanged<double> onChanged,
    double min = 0,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
      child: TextFormField(
        initialValue: value == 0 ? '' : value.toString(),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (v) {
          final n = double.tryParse(v) ?? min;
          onChanged(n < min ? min : n);
        },
      ),
    );
  }
}
