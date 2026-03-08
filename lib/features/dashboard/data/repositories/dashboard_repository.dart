import 'package:drift/drift.dart';

import '../../../../database/app_database.dart';
import '../../domain/models/profit_loss_summary.dart';

/// Repository for dashboard and business insights.
/// Keeps financial calculation logic out of widgets.
class DashboardRepository {
  DashboardRepository(this._db);

  final AppDatabase _db;

  /// Today's date range (start and end of day).
  (DateTime, DateTime) get _todayRange {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return (start, end);
  }

  /// Current month date range.
  (DateTime, DateTime) get _monthRange {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return (start, end);
  }

  /// Revenue = sum of sales.total_amount in date range. = sum of sales.total_amount in date range.
  Future<double> getSalesTotal(DateTime from, DateTime to) async {
    final rows = await (_db.select(_db.sales)
          ..where((t) =>
              t.saleDate.isBiggerOrEqualValue(from) &
              t.saleDate.isSmallerOrEqualValue(to)))
        .get();
    return rows.fold<double>(0.0, (sum, s) => sum + s.totalAmount);
  }

  /// COGS = sum of (sale_items.unit_cost * sale_items.quantity) for sales in range.
  Future<double> getCogs(DateTime from, DateTime to) async {
    final rows = await (_db.selectOnly(_db.sales)
          ..addColumns([_db.sales.id])
          ..where(_db.sales.saleDate.isBiggerOrEqualValue(from) &
              _db.sales.saleDate.isSmallerOrEqualValue(to)))
        .get();
    final saleIds = rows.map((r) => r.read(_db.sales.id)).whereType<int>().toList();

    if (saleIds.isEmpty) return 0.0;

    final items = await (_db.select(_db.saleItems)
          ..where((t) => t.saleId.isIn(saleIds)))
        .get();
    return items.fold<double>(0.0, (sum, i) => sum + (i.unitCost * i.quantity));
  }

  /// Expenses = sum of expenses.amount in date range.
  Future<double> getExpensesTotal(DateTime from, DateTime to) async {
    final rows = await (_db.select(_db.expenses)
          ..where((t) =>
              t.expenseDate.isBiggerOrEqualValue(from) &
              t.expenseDate.isSmallerOrEqualValue(to)))
        .get();
    return rows.fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  Future<double> getTodaySalesTotal() async {
    final (from, to) = _todayRange;
    return getSalesTotal(from, to);
  }

  Future<double> getTodayExpensesTotal() async {
    final (from, to) = _todayRange;
    return getExpensesTotal(from, to);
  }

  Future<double> getMonthlySalesTotal() async {
    final (from, to) = _monthRange;
    return getSalesTotal(from, to);
  }

  Future<double> getMonthlyExpensesTotal() async {
    final (from, to) = _monthRange;
    return getExpensesTotal(from, to);
  }

  Future<ProfitLossSummary> getProfitLossSummary(DateTime from, DateTime to) async {
    final revenue = await getSalesTotal(from, to);
    final cogs = await getCogs(from, to);
    final expenses = await getExpensesTotal(from, to);
    final grossProfit = revenue - cogs;
    final netProfit = grossProfit - expenses;
    return ProfitLossSummary(
      revenue: revenue,
      cogs: cogs,
      grossProfit: grossProfit,
      expenses: expenses,
      netProfit: netProfit,
      from: from,
      to: to,
    );
  }

  Future<ProfitLossSummary> getTodayProfitLoss() async {
    final (from, to) = _todayRange;
    return getProfitLossSummary(from, to);
  }

  Future<ProfitLossSummary> getMonthlyProfitLoss() async {
    final (from, to) = _monthRange;
    return getProfitLossSummary(from, to);
  }

  Future<List<Sale>> getRecentSales({int limit = 10}) async {
    return (_db.select(_db.sales)
          ..orderBy([(t) => OrderingTerm.desc(t.saleDate)])
          ..limit(limit))
        .get();
  }

  Future<List<Expense>> getRecentExpenses({int limit = 10}) async {
    return (_db.select(_db.expenses)
          ..orderBy([(t) => OrderingTerm.desc(t.expenseDate)])
          ..limit(limit))
        .get();
  }

  /// Top selling products by quantity sold in current month.
  Future<List<({int productId, String name, double quantity, double revenue})>>
      getTopSellingProducts({int limit = 10}) async {
    final (from, to) = _monthRange;
    final rows = await (_db.selectOnly(_db.sales)
          ..addColumns([_db.sales.id])
          ..where(_db.sales.saleDate.isBiggerOrEqualValue(from) &
              _db.sales.saleDate.isSmallerOrEqualValue(to)))
        .get();
    final saleIds = rows.map((r) => r.read(_db.sales.id)).whereType<int>().toList();

    if (saleIds.isEmpty) return [];

    final items = await (_db.select(_db.saleItems)
          ..where((t) => t.saleId.isIn(saleIds)))
        .get();

    final productIds = items.map((i) => i.productId).toSet().toList();
    final products = await (_db.select(_db.products)
          ..where((t) => t.id.isIn(productIds)))
        .get();
    final productMap = {for (final p in products) p.id: p};

    final totals = <int, ({double quantity, double revenue})>{};
    for (final i in items) {
      final cur = totals[i.productId] ?? (quantity: 0.0, revenue: 0.0);
      totals[i.productId] = (
        quantity: cur.quantity + i.quantity,
        revenue: cur.revenue + i.totalAmount,
      );
    }

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.quantity.compareTo(a.value.quantity));

    return sorted.take(limit).map((e) {
      final p = productMap[e.key];
      return (
        productId: e.key,
        name: p?.name ?? 'Unknown',
        quantity: e.value.quantity,
        revenue: e.value.revenue,
      );
    }).toList();
  }

  /// Count active products where stock <= reorder_level and stock > 0.
  Future<int> getLowStockCount() async {
    final products = await (_db.select(_db.products)
          ..where((t) => t.isActive.equals(true)))
        .get();
    return products
        .where((p) =>
            p.reorderLevel > 0 &&
            p.stockQuantity > 0 &&
            p.stockQuantity <= p.reorderLevel)
        .length;
  }

  Future<int> getOutOfStockCount() async {
    final list = await (_db.select(_db.products)
          ..where((t) =>
              t.isActive.equals(true) &
              t.stockQuantity.isSmallerOrEqualValue(0)))
        .get();
    return list.length;
  }

  Future<int> getTotalProductsCount() async {
    final list = await _db.select(_db.products).get();
    return list.length;
  }

  /// Low stock products (stock <= reorder_level and stock > 0).
  Future<List<Product>> getLowStockProducts({int limit = 10}) async {
    final products = await (_db.select(_db.products)
          ..where((t) => t.isActive.equals(true)))
        .get();
    final lowStock = products
        .where((p) =>
            p.reorderLevel > 0 &&
            p.stockQuantity > 0 &&
            p.stockQuantity <= p.reorderLevel)
        .take(limit)
        .toList();
    return lowStock;
  }
}
