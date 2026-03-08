import 'package:flutter/material.dart';

/// Material 3 theme configuration for the POS application.
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
          brightness: Brightness.light,
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFF388E3C),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        navigationRailTheme: NavigationRailThemeData(
          elevation: 0,
          backgroundColor: Colors.white,
          selectedIconTheme: const IconThemeData(
            color: Color(0xFF2E7D32),
            size: 24,
          ),
          unselectedIconTheme: IconThemeData(
            color: Colors.grey.shade600,
            size: 24,
          ),
          labelType: NavigationRailLabelType.all,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.dark,
          primary: const Color(0xFF66BB6A),
          secondary: const Color(0xFF81C784),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        navigationRailTheme: NavigationRailThemeData(
          elevation: 0,
          selectedIconTheme: const IconThemeData(
            color: Color(0xFF66BB6A),
            size: 24,
          ),
          labelType: NavigationRailLabelType.all,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
        ),
      );
}
