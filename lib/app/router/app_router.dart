import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/route_names.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/products/presentation/screens/products_screen.dart';
import '../../features/purchases/presentation/screens/create_purchase_screen.dart';
import '../../features/purchases/presentation/screens/purchase_details_screen.dart';
import '../../features/purchases/presentation/screens/purchases_list_screen.dart';
import '../../features/sales/presentation/sales_screen.dart';
import '../../features/inventory/presentation/inventory_screen.dart';
import '../../features/expenses/presentation/expenses_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/reports/presentation/screens/expense_report_screen.dart';
import '../../features/reports/presentation/screens/inventory_report_screen.dart';
import '../../features/reports/presentation/screens/low_stock_report_screen.dart';
import '../../features/reports/presentation/screens/profit_loss_report_screen.dart';
import '../../features/reports/presentation/screens/purchase_report_screen.dart';
import '../../features/reports/presentation/screens/sales_report_screen.dart';
import '../../features/settings/presentation/screens/backup_restore_screen.dart';
import '../../features/settings/presentation/screens/business_profile_screen.dart';
import '../../features/settings/presentation/screens/printer_settings_screen.dart';
import '../../features/settings/presentation/screens/receipt_settings_screen.dart';
import '../../features/settings/presentation/screens/settings_home_screen.dart';
import '../../features/settings/presentation/screens/system_preferences_screen.dart';
import 'app_shell.dart';

/// Application router configuration.
final GoRouter appRouter = GoRouter(
  initialLocation: RouteNames.dashboardPath,
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: RouteNames.root,
          redirect: (context, state) => RouteNames.dashboardPath,
        ),
        GoRoute(
          path: RouteNames.dashboardPath,
          name: RouteNames.dashboard,
          pageBuilder: (context, state) => _buildPage(
            state: state,
            child: const DashboardScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.productsPath,
          name: RouteNames.products,
          pageBuilder: (context, state) => _buildPage(
            state: state,
            child: const ProductsScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.purchasesPath,
          name: RouteNames.purchases,
          routes: [
            GoRoute(
              path: 'new',
              name: RouteNames.createPurchase,
              pageBuilder: (context, state) => _buildPage(
                state: state,
                child: const CreatePurchaseScreen(),
              ),
            ),
            GoRoute(
              path: ':id',
              name: RouteNames.purchaseDetails,
              pageBuilder: (context, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '');
                return _buildPage(
                  state: state,
                  child: id != null
                      ? PurchaseDetailsScreen(purchaseId: id)
                      : const Scaffold(
                          body: Center(child: Text('Purchase not found')),
                        ),
                );
              },
            ),
          ],
          pageBuilder: (context, state) => _buildPage(
            state: state,
            child: const PurchasesListScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.salesPath,
          name: RouteNames.sales,
          pageBuilder: (context, state) => _buildPage(
            state: state,
            child: const SalesScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.inventoryPath,
          name: RouteNames.inventory,
          pageBuilder: (context, state) => _buildPage(
            state: state,
            child: const InventoryScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.expensesPath,
          name: RouteNames.expenses,
          pageBuilder: (context, state) => _buildPage(
            state: state,
            child: const ExpensesScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.reportsPath,
          name: RouteNames.reports,
          routes: [
            GoRoute(
              path: 'sales',
              name: RouteNames.salesReport,
              pageBuilder: (context, state) => _buildPage(
                state: state,
                child: const SalesReportScreen(),
              ),
            ),
            GoRoute(
              path: 'purchases',
              name: RouteNames.purchaseReport,
              pageBuilder: (context, state) => _buildPage(
                state: state,
                child: const PurchaseReportScreen(),
              ),
            ),
            GoRoute(
              path: 'inventory',
              name: RouteNames.inventoryReport,
              pageBuilder: (context, state) => _buildPage(
                state: state,
                child: const InventoryReportScreen(),
              ),
            ),
            GoRoute(
              path: 'low-stock',
              name: RouteNames.lowStockReport,
              pageBuilder: (context, state) => _buildPage(
                state: state,
                child: const LowStockReportScreen(),
              ),
            ),
            GoRoute(
              path: 'expenses',
              name: RouteNames.expenseReport,
              pageBuilder: (context, state) => _buildPage(
                state: state,
                child: const ExpenseReportScreen(),
              ),
            ),
            GoRoute(
              path: 'profit-loss',
              name: RouteNames.profitLossReport,
              pageBuilder: (context, state) => _buildPage(
                state: state,
                child: const ProfitLossReportScreen(),
              ),
            ),
          ],
          pageBuilder: (context, state) => _buildPage(
            state: state,
            child: const ReportsScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.settingsPath,
          name: RouteNames.settings,
          routes: [
            GoRoute(
              path: 'business',
              name: RouteNames.businessProfile,
              pageBuilder: (context, state) => _buildPage(
                state: state,
                child: const BusinessProfileScreen(),
              ),
            ),
            GoRoute(
              path: 'receipt',
              name: RouteNames.receiptSettings,
              pageBuilder: (context, state) => _buildPage(
                state: state,
                child: const ReceiptSettingsScreen(),
              ),
            ),
            GoRoute(
              path: 'printer',
              name: RouteNames.printerSettings,
              pageBuilder: (context, state) => _buildPage(
                state: state,
                child: const PrinterSettingsScreen(),
              ),
            ),
            GoRoute(
              path: 'preferences',
              name: RouteNames.systemPreferences,
              pageBuilder: (context, state) => _buildPage(
                state: state,
                child: const SystemPreferencesScreen(),
              ),
            ),
            GoRoute(
              path: 'backup',
              name: RouteNames.backupRestore,
              pageBuilder: (context, state) => _buildPage(
                state: state,
                child: const BackupRestoreScreen(),
              ),
            ),
          ],
          pageBuilder: (context, state) => _buildPage(
            state: state,
            child: const SettingsHomeScreen(),
          ),
        ),
      ],
    ),
  ],
);

CustomTransitionPage<void> _buildPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}
