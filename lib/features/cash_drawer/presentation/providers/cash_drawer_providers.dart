import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/database_provider.dart';
import '../../../../database/app_database.dart';
import '../../data/repositories/cash_drawer_repository.dart';
import '../../domain/models/cash_drawer_summary.dart';

final cashDrawerRepositoryProvider = Provider<CashDrawerRepository>((ref) {
  return CashDrawerRepository(ref.watch(databaseProvider));
});

final cashDrawerSummaryProvider = FutureProvider.autoDispose<CashDrawerSummary>(
  (ref) {
    return ref.watch(cashDrawerRepositoryProvider).getSummary();
  },
);

final cashDrawerActivityProvider =
    FutureProvider.autoDispose<List<CashDrawerMovement>>((ref) {
      return ref.watch(cashDrawerRepositoryProvider).getRecentActivity();
    });

void refreshCashDrawer(WidgetRef ref) {
  ref.invalidate(cashDrawerSummaryProvider);
  ref.invalidate(cashDrawerActivityProvider);
}
