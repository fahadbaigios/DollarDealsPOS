import 'package:drift/drift.dart';

import '../../../../database/app_database.dart';
import '../../domain/models/expense_report_result.dart';
import '../../domain/models/expense_report_row.dart';
import '../../domain/models/inventory_report_result.dart';
import '../../domain/models/inventory_report_row.dart';
import '../../../dashboard/domain/models/profit_loss_summary.dart';
import '../../domain/models/profit_loss_report_result.dart';
import '../../domain/models/purchase_report_result.dart';
import '../../domain/models/purchase_report_row.dart';
import '../../domain/models/report_filter_state.dart';
import '../../domain/models/sales_report_result.dart';
import '../../domain/models/sales_report_row.dart';

/// Central repository for all report data.
/// Keeps SQL/Drift logic out of widgets.
class ReportsRepository {
  ReportsRepository(this._db);

  final AppDatabase _db;

  Future<SalesReportResult> getSalesReport(ReportFilterState filter) async {
    var query = _db.select(_db.sales);
    final where = _buildSalesWhere(filter);
    if (where != null) {
      query = query..where((t) => where);
    }
    final sales = await (query..orderBy([(t) => OrderingTerm.desc(t.saleDate)])).get();

    final customerIds = sales.map((s) => s.customerId).whereType<int>().toSet().toList();
    final cashierIds = sales.map((s) => s.cashierId).toSet().toList();

    final customers = customerIds.isEmpty
        ? <Customer>[]
        : await (_db.select(_db.customers)..where((t) => t.id.isIn(customerIds))).get();
    final users = await (_db.select(_db.users)..where((t) => t.id.isIn(cashierIds))).get();

    final customerMap = {for (final c in customers) c.id: c.name};
    final userMap = {for (final u in users) u.id: u.fullName};

    final rows = sales.map((s) => SalesReportRow(
          sale: s,
          customerName: s.customerId != null ? customerMap[s.customerId] : null,
          cashierName: userMap[s.cashierId],
        )).toList();

    final totalRevenue = rows.fold<double>(0, (sum, r) => sum + r.total);
    final totalDiscount = rows.fold<double>(0, (sum, r) => sum + r.discount);
    final totalTax = rows.fold<double>(0, (sum, r) => sum + r.tax);
    final totalDue = rows.fold<double>(0, (sum, r) => sum + r.due);

    return SalesReportResult(
      rows: rows,
      totalCount: rows.length,
      totalRevenue: totalRevenue,
      totalDiscount: totalDiscount,
      totalTax: totalTax,
      totalDue: totalDue,
    );
  }

  Expression<bool>? _buildSalesWhere(ReportFilterState filter) {
    Expression<bool>? cond;
    if (filter.dateRange != null) {
      cond = _db.sales.saleDate.isBiggerOrEqualValue(filter.dateRange!.from) &
          _db.sales.saleDate.isSmallerOrEqualValue(filter.dateRange!.to);
    }
    if (filter.searchQuery.trim().isNotEmpty) {
      final q = filter.searchQuery.trim().toLowerCase();
      final searchCond = _db.sales.invoiceNumber.lower().like('%$q%');
      cond = cond == null ? searchCond : cond & searchCond;
    }
    if (filter.cashierId != null) {
      final c = _db.sales.cashierId.equals(filter.cashierId!);
      cond = cond == null ? c : cond & c;
    }
    if (filter.customerId != null) {
      final c = _db.sales.customerId.equals(filter.customerId!);
      cond = cond == null ? c : cond & c;
    }
    return cond;
  }

  Future<PurchaseReportResult> getPurchaseReport(ReportFilterState filter) async {
    var query = _db.select(_db.purchases);
    final where = _buildPurchaseWhere(filter);
    if (where != null) {
      query = query..where((t) => where);
    }
    final purchases = await (query
          ..orderBy([(t) => OrderingTerm.desc(t.purchaseDate)]))
        .get();

    final supplierIds = purchases.map((p) => p.supplierId).toSet().toList();
    final createdByIds = purchases.map((p) => p.createdBy).whereType<int>().toSet().toList();

    final suppliers = await (_db.select(_db.suppliers)
          ..where((t) => t.id.isIn(supplierIds)))
        .get();
    final users = createdByIds.isEmpty
        ? <User>[]
        : await (_db.select(_db.users)..where((t) => t.id.isIn(createdByIds))).get();

    final supplierMap = {for (final s in suppliers) s.id: s.name};
    final userMap = {for (final u in users) u.id: u.fullName};

    final rows = purchases.map((p) => PurchaseReportRow(
          purchase: p,
          supplierName: supplierMap[p.supplierId],
          createdByName: p.createdBy != null ? userMap[p.createdBy] : null,
        )).toList();

    final totalValue = rows.fold<double>(0, (sum, r) => sum + r.total);
    final totalPaid = rows.fold<double>(0, (sum, r) => sum + r.paid);
    final totalDue = rows.fold<double>(0, (sum, r) => sum + r.due);

    return PurchaseReportResult(
      rows: rows,
      totalCount: rows.length,
      totalValue: totalValue,
      totalPaid: totalPaid,
      totalDue: totalDue,
    );
  }

