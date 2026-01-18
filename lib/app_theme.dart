import 'package:flutter/material.dart';

class AppColors {
  // Light theme (backgrounds = white / light grey, foreground = near-black)
  static const lightBackground = Color(0xFFF5F5F7); // very light grey
  static const lightSurface = Color(0xFFFBF7F5); // white
  static const lightSurfaceVariant = Color(0xFFE6E7EA); // slightly darker white
  static const lightOnSurface = Color(0xFF0F1720); // almost black
  static const lightOutline = Color(0xFFB8B8B8);

  // Dark theme (backgrounds = near-black / dark grey, foreground = light grey/white)
  static const darkBackground = Color(0xFF0A0A0B); // near black
  static const darkSurface = Color(0xFF111214); // slightly lighter
  static const darkSurfaceVariant = Color(0xFF1E2326); // panel variant
  static const darkOnSurface = Color(0xFFE6E7EA); // light grey text
  static const darkOutline = Color(0xFF4B5563);

  // Highlight colors
  static const red = Color(0xffd85858);
  static const green = Color(0xff78d668);
}

class AppTheme {
  static final ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.lightOnSurface,
    // primary controls foreground in mono theme
    onPrimary: AppColors.lightSurface,
    // if buttons are dark text on white
    secondary: AppColors.lightOnSurface,
    onSecondary: AppColors.lightSurface,
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightOnSurface,
    error: Colors.red.shade700,
    onError: Colors.white,
  );

  static final ThemeData lightTheme = ThemeData(
    colorScheme: lightColorScheme,
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightColorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: lightColorScheme.surface,
      foregroundColor: lightColorScheme.onSurface,
      elevation: 0,
    ),
    cardColor: AppColors.lightSurfaceVariant,
    dividerColor: AppColors.lightOutline,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightColorScheme.primary,
        // here primary is dark text color
        foregroundColor: lightColorScheme.onPrimary,
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: lightColorScheme.primary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightSurfaceVariant,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
    ),
    textTheme: Typography.blackMountainView,
  );

  static final ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.darkOnSurface,
    onPrimary: AppColors.darkSurface,
    secondary: AppColors.darkOnSurface,
    onSecondary: AppColors.darkSurface,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkOnSurface,
    error: Colors.red.shade300,
    onError: Colors.black,
  );

  static final ThemeData darkTheme = ThemeData(
    colorScheme: darkColorScheme,
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkColorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: darkColorScheme.surface,
      foregroundColor: darkColorScheme.onSurface,
      elevation: 0,
    ),
    cardColor: AppColors.darkSurfaceVariant,
    dividerColor: AppColors.darkOutline,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkColorScheme.primary, // light text on dark surfaces
        foregroundColor: darkColorScheme.onPrimary,
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: darkColorScheme.primary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurfaceVariant,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
    ),
    textTheme: Typography.whiteMountainView, // light text for dark theme
  );
}
