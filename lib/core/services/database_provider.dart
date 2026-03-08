import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/app_database.dart';

/// Singleton database instance for app-wide access.
/// Lazy-initialized on first read; cached for app lifetime.
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});
