import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';

class ReportsHomeScreen extends StatelessWidget {
  const ReportsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = [
      (RouteNames.salesReportPath, 'Sales Report', Icons.point_of_sale, Colors.green),
      (RouteNames.purchaseReportPath, 'Purchase Report', Icons.shopping_cart, Colors.blue),
      (RouteNames.inventoryReportPath, 'Inventory Report', Icons.inventory_2, Colors.indigo),
      (RouteNames.lowStockReportPath, 'Low Stock Report', Icons.warning_amber, Colors.amber),
      (RouteNames.expenseReportPath, 'Expense Report', Icons.receipt_long, Colors.orange),
      (RouteNames.profitLossReportPath, 'Profit/Loss Report', Icons.account_balance_wallet, Colors.teal),
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Reports',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a report to view business analytics',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 900 ? 3 : 2;
              return GridView.count(
                shrinkWrap: true,
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: reports.map((r) => _ReportCard(
                      path: r.$1,
                      title: r.$2,
                      icon: r.$3,
                      color: r.$4,
                    )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.path,
    required this.title,
    required this.icon,
    required this.color,
  });

  final String path;
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.go(path),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
