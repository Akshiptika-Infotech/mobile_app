import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ── Public theme builders ──────────────────────────────────────────────────

  static ThemeData light(Color primaryColor) =>
      _build(primaryColor, Brightness.light);

  static ThemeData dark(Color primaryColor) =>
      _build(primaryColor, Brightness.dark);

  // ── Implementation ─────────────────────────────────────────────────────────

  static ThemeData _build(Color seed, Brightness brightness) {
    final cs = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final isDark = brightness == Brightness.dark;

    // Typography — slightly tighter, weightier headings for a modern feel.
    final textTheme = ThemeData(brightness: brightness).textTheme.copyWith(
          headlineSmall: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2),
          titleLarge:    const TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.1),
          titleMedium:   const TextStyle(fontWeight: FontWeight.w600),
          titleSmall:    const TextStyle(fontWeight: FontWeight.w600),
          labelLarge:    const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.2),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: isDark
          ? cs.surface
          : const Color(0xFFF7F8FB),
      textTheme: textTheme,

      // ── App bar — brand-coloured background with white content. Uses
      //    the raw flavor `seed` colour (not `cs.primary`) so every
      //    AppBar matches the dashboard header exactly. ─────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: seed,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
      ),

      // ── Tab bar — paired with the brand-coloured AppBar above. ──────
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.72),
        indicatorColor: Colors.white,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(
          Colors.white.withValues(alpha: 0.08),
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.2),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, letterSpacing: 0.1),
      ),

      // ── Bottom navigation (each role's shell uses NavigationBar) ────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: seed,
        indicatorColor: Colors.white.withValues(alpha: 0.18),
        elevation: 6,
        height: 64,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? Colors.white : Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.15,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? Colors.white : Colors.white.withValues(alpha: 0.7),
            size: 24,
          );
        }),
      ),

      // ── Buttons — use the raw brand colour so primary CTAs match the
      //    AppBar / bottom-nav exactly. ─────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: seed,
          minimumSize: const Size.fromHeight(48),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          side: BorderSide(color: cs.outlineVariant, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: seed,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // ── Inputs ──────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        filled: true,
        fillColor: isDark ? cs.surfaceContainer : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w500),
        hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
      ),

      // ── Cards & dialogs ─────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? cs.surfaceContainerLow : Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? cs.outlineVariant.withValues(alpha: 0.3) : const Color(0xFFE6E8EE),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? cs.surfaceContainerHigh : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // ── Chips (status pills like "ACTIVE") ──────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: cs.primaryContainer,
        labelStyle: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.4),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),

      // ── List & dividers ─────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        iconColor: cs.onSurfaceVariant,
        textColor: cs.onSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant.withValues(alpha: 0.5),
        thickness: 0.8,
        space: 16,
      ),

      // ── FAB & bottom sheets ─────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? cs.surfaceContainerHigh : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? cs.surfaceContainerHigh : const Color(0xFF1F2937),
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // ── Page transitions — smoother on mobile ───────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}