  Expression<bool>? _buildPurchaseWhere(ReportFilterState filter) {
    Expression<bool>? cond;
    if (filter.dateRange != null) {
      cond = _db.purchases.purchaseDate.isBiggerOrEqualValue(filter.dateRange!.from) &
          _db.purchases.purchaseDate.isSmallerOrEqualValue(filter.dateRange!.to);
    }
    if (filter.searchQuery.trim().isNotEmpty) {
      final q = filter.searchQuery.trim().toLowerCase();
      final searchCond = (_db.purchases.invoiceNumber.isNotNull() &
              _db.purchases.invoiceNumber.like('%$q%')) |
          _db.purchases.notes.like('%$q%');
      cond = cond == null ? searchCond : cond & searchCond;
    }
    if (filter.supplierId != null) {
      final s = _db.purchases.supplierId.equals(filter.supplierId!);
      cond = cond == null ? s : cond & s;
    }
    return cond;
  }

  Future<InventoryReportResult> getInventoryReport(ReportFilterState filter) async {
    var query = _db.select(_db.products);
    final where = _buildInventoryWhere(filter);
    if (where != null) {
      query = query..where((t) => where);
    }
    final products = await (query..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

    final categoryIds = products.map((p) => p.categoryId).toSet().toList();
    final supplierIds = products.map((p) => p.supplierId).whereType<int>().toSet().toList();
    final unitIds = products.map((p) => p.unitId).toSet().toList();

    final categories = await (_db.select(_db.categories)
          ..where((t) => t.id.isIn(categoryIds)))
        .get();
    final suppliers = supplierIds.isEmpty
        ? <Supplier>[]
        : await (_db.select(_db.suppliers)..where((t) => t.id.isIn(supplierIds))).get();
    final units = await (_db.select(_db.units)..where((t) => t.id.isIn(unitIds))).get();

    final catMap = {for (final c in categories) c.id: c.name};
    final supMap = {for (final s in suppliers) s.id: s.name};
    final unitMap = {for (final u in units) u.id: u.name};

    final rows = products.map((p) => InventoryReportRow(
          product: p,
          categoryName: catMap[p.categoryId] ?? '—',
          supplierName: p.supplierId != null ? supMap[p.supplierId] : null,
          unitName: unitMap[p.unitId] ?? '—',
        )).toList();

    var totalStockQty = 0.0;
    var totalCost = 0.0;
    var totalSelling = 0.0;
    var lowStock = 0;
    var outOfStock = 0;
    for (final r in rows) {
      totalStockQty += r.stockQuantity;
      totalCost += r.stockValueAtCost;
      totalSelling += r.stockValueAtSelling;
      if (r.product.stockQuantity <= 0) {
        outOfStock++;
      } else if (r.product.reorderLevel > 0 &&
          r.product.stockQuantity <= r.product.reorderLevel) {
        lowStock++;
      }
    }

    return InventoryReportResult(
      rows: rows,
      totalProducts: rows.length,
      totalStockQuantity: totalStockQty,
      totalStockValueAtCost: totalCost,
      totalStockValueAtSelling: totalSelling,
      lowStockCount: lowStock,
      outOfStockCount: outOfStock,
    );
  }

  Expression<bool>? _buildInventoryWhere(ReportFilterState filter) {
    Expression<bool>? cond;
    if (filter.searchQuery.trim().isNotEmpty) {
      final q = filter.searchQuery.trim().toLowerCase();
      cond = _db.products.name.lower().like('%$q%') |
          _db.products.sku.lower().like('%$q%') |
          (_db.products.barcode.isNotNull() & _db.products.barcode.like('%$q%'));
    }
    if (filter.categoryId != null) {
      final c = _db.products.categoryId.equals(filter.categoryId!);
      cond = cond == null ? c : cond & c;
    }
    if (!filter.includeInactive) {
      final a = _db.products.isActive.equals(true);
      cond = cond == null ? a : cond & a;
    }
    return cond;
  }

  Future<List<InventoryReportRow>> getLowStockReport(ReportFilterState filter) async {
    var query = _db.select(_db.products);
    Expression<bool>? where;
    if (!filter.includeInactive) {
      where = _db.products.isActive.equals(true);
    }
    if (filter.searchQuery.trim().isNotEmpty) {
      final q = filter.searchQuery.trim().toLowerCase();
      final searchCond = _db.products.name.lower().like('%$q%') |
          _db.products.sku.lower().like('%$q%') |
          (_db.products.barcode.isNotNull() & _db.products.barcode.like('%$q%'));
      where = where == null ? searchCond : where & searchCond;
    }
    if (filter.categoryId != null) {
      final c = _db.products.categoryId.equals(filter.categoryId!);
      where = where == null ? c : where & c;
    }
    if (where != null) {
      query = query..where((t) => where!);
    }
    final allProducts = await (query..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
    final products = allProducts
        .where((p) =>
            p.stockQuantity <= 0 ||
            (p.reorderLevel > 0 && p.stockQuantity <= p.reorderLevel))
        .toList();

    final categoryIds = products.map((p) => p.categoryId).toSet().toList();
    final supplierIds = products.map((p) => p.supplierId).whereType<int>().toSet().toList();
    final unitIds = products.map((p) => p.unitId).toSet().toList();

    final categories = await (_db.select(_db.categories)
          ..where((t) => t.id.isIn(categoryIds)))
        .get();
    final suppliers = supplierIds.isEmpty
        ? <Supplier>[]
        : await (_db.select(_db.suppliers)..where((t) => t.id.isIn(supplierIds))).get();
    final units = await (_db.select(_db.units)..where((t) => t.id.isIn(unitIds))).get();

    final catMap = {for (final c in categories) c.id: c.name};
    final supMap = {for (final s in suppliers) s.id: s.name};
    final unitMap = {for (final u in units) u.id: u.name};

    return products.map((p) => InventoryReportRow(
          product: p,
          categoryName: catMap[p.categoryId] ?? '—',
          supplierName: p.supplierId != null ? supMap[p.supplierId] : null,
          unitName: unitMap[p.unitId] ?? '—',
        )).toList();
  }

  Future<ExpenseReportResult> getExpenseReport(ReportFilterState filter) async {
    var query = _db.select(_db.expenses);
    final where = _buildExpenseWhere(filter);
    if (where != null) {
      query = query..where((t) => where);
    }
    final expenses = await (query
          ..orderBy([(t) => OrderingTerm.desc(t.expenseDate)]))
        .get();

    final categoryIds = expenses.map((e) => e.expenseCategoryId).toSet().toList();
    final pmIds = expenses.map((e) => e.paymentMethodId).whereType<int>().toSet().toList();

    final categories = await (_db.select(_db.expenseCategories)
          ..where((t) => t.id.isIn(categoryIds)))
        .get();
    final pms = pmIds.isEmpty
        ? <PaymentMethod>[]
        : await (_db.select(_db.paymentMethods)..where((t) => t.id.isIn(pmIds))).get();

    final catMap = {for (final c in categories) c.id: c.name};
    final pmMap = {for (final p in pms) p.id: p.name};

    final rows = expenses.map((e) => ExpenseReportRow(
          expense: e,
          categoryName: catMap[e.expenseCategoryId] ?? '—',
          paymentMethodName: e.paymentMethodId != null ? pmMap[e.paymentMethodId] : null,
        )).toList();

    final totalAmount = rows.fold<double>(0, (sum, r) => sum + r.amount);
    final largest = rows.isEmpty ? null : rows.map((r) => r.amount).reduce((a, b) => a > b ? a : b);
    final categoryTotals = <String, double>{};
    for (final r in rows) {
      categoryTotals[r.categoryName] = (categoryTotals[r.categoryName] ?? 0) + r.amount;
    }

    return ExpenseReportResult(
      rows: rows,
      totalCount: rows.length,
      totalAmount: totalAmount,
      largestExpense: largest,
      categoryTotals: categoryTotals,
    );
  }

  Expression<bool>? _buildExpenseWhere(ReportFilterState filter) {
    Expression<bool>? cond;
    if (filter.dateRange != null) {
      cond = _db.expenses.expenseDate.isBiggerOrEqualValue(filter.dateRange!.from) &
          _db.expenses.expenseDate.isSmallerOrEqualValue(filter.dateRange!.to);
    }
    if (filter.searchQuery.trim().isNotEmpty) {
      final q = filter.searchQuery.trim().toLowerCase();
      final searchCond = _db.expenses.title.lower().like('%$q%') |
          (_db.expenses.notes.isNotNull() & _db.expenses.notes.like('%$q%'));
      cond = cond == null ? searchCond : cond & searchCond;
    }
    if (filter.expenseCategoryId != null) {
      final c = _db.expenses.expenseCategoryId.equals(filter.expenseCategoryId!);
      cond = cond == null ? c : cond & c;
    }
    return cond;
  }

  Future<ProfitLossReportResult> getProfitLossReport(ReportFilterState filter) async {
    if (filter.dateRange == null) {
      return ProfitLossReportResult(
        summary: ProfitLossSummary(
          revenue: 0,
          cogs: 0,
          grossProfit: 0,
          expenses: 0,
          netProfit: 0,
          from: DateTime.now(),
          to: DateTime.now(),
        ),
      );
    }
    final from = filter.dateRange!.from;
    final to = filter.dateRange!.to;

    final revenue = await _getSalesTotal(from, to);
    final cogs = await _getCogs(from, to);
    final expenses = await _getExpensesTotal(from, to);
    final grossProfit = revenue - cogs;
    final netProfit = grossProfit - expenses;

    final summary = ProfitLossSummary(
      revenue: revenue,
      cogs: cogs,
      grossProfit: grossProfit,
      expenses: expenses,
      netProfit: netProfit,
      from: from,
      to: to,
    );

    final topSelling = await _getTopSellingProducts(from, to, limit: 10);
    final expenseByCat = await _getExpenseByCategory(from, to);

    return ProfitLossReportResult(
      summary: summary,
      topSellingProducts: topSelling,
      expenseByCategory: expenseByCat,
    );
  }

  Future<double> _getSalesTotal(DateTime from, DateTime to) async {
    final rows = await (_db.select(_db.sales)
          ..where((t) =>
              t.saleDate.isBiggerOrEqualValue(from) &
              t.saleDate.isSmallerOrEqualValue(to)))
        .get();
    return rows.fold<double>(0, (sum, s) => sum + s.totalAmount);
  }

  Future<double> _getCogs(DateTime from, DateTime to) async {
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
    return items.fold<double>(0, (sum, i) => sum + (i.unitCost * i.quantity));
  }

  Future<double> _getExpensesTotal(DateTime from, DateTime to) async {
    final rows = await (_db.select(_db.expenses)
          ..where((t) =>
              t.expenseDate.isBiggerOrEqualValue(from) &
              t.expenseDate.isSmallerOrEqualValue(to)))
        .get();
    return rows.fold<double>(0, (sum, e) => sum + e.amount);
  }

  Future<List<({int productId, String name, double quantity, double revenue})>>
      _getTopSellingProducts(DateTime from, DateTime to, {int limit = 10}) async {
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

  Future<Map<String, double>> _getExpenseByCategory(DateTime from, DateTime to) async {
    final expenses = await (_db.select(_db.expenses)
          ..where((t) =>
              t.expenseDate.isBiggerOrEqualValue(from) &
              t.expenseDate.isSmallerOrEqualValue(to)))
        .get();
    if (expenses.isEmpty) return {};
    final catIds = expenses.map((e) => e.expenseCategoryId).toSet().toList();
    final categories = await (_db.select(_db.expenseCategories)
          ..where((t) => t.id.isIn(catIds)))
        .get();
    final catMap = {for (final c in categories) c.id: c.name};
    final result = <String, double>{};
    for (final e in expenses) {
      final name = catMap[e.expenseCategoryId] ?? 'Unknown';
      result[name] = (result[name] ?? 0) + e.amount;
    }
    return result;
  }

  Future<List<User>> getUsersForFilter() async {
    return (_db.select(_db.users)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.fullName)]))
        .get();
  }

  Future<List<Customer>> getCustomersForFilter() async {
    return (_db.select(_db.customers)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<List<Supplier>> getSuppliersForFilter() async {
    return (_db.select(_db.suppliers)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<List<Category>> getCategoriesForFilter() async {
    return (_db.select(_db.categories)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<List<ExpenseCategory>> getExpenseCategoriesForFilter() async {
    return (_db.select(_db.expenseCategories)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }
}
