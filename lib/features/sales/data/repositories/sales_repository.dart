import 'package:drift/drift.dart';

import '../../../../database/app_database.dart';
import '../../domain/models/sales_history_page_result.dart';
import 'customers_repository.dart';
import 'users_repository.dart';

class SalesRepository {
  SalesRepository(this._db, this._customersRepo, this._usersRepo);

  final AppDatabase _db;
  final CustomersRepository _customersRepo;
  final UsersRepository _usersRepo;

  Stream<List<Sale>> watchAll() {
    return (_db.select(_db.sales)
          ..orderBy([(t) => OrderingTerm.desc(t.saleDate)]))
        .watch();
  }

  Expression<bool> _buildSearchWhere({
    String? query,
    DateTime? from,
    DateTime? to,
  }) {
    final t = _db.sales;
    Expression<bool> cond = const Constant(true);
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      cond = cond & t.invoiceNumber.lower().like('%$q%');
    }
    if (from != null) {
      cond = cond & t.saleDate.isBiggerOrEqualValue(from);
    }
    if (to != null) {
      final end = DateTime(to.year, to.month, to.day, 23, 59, 59);
      cond = cond & t.saleDate.isSmallerOrEqualValue(end);
    }
    return cond;
  }

  Stream<List<Sale>> search({
    String? query,
    DateTime? from,
    DateTime? to,
  }) {
    if ((query == null || query.trim().isEmpty) && from == null && to == null) {
      return watchAll();
    }
    final where = _buildSearchWhere(query: query, from: from, to: to);
    return (_db.select(_db.sales)
          ..where((t) => where)
          ..orderBy([(t) => OrderingTerm.desc(t.saleDate)]))
        .watch();
  }

  Future<int> countSearch({
    String? query,
    DateTime? from,
    DateTime? to,
  }) async {
    final countExpr = _db.sales.id.count();
    final row = await (_db.selectOnly(_db.sales)
          ..addColumns([countExpr])
          ..where(_buildSearchWhere(query: query, from: from, to: to)))
        .getSingle();
    return row.read(countExpr) ?? 0;
  }

  Future<List<Sale>> searchPage({
    String? query,
    DateTime? from,
    DateTime? to,
    required int limit,
    required int offset,
  }) async {
    final where = _buildSearchWhere(query: query, from: from, to: to);
    return (_db.select(_db.sales)
          ..where((t) => where)
          ..orderBy([(t) => OrderingTerm.desc(t.saleDate)])
          ..limit(limit, offset: offset))
        .get();
  }

  /// Paginated sales history with batched customer/cashier name lookups.
  Future<SalesHistoryPageResult> searchPaginated({
    String? query,
    DateTime? from,
    DateTime? to,
    required int page,
    required int pageSize,
  }) async {
    final normalizedQuery =
        (query == null || query.trim().isEmpty) ? null : query.trim();
    final offset = page * pageSize;

    final totalCount = await countSearch(
      query: normalizedQuery,
      from: from,
      to: to,
    );
    final sales = await searchPage(
      query: normalizedQuery,
      from: from,
      to: to,
      limit: pageSize,
      offset: offset,
    );

    final customerIds =
        sales.map((s) => s.customerId).whereType<int>().toSet();
    final cashierIds = sales.map((s) => s.cashierId).toSet();

    final customers = await _customersRepo.getByIds(customerIds);
    final users = await _usersRepo.getByIds(cashierIds);
    final customerById = {for (final c in customers) c.id: c.name};
    final cashierById = {for (final u in users) u.id: u.fullName};

    final customerNamesBySaleId = <int, String>{};
    final cashierNamesBySaleId = <int, String>{};
    for (final sale in sales) {
      customerNamesBySaleId[sale.id] = sale.customerId == null
          ? 'Walk-in'
          : (customerById[sale.customerId] ?? '-');
      cashierNamesBySaleId[sale.id] =
          cashierById[sale.cashierId] ?? '-';
    }

    return SalesHistoryPageResult(
      sales: sales,
      totalCount: totalCount,
      page: page,
      pageSize: pageSize,
      customerNamesBySaleId: customerNamesBySaleId,
      cashierNamesBySaleId: cashierNamesBySaleId,
    );
  }

  Future<Sale?> getById(int id) async {
    return (_db.select(_db.sales)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<SaleItem>> getSaleItems(int saleId) async {
    return (_db.select(_db.saleItems)
          ..where((t) => t.saleId.equals(saleId)))
        .get();
  }

  Future<String?> getLastInvoiceNumber() async {
    final last = await (_db.select(_db.sales)
          ..orderBy([(t) => OrderingTerm.desc(t.id)])
          ..limit(1))
        .getSingleOrNull();
    return last?.invoiceNumber;
  }

  Future<int> getNextInvoiceSequence() async {
    final last = await getLastInvoiceNumber();
    if (last == null) return 1;
    final parts = last.split('-');
    if (parts.length >= 3) {
      final seq = int.tryParse(parts.last);
      if (seq != null) return seq + 1;
    }
    return 1;
  }
}
