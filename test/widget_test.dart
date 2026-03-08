import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:one_dollar_deals_inventory_system/app/app.dart';

void main() {
  testWidgets('App loads and shows dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PosApp(),
      ),
    );

    expect(find.text('Overview and quick stats will appear here'), findsOneWidget);
  });
}
