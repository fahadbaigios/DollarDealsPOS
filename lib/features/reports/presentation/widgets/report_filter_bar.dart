import 'package:flutter/material.dart';

import '../../domain/models/report_date_range.dart';
import '../../domain/models/report_filter_state.dart';

/// Reusable filter bar for reports.
class ReportFilterBar extends StatelessWidget {
  const ReportFilterBar({
    super.key,
    required this.filter,
    required this.onFilterChanged,
    this.showSearch = true,
    this.searchHint = 'Search...',
    this.showCategoryFilter = false,
    this.categoryOptions = const [],
    this.showSupplierFilter = false,
    this.supplierOptions = const [],
    this.showCustomerFilter = false,
    this.customerOptions = const [],
    this.showCashierFilter = false,
    this.cashierOptions = const [],
    this.showExpenseCategoryFilter = false,
    this.expenseCategoryOptions = const [],
  });

  final ReportFilterState filter;
  final ValueChanged<ReportFilterState> onFilterChanged;
  final bool showSearch;
  final String searchHint;
  final bool showCategoryFilter;
  final List<({int id, String name})> categoryOptions;
  final bool showSupplierFilter;
  final List<({int id, String name})> supplierOptions;
  final bool showCustomerFilter;
  final List<({int id, String name})> customerOptions;
  final bool showCashierFilter;
  final List<({int id, String name})> cashierOptions;
  final bool showExpenseCategoryFilter;
  final List<({int id, String name})> expenseCategoryOptions;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _DatePresetChips(
          current: filter.dateRange?.preset,
          onPreset: (preset) {
            ReportDateRange range;
            switch (preset) {
              case ReportDatePreset.today:
                range = ReportDateRange.today();
                break;
              case ReportDatePreset.thisWeek:
                range = ReportDateRange.thisWeek();
                break;
              case ReportDatePreset.thisMonth:
                range = ReportDateRange.thisMonth();
                break;
              case ReportDatePreset.custom:
                return;
            }
            onFilterChanged(filter.copyWith(dateRange: range));
          },
          onCustom: () async {
            final range = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              initialDateRange: filter.dateRange != null
                  ? DateTimeRange(
                      start: filter.dateRange!.from,
                      end: filter.dateRange!.to,
                    )
                  : null,
            );
            if (range != null) {
              onFilterChanged(filter.copyWith(
                  dateRange: ReportDateRange.custom(range.start, range.end)));
            }
          },
        ),
        if (showSearch)
          SizedBox(
            width: 220,
            child: TextField(
              decoration: InputDecoration(
                hintText: searchHint,
                prefixIcon: const Icon(Icons.search, size: 20),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) =>
                  onFilterChanged(filter.copyWith(searchQuery: v)),
            ),
          ),
        if (showCategoryFilter && categoryOptions.isNotEmpty)
          _DropdownFilter<int?>(
            value: filter.categoryId,
            hint: 'All Categories',
            items: [
              (null, 'All Categories'),
              ...categoryOptions.map((c) => (c.id as int?, c.name)),
            ],
            onChanged: (v) => onFilterChanged(filter.copyWith(categoryId: v)),
          ),
        if (showSupplierFilter && supplierOptions.isNotEmpty)
          _DropdownFilter<int?>(
            value: filter.supplierId,
            hint: 'All Suppliers',
            items: [
              (null, 'All Suppliers'),
              ...supplierOptions.map((s) => (s.id as int?, s.name)),
            ],
            onChanged: (v) => onFilterChanged(filter.copyWith(supplierId: v)),
          ),
        if (showCustomerFilter && customerOptions.isNotEmpty)
          _DropdownFilter<int?>(
            value: filter.customerId,
            hint: 'All Customers',
            items: [
              (null, 'All Customers'),
              ...customerOptions.map((c) => (c.id as int?, c.name)),
            ],
            onChanged: (v) => onFilterChanged(filter.copyWith(customerId: v)),
          ),
        if (showCashierFilter && cashierOptions.isNotEmpty)
          _DropdownFilter<int?>(
            value: filter.cashierId,
            hint: 'All Cashiers',
            items: [
              (null, 'All Cashiers'),
              ...cashierOptions.map((c) => (c.id as int?, c.name)),
            ],
            onChanged: (v) => onFilterChanged(filter.copyWith(cashierId: v)),
          ),
        if (showExpenseCategoryFilter && expenseCategoryOptions.isNotEmpty)
          _DropdownFilter<int?>(
            value: filter.expenseCategoryId,
            hint: 'All Categories',
            items: [
              (null, 'All Categories'),
              ...expenseCategoryOptions.map((e) => (e.id as int?, e.name)),
            ],
            onChanged: (v) =>
                onFilterChanged(filter.copyWith(expenseCategoryId: v)),
          ),
        TextButton.icon(
          onPressed: () {
            onFilterChanged(ReportFilterState(
              dateRange: ReportDateRange.thisMonth(),
              searchQuery: '',
            ));
          },
          icon: const Icon(Icons.clear, size: 18),
          label: const Text('Reset'),
        ),
      ],
    );
  }
}

class _DatePresetChips extends StatelessWidget {
  const _DatePresetChips({
    required this.current,
    required this.onPreset,
    required this.onCustom,
  });

  final ReportDatePreset? current;
  final ValueChanged<ReportDatePreset> onPreset;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ChoiceChip(
          label: const Text('Today'),
          selected: current == ReportDatePreset.today,
          onSelected: (_) => onPreset(ReportDatePreset.today),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('This Week'),
          selected: current == ReportDatePreset.thisWeek,
          onSelected: (_) => onPreset(ReportDatePreset.thisWeek),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('This Month'),
          selected: current == ReportDatePreset.thisMonth,
          onSelected: (_) => onPreset(ReportDatePreset.thisMonth),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: onCustom,
          icon: const Icon(Icons.calendar_month, size: 18),
          label: const Text('Custom'),
        ),
      ],
    );
  }
}

class _DropdownFilter<T> extends StatelessWidget {
  const _DropdownFilter({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final T? value;
  final String hint;
  final List<(T?, String)> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<T?>(
      value: value,
      hint: Text(hint),
      items: items
          .map((e) => DropdownMenuItem<T?>(value: e.$1, child: Text(e.$2)))
          .toList(),
      onChanged: (v) => onChanged(v),
    );
  }
}
