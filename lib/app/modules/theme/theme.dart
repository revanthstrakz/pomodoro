import 'package:flutter/material.dart';

class AppTheme {
  // Define default seed color
  static const Color defaultPrimarySeed = Color(0xFF1DCD9F);

  // Light theme - now takes a seed color parameter
  static ThemeData lightTheme([Color? seedColor]) {
    final ColorScheme lightColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor ?? defaultPrimarySeed,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightColorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: lightColorScheme.surface,
        foregroundColor: lightColorScheme.onSurface,
        elevation: 0,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: lightColorScheme.onSurface,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: lightColorScheme.onSurface.withValues(alpha: 0.9),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: lightColorScheme.onSurface.withValues(alpha: 0.9),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightColorScheme.primary,
          foregroundColor: lightColorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // Dark theme - now takes a seed color parameter
  static ThemeData darkTheme([Color? seedColor]) {
    final ColorScheme darkColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor ?? defaultPrimarySeed,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkColorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: darkColorScheme.surface,
        foregroundColor: darkColorScheme.onSurface,
        elevation: 0,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: darkColorScheme.onSurface,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: darkColorScheme.onSurface.withValues(alpha: 0.9),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: darkColorScheme.onSurface.withValues(alpha: 0.9),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkColorScheme.primary,
          foregroundColor: darkColorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

// Extending the AppColors to use Material Design tokens,
// maintained for backward compatibility
class AppColors {
  static Color primary(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
  static Color primaryLight(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
  static Color primaryDark(BuildContext context) =>
      Theme.of(context).colorScheme.primaryContainer;

  static Color secondary(BuildContext context) =>
      Theme.of(context).colorScheme.secondary;
  static Color secondaryLight(BuildContext context) =>
      Theme.of(context).colorScheme.secondaryContainer;
  static Color secondaryDark(BuildContext context) =>
      Theme.of(context).colorScheme.onSecondaryContainer;
  static Color secondaryVariant(BuildContext context) =>
      Theme.of(context).colorScheme.tertiary;

  static Color accent(BuildContext context) =>
      Theme.of(context).colorScheme.tertiary;
  static Color accentLight(BuildContext context) =>
      Theme.of(context).colorScheme.tertiaryContainer;
  static Color accentDark(BuildContext context) =>
      Theme.of(context).colorScheme.onTertiaryContainer;

  static Color textOnPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onPrimary;
  static Color textOnSecondary(BuildContext context) =>
      Theme.of(context).colorScheme.onSecondary;
  static Color textPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;
  static Color textSecondary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  static Color background(BuildContext context) =>
      Theme.of(context).colorScheme.surface;
  static Color surface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;
  static Color divider(BuildContext context) =>
      Theme.of(context).colorScheme.outlineVariant;

  static Color success(BuildContext context) => Colors.green;
  static Color error(BuildContext context) =>
      Theme.of(context).colorScheme.error;
  static Color warning(BuildContext context) => Colors.orange;
  static Color info(BuildContext context) => Colors.blue;
}
