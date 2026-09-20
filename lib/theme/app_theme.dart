import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primary = Color(0xFF9C2C50);
  static const primaryContainer = Color(0xFFC24571);
  static const surface = Color(0xFFF8F9FA);
  static const surfaceLow = Color(0xFFF3F4F5);
  static const navy = Color(0xFF1A1A2E);
  static const muted = Color(0xFF5B3F43);
  static const success = Color(0xFF006B1B);

  // Dark mode palette
  static const darkSurface = Color(0xFF121218);
  static const darkSurfaceLow = Color(0xFF262633);
  static const darkCard = Color(0xFF1E1E2A);
  static const darkText = Color(0xFFF1F1F5);
  static const darkMuted = Color(0xFFCDBDC1);
  static const darkAccent = Color(0xFFE57399);
  static const darkSuccess = Color(0xFF6FDC8C);

  // Compatibility aliases used by the existing screens.
  static const ink = navy;
  static const coral = primary;
  static const cream = surface;
  static const sand = surfaceLow;
  static const mint = Color(0xFFE6F4EA);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? darkSurface : surface;
    final low = isDark ? darkSurfaceLow : surfaceLow;
    final card = isDark ? darkCard : Colors.white;
    final text = isDark ? darkText : navy;
    final variant = isDark ? darkMuted : muted;
    final accent = isDark ? darkAccent : primary;

    final base = ThemeData(useMaterial3: true, brightness: brightness);
    final scheme = isDark
        ? ColorScheme.dark(
            primary: accent,
            onPrimary: Colors.white,
            primaryContainer: primaryContainer,
            onPrimaryContainer: Colors.white,
            secondary: primaryContainer,
            onSecondary: Colors.white,
            surface: bg,
            onSurface: text,
            surfaceContainerLow: low,
            onSurfaceVariant: variant,
            error: const Color(0xFFFFB4AB),
          )
        : const ColorScheme.light(
            primary: primary,
            onPrimary: Colors.white,
            primaryContainer: primaryContainer,
            onPrimaryContainer: Colors.white,
            secondary: primaryContainer,
            onSecondary: Colors.white,
            surface: surface,
            onSurface: navy,
            surfaceContainerLow: surfaceLow,
            onSurfaceVariant: muted,
            error: Color(0xFFBA1A1A),
          );

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: scheme,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: text,
        displayColor: text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: text,
        iconTheme: IconThemeData(color: accent),
        actionsIconTheme: IconThemeData(color: accent),
        elevation: 0,
        centerTitle: false,
      ),
      iconTheme: IconThemeData(color: text),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        indicatorColor: primary,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w700, color: text),
        ),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: text),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        selectedColor: primary,
        secondarySelectedColor: primaryContainer,
        side: BorderSide(color: accent),
        labelStyle: TextStyle(color: text, fontWeight: FontWeight.w700),
        secondaryLabelStyle:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      dividerTheme: DividerThemeData(
        color: low,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: low,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: accent),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
      ),
    );
  }
}
