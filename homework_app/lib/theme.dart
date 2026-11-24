import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Палітра «Як розв'язати?»: небесно-блакитний + чорнильний, рожевий маркер, зелений «правильно», червоний «помилка».
class AppColors {
  static const sky = Color(0xFF4CC9F0); // головний колір: видошукач, кнопки, значок
  static const ink = Color(0xFF0B2545); // чорнильний: текст на блакитному
  static const ocean = Color(0xFF1D6FB8); // посилання, іконки
  static const oceanTint = Color(0xFFEAF6FD);
  static const pink = Color(0xFFF472B6); // підказки, маркер
  static const pinkBg = Color(0xFFFDE8F3);
  static const amber = Color(0xFFF59E0B);
  static const amberBg = Color(0xFFFFF6D9); // «жовтий маркер» для відповіді
  static const blue = Color(0xFF1D6FB8);
  static const blueBg = Color(0xFFE6F1FB);
  static const green = Color(0xFF16A34A); // правильно
  static const greenBg = Color(0xFFE3F6EA);
  static const red = Color(0xFFDC2626); // помилка
  static const redBg = Color(0xFFFDE5E5);
  static const bg = Color(0xFFFFFFFF);
  static const muted = Color(0xFF5C6B80);
  static const line = Color(0xFFE3EAF2);

  // темна тема
  static const oceanDark = Color(0xFF7DD8F6);
  static const oceanTintDark = Color(0xFF132A44);
  static const bgDark = Color(0xFF0A1626);
  static const cardDark = Color(0xFF102036);
  static const lineDark = Color(0xFF1E3550);
  static const amberBgDark = Color(0xFF3A3010);
  static const blueBgDark = Color(0xFF12304E);
  static const redDark = Color(0xFFFF6B6B);
  static const redBgDark = Color(0xFF3D1717);
  static const greenBgDark = Color(0xFF123320);
  static const pinkBgDark = Color(0xFF3D1630);
}

/// Кольори, яких немає в ColorScheme: Extra.of(context)
class Extra extends ThemeExtension<Extra> {
  const Extra({
    required this.leaf,
    required this.muted,
    required this.amberBg,
    required this.blue,
    required this.blueBg,
    required this.red,
    required this.redBg,
  });
  final Color leaf, muted, amberBg, blue, blueBg, red, redBg;

  static Extra of(BuildContext context) => Theme.of(context).extension<Extra>()!;

  @override
  Extra copyWith({Color? leaf, Color? muted, Color? amberBg, Color? blue, Color? blueBg, Color? red, Color? redBg}) => Extra(
        leaf: leaf ?? this.leaf,
        muted: muted ?? this.muted,
        amberBg: amberBg ?? this.amberBg,
        blue: blue ?? this.blue,
        blueBg: blueBg ?? this.blueBg,
        red: red ?? this.red,
        redBg: redBg ?? this.redBg,
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
    primary: dark ? AppColors.oceanDark : AppColors.ocean,
    onPrimary: dark ? AppColors.ink : Colors.white,
    secondary: AppColors.sky,
    onSecondary: AppColors.ink,
    tertiary: AppColors.blue,
    onTertiary: Colors.white,
    error: dark ? AppColors.redDark : AppColors.red,
    onError: Colors.white,
    surface: dark ? AppColors.cardDark : Colors.white,
    onSurface: dark ? const Color(0xFFEEF5FC) : AppColors.ink,
    surfaceContainerHighest: dark ? AppColors.oceanTintDark : AppColors.oceanTint,
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
        backgroundColor: AppColors.sky,
        foregroundColor: AppColors.ink,
        disabledBackgroundColor: AppColors.sky.withValues(alpha: 0.4),
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
      indicatorColor: AppColors.sky,
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
        leaf: dark ? AppColors.oceanTintDark : AppColors.oceanTint,
        muted: dark ? const Color(0xFF9FB2C8) : AppColors.muted,
        amberBg: dark ? AppColors.amberBgDark : AppColors.amberBg,
        blue: AppColors.blue,
        blueBg: dark ? AppColors.blueBgDark : AppColors.blueBg,
        red: dark ? AppColors.redDark : AppColors.red,
        redBg: dark ? AppColors.redBgDark : AppColors.redBg,
      ),
    ],
  );
}
