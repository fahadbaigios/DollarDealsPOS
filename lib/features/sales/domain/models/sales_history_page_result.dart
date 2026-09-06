import '../../../../database/app_database.dart';

/// One page of sales history with lookup names for the table UI.
class SalesHistoryPageResult {
  const SalesHistoryPageResult({
    required this.sales,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.customerNamesBySaleId,
    required this.cashierNamesBySaleId,
  });

  final List<Sale> sales;
  final int totalCount;
  final int page;
  final int pageSize;

  /// Keyed by sale id (not customer id) for convenient table lookup.
  final Map<int, String> customerNamesBySaleId;
  final Map<int, String> cashierNamesBySaleId;

  int get totalPages =>
      totalCount == 0 ? 1 : ((totalCount + pageSize - 1) ~/ pageSize);

  int get rangeStart => totalCount == 0 ? 0 : page * pageSize + 1;

  int get rangeEnd {
    final end = (page + 1) * pageSize;
    return end > totalCount ? totalCount : end;
  }

  bool get hasPreviousPage => page > 0;

  bool get hasNextPage => (page + 1) * pageSize < totalCount;
}
