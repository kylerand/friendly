import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Palette – Wireframe v2.0
// ---------------------------------------------------------------------------

class AppPalette {
  AppPalette._();

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color warmWhite = Color(0xFFFAF8F5);
  static const Color cream = Color(0xFFF5F0EB);
  static const Color sand = Color(0xFFE8E0D8);
  static const Color clay = Color(0xFFC4B5A5);
  static const Color stone = Color(0xFF8A7E72);
  static const Color driftwood = Color(0xFF6B5E52);
  static const Color espresso = Color(0xFF3D3530);
  static const Color charcoal = Color(0xFF2A2523);
  static const Color midnight = Color(0xFF1C1917);

  // Brand primaries
  static const Color orange = Color(0xFFFF4610);
  static const Color blue = Color(0xFF0066FF);
  static const Color pink = Color(0xFFFF73CA);
  static const Color gold = Color(0xFFFFBF17);
  static const Color green = Color(0xFF9DA30A);
  static const Color textDark = Color(0xFF2B2B2B);

  // Brand subtle tints
  static const Color orangeSubtle = Color(0xFFFFE8E2);
  static const Color blueSubtle = Color(0xFFE8F0FE);
  static const Color pinkSubtle = Color(0xFFFFE8F5);
  static const Color goldSubtle = Color(0xFFFFF6DE);
  static const Color greenSubtle = Color(0xFFF3F4E0);

  // Friend-specific colors
  static const Color blueDark = Color(0xFF004FCC);
  static const Color blueDarkSubtle = Color(0xFFE0ECFF);

  // Legacy aliases for backwards compatibility
  static const Color peach = Color(0xFFFFB088);
  static const Color coral = orange;
  static const Color rose = Color(0xFFF28872);
  static const Color blush = Color(0xFFF5A6A0);
  static const Color mint = Color(0xFF88D4B0);
  static const Color sage = Color(0xFFA8C5A0);
  static const Color sky = Color(0xFF88B8E8);
  static const Color lavender = Color(0xFFB8A0D8);
  static const Color honey = gold;
  static const Color amber = Color(0xFFE8B060);
}

// ---------------------------------------------------------------------------
// Semantic colors – Light (Wireframe v2.0)
// ---------------------------------------------------------------------------

class AppColors {
  AppColors._();

  static const Color background = AppPalette.white;
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFFFF5EE);
  static const Color warmSurface = Color(0xFFFFF5EE);
  static const Color card = Color(0xFFFFFFFF);

  static const Color border = Color(0x0A2B2B2B); // 2B2B2B at ~4%
  static const Color borderSubtle = Color(0x0D2B2B2B); // 2B2B2B at ~5%

  static const Color textPrimary = AppPalette.textDark;
  static const Color textSecondary = Color(0x992B2B2B); // 2B2B2B at 60%
  static const Color textTertiary = Color(0x662B2B2B); // 2B2B2B at 40%
  static const Color textMuted = Color(0x4D2B2B2B); // 2B2B2B at 30%
  static const Color textFaint = Color(0x332B2B2B); // 2B2B2B at 20%
  static const Color textInverse = Color(0xFFFFFFFF);

  static const Color accent = AppPalette.orange;
  static const Color accentSubtle = AppPalette.orangeSubtle;

  static const Color link = AppPalette.blue;
  static const Color linkSubtle = AppPalette.blueSubtle;

  static const Color warm = AppPalette.gold;
  static const Color warmSubtle = AppPalette.goldSubtle;

  static const Color positive = AppPalette.green;
  static const Color positiveSubtle = AppPalette.greenSubtle;

  static const Color caution = AppPalette.gold;
  static const Color cautionSubtle = AppPalette.goldSubtle;

  static const Color negative = Color(0xFFDC2626);
  static const Color negativeSubtle = Color(0xFFFFF0EF);

  static const Color icon = Color(0x662B2B2B); // 40%
  static const Color iconSubtle = Color(0x4D2B2B2B); // 30%

  static const Color shadow = Color(0x0F2B2B2B);
  static const Color overlay = Color(0x4D2B2B2B);
}

// ---------------------------------------------------------------------------
// Semantic colors – Dark (adapted from wireframe v2.0)
// ---------------------------------------------------------------------------

class AppColorsDark {
  AppColorsDark._();

  static const Color background = Color(0xFF1A1A1A);
  static const Color surface = Color(0xFF242424);
  static const Color surfaceSubtle = Color(0xFF2E2E2E);
  static const Color warmSurface = Color(0xFF2E2218);
  static const Color card = Color(0xFF242424);

  static const Color border = Color(0xFF3A3A3A);
  static const Color borderSubtle = Color(0xFF333333);

  static const Color textPrimary = Color(0xFFF5F0EB);
  static const Color textSecondary = Color(0xFFB5A898);
  static const Color textTertiary = Color(0xFF8A7E72);
  static const Color textMuted = Color(0xFF6B5E52);
  static const Color textFaint = Color(0xFF4A4440);
  static const Color textInverse = Color(0xFF1A1A1A);

  static const Color accent = Color(0xFFFF6B42);
  static const Color accentSubtle = Color(0xFF33221C);

  static const Color link = Color(0xFF4D94FF);
  static const Color linkSubtle = Color(0xFF1A2840);

  static const Color warm = Color(0xFFFFCF4D);
  static const Color warmSubtle = Color(0xFF33291A);

  static const Color positive = Color(0xFFB5C44A);
  static const Color positiveSubtle = Color(0xFF242812);

  static const Color caution = Color(0xFFFFCF4D);
  static const Color cautionSubtle = Color(0xFF332E1A);

