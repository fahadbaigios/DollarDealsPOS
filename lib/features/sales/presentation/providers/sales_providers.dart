import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/database_provider.dart';
import '../../../../database/app_database.dart';
import '../../../products/presentation/providers/products_providers.dart';
import '../../data/repositories/customers_repository.dart';
import '../../data/repositories/payment_methods_repository.dart';
import '../../data/repositories/sales_repository.dart';
import '../../data/repositories/users_repository.dart';
import '../../domain/models/cart_item.dart';
import '../../domain/services/pos_scanner_service.dart';
import '../../domain/services/sales_checkout_service.dart';

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  return SalesRepository(ref.watch(databaseProvider));
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

final posProductSearchResultsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final query = ref.watch(posProductSearchQueryProvider);
  final productsRepo = ref.watch(productsRepositoryProvider);
  final products = await productsRepo.getAll();
  if (query.trim().isEmpty) {
    return products.where((p) => p.isActive).toList();
  }
  final q = query.trim().toLowerCase();
  return products.where((p) {
    if (!p.isActive) return false;
    if (p.name.toLowerCase().contains(q)) return true;
    if (p.sku.toLowerCase().contains(q)) return true;
    if (p.barcode != null && p.barcode!.toLowerCase().contains(q)) return true;
    return false;
  }).toList();
});

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

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
final salesHistoryDateFromProvider = StateProvider<DateTime?>((ref) => null);
final salesHistoryDateToProvider = StateProvider<DateTime?>((ref) => null);

final salesStreamProvider = StreamProvider.autoDispose<List<Sale>>((ref) {
  final repo = ref.watch(salesRepositoryProvider);
  final query = ref.watch(salesHistorySearchQueryProvider);
  final from = ref.watch(salesHistoryDateFromProvider);
  final to = ref.watch(salesHistoryDateToProvider);
  return repo.search(
    query: query.isEmpty ? null : query,
    from: from,
    to: to,
  );
});

final saleDetailProvider =
    FutureProvider.autoDispose.family<Sale?, int>((ref, id) async {
  return ref.watch(salesRepositoryProvider).getById(id);
});

final saleItemsProvider =
    FutureProvider.autoDispose.family<List<SaleItem>, int>((ref, saleId) async {
  return ref.watch(salesRepositoryProvider).getSaleItems(saleId);
});
