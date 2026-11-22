import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Палітра «Що з рослиною?»: соковитий паросток + глибокий лісовий, сонце, вода, глина.
class AppColors {
  static const sprout = Color(0xFF8EE36B); // головний колір: видошукач, кнопки, значок
  static const ink = Color(0xFF0F2A1D); // текст на паростку, темна тема
  static const forest = Color(0xFF1F7A4C); // посилання, іконки
  static const forestTint = Color(0xFFE9F7E4);
  static const sun = Color(0xFFFFC83D); // «потребує уваги»
  static const sunBg = Color(0xFFFFF4D6);
  static const water = Color(0xFF2F9BEA); // полив
  static const waterBg = Color(0xFFE2F1FD);
  static const clay = Color(0xFFE2654B); // «хворіє», отруйна
  static const clayBg = Color(0xFFFDE7E2);
  static const bg = Color(0xFFFFFFFF);
  static const muted = Color(0xFF5E7166);
  static const line = Color(0xFFE3ECE4);

  // темна тема
  static const forestDark = Color(0xFF8EE36B);
  static const forestTintDark = Color(0xFF173626);
  static const bgDark = Color(0xFF0B1A13);
  static const cardDark = Color(0xFF12261C);
  static const lineDark = Color(0xFF214232);
  static const sunBgDark = Color(0xFF3A3110);
  static const waterBgDark = Color(0xFF10293D);
  static const clayDark = Color(0xFFFF8A72);
  static const clayBgDark = Color(0xFF3D1C16);
}

/// Кольори, яких немає в ColorScheme: Extra.of(context)
class Extra extends ThemeExtension<Extra> {
  const Extra({
    required this.leaf,
    required this.muted,
    required this.sunBg,
    required this.water,
    required this.waterBg,
    required this.clay,
    required this.clayBg,
  });
  final Color leaf, muted, sunBg, water, waterBg, clay, clayBg;

  static Extra of(BuildContext context) => Theme.of(context).extension<Extra>()!;

  @override
  Extra copyWith({Color? leaf, Color? muted, Color? sunBg, Color? water, Color? waterBg, Color? clay, Color? clayBg}) => Extra(
        leaf: leaf ?? this.leaf,
        muted: muted ?? this.muted,
        sunBg: sunBg ?? this.sunBg,
        water: water ?? this.water,
        waterBg: waterBg ?? this.waterBg,
        clay: clay ?? this.clay,
        clayBg: clayBg ?? this.clayBg,
      );

  @override
  Extra lerp(ThemeExtension<Extra>? other, double t) => this;
}

/// Заголовки — Unbounded, текст — Manrope (як в усій родині фото-апок Koreec).
TextStyle display(double size, {Color? color, FontWeight weight = FontWeight.w700}) =>
    GoogleFonts.unbounded(fontSize: size, fontWeight: weight, color: color, height: 1.15, letterSpacing: -0.3);

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final line = dark ? AppColors.lineDark : AppColors.line;
  final scheme = ColorScheme(
    brightness: b,
    primary: dark ? AppColors.forestDark : AppColors.forest,
    onPrimary: dark ? AppColors.ink : Colors.white,
    secondary: AppColors.sprout,
    onSecondary: AppColors.ink,
    tertiary: AppColors.water,
    onTertiary: Colors.white,
    error: dark ? AppColors.clayDark : AppColors.clay,
    onError: Colors.white,
    surface: dark ? AppColors.cardDark : Colors.white,
    onSurface: dark ? const Color(0xFFEFF8F0) : AppColors.ink,
    surfaceContainerHighest: dark ? AppColors.forestTintDark : AppColors.forestTint,
    outline: line,
    outlineVariant: line,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: b);
  final text = GoogleFonts.manropeTextTheme(base.textTheme).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  final radius = BorderRadius.circular(20);
  return base.copyWith(
    scaffoldBackgroundColor: dark ? AppColors.bgDark : AppColors.bg,
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? AppColors.bgDark : AppColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.sprout,
        foregroundColor: AppColors.ink,
        disabledBackgroundColor: AppColors.sprout.withValues(alpha: 0.4),
        disabledForegroundColor: AppColors.ink.withValues(alpha: 0.5),
        minimumSize: const Size.fromHeight(58),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: radius),
        side: BorderSide(color: line, width: 1.5),
        textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide(color: line),
      backgroundColor: scheme.surface,
      selectedColor: scheme.onSurface,
      labelStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      secondaryLabelStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: scheme.surface),
      showCheckmark: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: line, width: 1.5)),
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? AppColors.bgDark : Colors.white,
      indicatorColor: AppColors.sprout,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? AppColors.ink : scheme.onSurface),
      ),
      labelTextStyle: WidgetStatePropertyAll(text.labelMedium?.copyWith(fontWeight: FontWeight.w800)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    extensions: [
      Extra(
        leaf: dark ? AppColors.forestTintDark : AppColors.forestTint,
        muted: dark ? const Color(0xFF9DB5A6) : AppColors.muted,
        sunBg: dark ? AppColors.sunBgDark : AppColors.sunBg,
        water: AppColors.water,
        waterBg: dark ? AppColors.waterBgDark : AppColors.waterBg,
        clay: dark ? AppColors.clayDark : AppColors.clay,
        clayBg: dark ? AppColors.clayBgDark : AppColors.clayBg,
      ),
    ],
  );
}
