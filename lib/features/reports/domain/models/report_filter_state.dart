import 'report_date_range.dart';

/// Shared filter state for reports.
class ReportFilterState {
  const ReportFilterState({
    this.dateRange,
    this.searchQuery = '',
    this.categoryId,
    this.supplierId,
    this.customerId,
    this.cashierId,
    this.paymentMethodId,
    this.expenseCategoryId,
    this.includeInactive = false,
  });

  final ReportDateRange? dateRange;
  final String searchQuery;
  final int? categoryId;
  final int? supplierId;
  final int? customerId;
  final int? cashierId;
  final int? paymentMethodId;
  final int? expenseCategoryId;
  final bool includeInactive;

  ReportFilterState copyWith({
    ReportDateRange? dateRange,
    String? searchQuery,
    int? categoryId,
    int? supplierId,
    int? customerId,
    int? cashierId,
    int? paymentMethodId,
    int? expenseCategoryId,
    bool? includeInactive,
  }) {
    return ReportFilterState(
      dateRange: dateRange ?? this.dateRange,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryId: categoryId ?? this.categoryId,
      supplierId: supplierId ?? this.supplierId,
      customerId: customerId ?? this.customerId,
      cashierId: cashierId ?? this.cashierId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      expenseCategoryId: expenseCategoryId ?? this.expenseCategoryId,
      includeInactive: includeInactive ?? this.includeInactive,
    );
  }

  ReportFilterState clearDateRange() => copyWith(dateRange: null);
  ReportFilterState clearSearch() => copyWith(searchQuery: '');
  ReportFilterState clearCategory() => copyWith(categoryId: null);
  ReportFilterState clearSupplier() => copyWith(supplierId: null);
  ReportFilterState clearCustomer() => copyWith(customerId: null);
  ReportFilterState clearCashier() => copyWith(cashierId: null);
  ReportFilterState clearPaymentMethod() => copyWith(paymentMethodId: null);
  ReportFilterState clearExpenseCategory() => copyWith(expenseCategoryId: null);
}
