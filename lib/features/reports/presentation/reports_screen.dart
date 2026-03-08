import 'package:flutter/material.dart';

import 'screens/reports_home_screen.dart';

/// Reports shell - shows home or nested report based on route.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReportsHomeScreen();
  }
}
