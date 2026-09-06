import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/database_provider.dart';
import '../../../../database/app_database.dart';
import '../../../products/presentation/providers/products_providers.dart';
import '../../data/repositories/customers_repository.dart';
import '../../data/repositories/held_carts_repository.dart';
import '../../data/repositories/payment_methods_repository.dart';
import '../../data/repositories/sales_repository.dart';
import '../../data/repositories/users_repository.dart';
import '../../domain/models/cart_item.dart';
import '../../domain/models/held_cart_summary.dart';
import '../../domain/models/sales_history_page_result.dart';
import '../../domain/services/pos_scanner_service.dart';
import '../../domain/services/sales_checkout_service.dart';

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  return SalesRepository(
    ref.watch(databaseProvider),
    ref.watch(customersRepositoryProvider),
    ref.watch(usersRepositoryProvider),
  );
});

final salesCheckoutServiceProvider = Provider<SalesCheckoutService>((ref) {
  return SalesCheckoutService(
    ref.watch(databaseProvider),
    ref.watch(salesRepositoryProvider),
  );
});

final posScannerServiceProvider = Provider<PosScannerService>((ref) {
  return PosScannerService(ref.watch(productsRepositoryProvider));
});

final customersRepositoryProvider = Provider<CustomersRepository>((ref) {
  return CustomersRepository(ref.watch(databaseProvider));
});

final paymentMethodsRepositoryProvider = Provider<PaymentMethodsRepository>((ref) {
  return PaymentMethodsRepository(ref.watch(databaseProvider));
});

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository(ref.watch(databaseProvider));
});

final heldCartsRepositoryProvider = Provider<HeldCartsRepository>((ref) {
  return HeldCartsRepository(ref.watch(databaseProvider));
});

final heldCartsListProvider = StreamProvider.autoDispose<List<HeldCartSummary>>((ref) {
  return ref.watch(heldCartsRepositoryProvider).watchAll();
});

final currentCashierProvider = FutureProvider.autoDispose<User?>((ref) {
  return ref.watch(usersRepositoryProvider).getFirstActiveUser();
});

final activeCustomersProvider = FutureProvider.autoDispose<List<Customer>>((ref) {
  return ref.watch(customersRepositoryProvider).getActive();
});

final activePaymentMethodsProvider = FutureProvider.autoDispose<List<PaymentMethod>>((ref) {
  return ref.watch(paymentMethodsRepositoryProvider).getActive();
});

final posProductSearchQueryProvider = StateProvider<String>((ref) => '');

final posProductSearchResultsProvider = FutureProvider.autoDispose<List<Product>>((ref) {
  final query = ref.watch(posProductSearchQueryProvider);
  final productsRepo = ref.watch(productsRepositoryProvider);
  return productsRepo.getFiltered(
    searchQuery: query.trim().isEmpty ? null : query,
    isActive: true,
    limit: 200,
  );
});

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  /// Replaces the entire cart contents at once (used when resuming a held
  /// cart).
  void loadItems(List<CartItem> items) {
    state = items;
  }

  void addItem(CartItem item) {
    final idx = state.indexWhere((i) => i.product.id == item.product.id);
    if (idx >= 0) {
      final existing = state[idx];
      state = [
        ...state.sublist(0, idx),
        existing.copyWith(quantity: existing.quantity + item.quantity),
        ...state.sublist(idx + 1),
      ];
    } else {
      state = [...state, item];
    }
  }

  void updateQuantity(int productId, double quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final idx = state.indexWhere((i) => i.product.id == productId);
    if (idx >= 0) {
      state = [
        ...state.sublist(0, idx),
        state[idx].copyWith(quantity: quantity),
        ...state.sublist(idx + 1),
      ];
    }
  }

  void removeItem(int productId) {
    state = state.where((i) => i.product.id != productId).toList();
  }

  void clear() {
    state = [];
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

final posOrderDiscountProvider = StateProvider<double>((ref) => 0);
final posPaidAmountProvider = StateProvider<double>((ref) => 0);
final posCustomerIdProvider = StateProvider<int?>((ref) => null);
final posPaymentMethodIdProvider = StateProvider<int?>((ref) => null);

final cartSubtotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, i) => sum + i.lineTotal);
});

final cartTotalProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  final discount = ref.watch(posOrderDiscountProvider);
  return subtotal - discount;
});

final changeAmountProvider = Provider<double>((ref) {
  final total = ref.watch(cartTotalProvider);
  final paid = ref.watch(posPaidAmountProvider);
  if (paid <= total) return 0;
  return paid - total;
});

final dueAmountProvider = Provider<double>((ref) {
  final total = ref.watch(cartTotalProvider);
  final paid = ref.watch(posPaidAmountProvider);
  if (paid >= total) return 0;
  return total - paid;
});

final salesHistorySearchQueryProvider = StateProvider<String>((ref) => '');

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// Sales history opens on today's sales instead of querying all historical
/// records. Users can still select another range with the From/To filters.
final salesHistoryDateFromProvider =
    StateProvider<DateTime?>((ref) => _today());
final salesHistoryDateToProvider =
    StateProvider<DateTime?>((ref) => _today());
const salesHistoryPageSize = 50;
final salesHistoryPageProvider = StateProvider<int>((ref) => 0);

final salesHistoryPaginatedProvider =
    FutureProvider.autoDispose<SalesHistoryPageResult>((ref) {
  final query = ref.watch(salesHistorySearchQueryProvider);
  final from = ref.watch(salesHistoryDateFromProvider);
  final to = ref.watch(salesHistoryDateToProvider);
  final page = ref.watch(salesHistoryPageProvider);

  return ref.watch(salesRepositoryProvider).searchPaginated(
        query: query.isEmpty ? null : query,
        from: from,
        to: to,
        page: page,
        pageSize: salesHistoryPageSize,
      );
});

/// Resets sales history to page 0 (call when filters change).
void resetSalesHistoryPage(WidgetRef ref) {
  ref.read(salesHistoryPageProvider.notifier).state = 0;
}

/// Restores the history filters to their default: today's sales, first page.
void resetSalesHistoryToToday(WidgetRef ref) {
  final today = _today();
  ref.read(salesHistorySearchQueryProvider.notifier).state = '';
  ref.read(salesHistoryDateFromProvider.notifier).state = today;
  ref.read(salesHistoryDateToProvider.notifier).state = today;
  resetSalesHistoryPage(ref);
}

final saleDetailProvider =
    FutureProvider.autoDispose.family<Sale?, int>((ref, id) async {
  return ref.watch(salesRepositoryProvider).getById(id);
});

final saleItemsProvider =
    FutureProvider.autoDispose.family<List<SaleItem>, int>((ref, saleId) async {
  return ref.watch(salesRepositoryProvider).getSaleItems(saleId);
});