  static const Color negative = Color(0xFFEF4444);
  static const Color negativeSubtle = Color(0xFF33201E);

  static const Color icon = Color(0xFFB5A898);
  static const Color iconSubtle = Color(0xFF8A7E72);

  static const Color shadow = Color(0x4D000000);
  static const Color overlay = Color(0x80000000);
}

// ---------------------------------------------------------------------------
// Spacing (8-point grid)
// ---------------------------------------------------------------------------

class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double xxxxl = 64;
}

// ---------------------------------------------------------------------------
// Radii
// ---------------------------------------------------------------------------

class AppRadii {
  AppRadii._();

  static const double sm = 6;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 20;
  static const double xxl = 28;
  static const double full = 9999;
}

// ---------------------------------------------------------------------------
// Typography – Chewy (display) + Nunito (body)
// ---------------------------------------------------------------------------

class AppTypography {
  AppTypography._();

  /// Display text – used for large hero-style headings.
  static const TextStyle display = TextStyle(
    fontFamily: 'Chewy',
    fontSize: 32,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.5,
  );

  /// Heading text – section titles, nav titles.
  static const TextStyle heading = TextStyle(
    fontFamily: 'Chewy',
    fontSize: 21,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
  );

  /// Subheading text.
  static const TextStyle subheading = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 15,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
  );

  /// Body text – default readable size.
  static const TextStyle body = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  /// Label text – buttons, tags, form labels.
  static const TextStyle label = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 14,
    fontWeight: FontWeight.w800,
  );

  /// Caption text – timestamps, footnotes.
  static const TextStyle caption = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.2,
  );
}

// ---------------------------------------------------------------------------
// Shadows
// ---------------------------------------------------------------------------

class AppShadows {
  AppShadows._();

  // Light mode
  static const List<BoxShadow> small = [
    BoxShadow(
      offset: Offset(0, 1),
      blurRadius: 3,
      color: Color(0x0F2B2B2B),
    ),
  ];

  static const List<BoxShadow> medium = [
    BoxShadow(
      offset: Offset(0, 2),
      blurRadius: 8,
      color: Color(0x142B2B2B),
    ),
  ];

  static const List<BoxShadow> large = [
    BoxShadow(
      offset: Offset(0, 4),
      blurRadius: 16,
      color: Color(0x1A2B2B2B),
    ),
  ];

  /// Accent-tinted shadow for primary CTA buttons.
  static List<BoxShadow> accentGlow(Color color) => [
    BoxShadow(
      offset: const Offset(0, 4),
      blurRadius: 12,
      color: color.withValues(alpha: 0.20),
    ),
  ];

  // Dark mode
  static const List<BoxShadow> smallDark = [
    BoxShadow(
      offset: Offset(0, 1),
      blurRadius: 4,
      color: Color(0x33000000),
    ),
  ];

  static const List<BoxShadow> mediumDark = [
    BoxShadow(
      offset: Offset(0, 3),
      blurRadius: 10,
      color: Color(0x40000000),
    ),
  ];

  static const List<BoxShadow> largeDark = [
    BoxShadow(
      offset: Offset(0, 6),
      blurRadius: 20,
      color: Color(0x4D000000),
    ),
  ];
}

// ---------------------------------------------------------------------------
// ThemeData builders
// ---------------------------------------------------------------------------

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final textTheme = _buildTextTheme(AppColors.textPrimary);

    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accent,
        onPrimary: AppColors.textInverse,
        secondary: AppColors.warm,
        onSecondary: AppColors.textPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.negative,
        onError: AppColors.textInverse,
        outline: AppColors.border,
        outlineVariant: AppColors.borderSubtle,
      ),
      cardColor: AppColors.card,
      dividerColor: AppColors.border,
      textTheme: textTheme,
      iconTheme: const IconThemeData(color: AppColors.icon),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        titleTextStyle: AppTypography.heading.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.textInverse,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          textStyle: AppTypography.label,
        ),
      ),
    );
  }

  static ThemeData dark() {
    final textTheme = _buildTextTheme(AppColorsDark.textPrimary);

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColorsDark.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColorsDark.accent,
        onPrimary: AppColorsDark.textInverse,
        secondary: AppColorsDark.warm,
        onSecondary: AppColorsDark.textPrimary,
        surface: AppColorsDark.surface,
        onSurface: AppColorsDark.textPrimary,
        error: AppColorsDark.negative,
        onError: AppColorsDark.textInverse,
        outline: AppColorsDark.border,
        outlineVariant: AppColorsDark.borderSubtle,
      ),
      cardColor: AppColorsDark.card,
      dividerColor: AppColorsDark.border,
      textTheme: textTheme,
      iconTheme: const IconThemeData(color: AppColorsDark.icon),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColorsDark.surface,
        foregroundColor: AppColorsDark.textPrimary,
        elevation: 0,
        titleTextStyle: AppTypography.heading.copyWith(
          color: AppColorsDark.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColorsDark.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsDark.accent,
          foregroundColor: AppColorsDark.textInverse,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          textStyle: AppTypography.label,
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(Color defaultColor) {
    return TextTheme(
      displayLarge: AppTypography.display.copyWith(color: defaultColor),
      headlineMedium: AppTypography.heading.copyWith(color: defaultColor),
      titleMedium: AppTypography.subheading.copyWith(color: defaultColor),
      bodyLarge: AppTypography.body.copyWith(color: defaultColor),
      labelLarge: AppTypography.label.copyWith(color: defaultColor),
      bodySmall: AppTypography.caption.copyWith(color: defaultColor),
    );
  }
}
