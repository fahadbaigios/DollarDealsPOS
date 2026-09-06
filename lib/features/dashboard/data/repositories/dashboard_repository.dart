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

  Expression<bool> _salesInRange(DateTime from, DateTime to) {
    return _db.sales.saleDate.isBiggerOrEqualValue(from) &
        _db.sales.saleDate.isSmallerOrEqualValue(to);
  }

  Expression<bool> _expensesInRange(DateTime from, DateTime to) {
    return _db.expenses.expenseDate.isBiggerOrEqualValue(from) &
        _db.expenses.expenseDate.isSmallerOrEqualValue(to);
  }

  /// Revenue = sum of sales.total_amount in date range.
  Future<double> getSalesTotal(DateTime from, DateTime to) async {
    final sumExpr = _db.sales.totalAmount.sum();
    final row = await (_db.selectOnly(_db.sales)
          ..addColumns([sumExpr])
          ..where(_salesInRange(from, to)))
        .getSingleOrNull();
    return row?.read(sumExpr) ?? 0.0;
  }

  /// COGS = sum of (sale_items.unit_cost * sale_items.quantity) for sales in range.
  Future<double> getCogs(DateTime from, DateTime to) async {
    final lineCost = _db.saleItems.unitCost * _db.saleItems.quantity;
    final sumExpr = lineCost.sum();
    final row = await (_db.selectOnly(_db.saleItems)
          ..addColumns([sumExpr])
          ..join([
            innerJoin(
              _db.sales,
              _db.sales.id.equalsExp(_db.saleItems.saleId),
            ),
          ])
          ..where(_salesInRange(from, to)))
        .getSingleOrNull();
    return row?.read(sumExpr) ?? 0.0;
  }

  /// Expenses = sum of expenses.amount in date range.
  Future<double> getExpensesTotal(DateTime from, DateTime to) async {
    final sumExpr = _db.expenses.amount.sum();
    final row = await (_db.selectOnly(_db.expenses)
          ..addColumns([sumExpr])
          ..where(_expensesInRange(from, to)))
        .getSingleOrNull();
    return row?.read(sumExpr) ?? 0.0;
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

    final rows = await (_db.select(_db.saleItems).join([
      innerJoin(
        _db.sales,
        _db.sales.id.equalsExp(_db.saleItems.saleId),
      ),
    ])
          ..where(_salesInRange(from, to)))
        .get();

    if (rows.isEmpty) return [];

    final items = rows.map((r) => r.readTable(_db.saleItems)).toList();
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

  Expression<bool> get _lowStockCondition {
    return _db.products.isActive.equals(true) &
        _db.products.reorderLevel.isBiggerThanValue(0) &
        _db.products.stockQuantity.isBiggerThanValue(0) &
        _db.products.stockQuantity.isSmallerOrEqual(_db.products.reorderLevel);
  }

  /// Count active products where stock <= reorder_level and stock > 0.
  Future<int> getLowStockCount() async {
    final countExpr = _db.products.id.count();
    final row = await (_db.selectOnly(_db.products)
          ..addColumns([countExpr])
          ..where(_lowStockCondition))
        .getSingle();
    return row.read(countExpr) ?? 0;
  }

  Future<int> getOutOfStockCount() async {
    final countExpr = _db.products.id.count();
    final row = await (_db.selectOnly(_db.products)
          ..addColumns([countExpr])
          ..where(_db.products.isActive.equals(true) &
              _db.products.stockQuantity.isSmallerOrEqualValue(0)))
        .getSingle();
    return row.read(countExpr) ?? 0;
  }

  Future<int> getTotalProductsCount() async {
    final countExpr = _db.products.id.count();
    final row =
        await (_db.selectOnly(_db.products)..addColumns([countExpr])).getSingle();
    return row.read(countExpr) ?? 0;
  }

  /// Low stock products (stock <= reorder_level and stock > 0).
  Future<List<Product>> getLowStockProducts({int limit = 10}) async {
    return (_db.select(_db.products)
          ..where((t) =>
              t.isActive.equals(true) &
              t.reorderLevel.isBiggerThanValue(0) &
              t.stockQuantity.isBiggerThanValue(0) &
              t.stockQuantity.isSmallerOrEqual(t.reorderLevel))
          ..orderBy([(t) => OrderingTerm.asc(t.name)])
          ..limit(limit))
        .get();
  }
}
