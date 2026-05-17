import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4CAF50),
          secondary: Color(0xFF81C784),
          surface: Color(0xFF161B22),
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF161B22),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF161B22),
          selectedItemColor: Color(0xFF4CAF50),
          unselectedItemColor: Colors.grey,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF161B22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: Color(0xFF4CAF50),
          thumbColor: Color(0xFF4CAF50),
          inactiveTrackColor: Colors.grey,
        ),
      );

  // Heatmap cell color based on visit count
  static Color heatmapColor(int count) {
    if (count <= 0) return Colors.transparent;
    if (count == 1) return const Color(0xFF4CAF50).withValues(alpha: 0.4);
    if (count <= 5) return const Color(0xFFFFEB3B).withValues(alpha: 0.5);
    if (count <= 20) return const Color(0xFFFF9800).withValues(alpha: 0.6);
    return const Color(0xFFF44336).withValues(alpha: 0.7);
  }
}
