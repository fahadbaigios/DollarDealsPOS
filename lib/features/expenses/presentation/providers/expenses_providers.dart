import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/database_provider.dart';
import '../../../../database/app_database.dart';
import '../../../sales/data/repositories/payment_methods_repository.dart';
import '../../data/repositories/expense_categories_repository.dart';
import '../../data/repositories/expenses_repository.dart';

final expenseCategoriesRepositoryProvider = Provider<ExpenseCategoriesRepository>((ref) {
  return ExpenseCategoriesRepository(ref.watch(databaseProvider));
});

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  return ExpensesRepository(ref.watch(databaseProvider));
});

final expenseCategoriesStreamProvider = StreamProvider.autoDispose<List<ExpenseCategory>>((ref) {
  return ref.watch(expenseCategoriesRepositoryProvider).watchAll();
});

final expenseCategoriesActiveListProvider = FutureProvider.autoDispose<List<ExpenseCategory>>((ref) {
  return ref.watch(expenseCategoriesRepositoryProvider).getActive();
});

final _paymentMethodsRepoProvider = Provider<PaymentMethodsRepository>((ref) {
  return PaymentMethodsRepository(ref.watch(databaseProvider));
});

final expensePaymentMethodsProvider = FutureProvider.autoDispose<List<PaymentMethod>>((ref) {
  return ref.watch(_paymentMethodsRepoProvider).getActive();
});

/// Filters for expenses list.
final expensesSearchQueryProvider = StateProvider<String>((ref) => '');
final expensesCategoryFilterProvider = StateProvider<int?>((ref) => null);
final expensesDateFromProvider = StateProvider<DateTime?>((ref) => null);
final expensesDateToProvider = StateProvider<DateTime?>((ref) => null);

final expensesStreamProvider = StreamProvider.autoDispose<List<Expense>>((ref) {
  final repo = ref.watch(expensesRepositoryProvider);
  final search = ref.watch(expensesSearchQueryProvider);
  final categoryId = ref.watch(expensesCategoryFilterProvider);
  final from = ref.watch(expensesDateFromProvider);
  final to = ref.watch(expensesDateToProvider);
  return repo.watchFiltered(
    searchQuery: search.isEmpty ? null : search,
    categoryId: categoryId,
    from: from,
    to: to,
  );
});
