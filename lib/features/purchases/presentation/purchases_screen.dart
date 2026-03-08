import 'package:flutter/material.dart';

class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Purchases', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            Text('Purchase orders and stock intake'),
          ],
        ),
      ),
    );
  }
}
