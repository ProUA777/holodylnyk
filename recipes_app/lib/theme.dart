import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Яскрава палітра: соковитий лайм + чорнильно-фіолетовий, і свій колір у кожного типу страви.
class AppColors {
  static const lime = Color(0xFFC8F135);
  static const ink = Color(0xFF1C1238); // текст на лаймі й фон режиму «Готую»
  static const violet = Color(0xFF5B3DF5);
  static const violetTint = Color(0xFFF0EDFF);
  static const berry = Color(0xFFFF3D9A);
  static const tomato = Color(0xFFF0401F);
  static const tomatoBg = Color(0xFFFFE6DF);
  static const mint = Color(0xFF0E8F68);
  static const mintBg = Color(0xFFDDF8EE);
  static const saffron = Color(0xFFFFB000); // «скоро зіпсується»
  static const saffronBg = Color(0xFFFFF3D6);
  static const bg = Color(0xFFFFFFFF);
  static const muted = Color(0xFF6B6585);
  static const line = Color(0xFFECE9F5);

  // темна тема
  static const violetDark = Color(0xFFA99BFF);
  static const violetTintDark = Color(0xFF2A2150);
  static const bgDark = Color(0xFF120B24);
  static const cardDark = Color(0xFF1D1535);
  static const lineDark = Color(0xFF2C2350);
  static const tomatoDark = Color(0xFFFF7A5C);
  static const tomatoBgDark = Color(0xFF3D1B17);
  static const mintDark = Color(0xFF4FE0B4);
  static const mintBgDark = Color(0xFF123A2E);
  static const saffronBgDark = Color(0xFF3A2E10);
}

/// Колір типу страви — плитка з емодзі, шапка рецепта, фільтри.
const _mealColors = {
  'breakfast': Color(0xFFFFB000),
  'soup': Color(0xFFFF5A36),
  'main': Color(0xFF7B6CFF),
  'salad': Color(0xFF2ED3A5),
  'baking': Color(0xFFFF8A3D),
  'dessert': Color(0xFFFF3D9A),
  'snack': Color(0xFF9BD400),
  'drink': Color(0xFF2EB8FF),
};

Color mealColor(String type) => _mealColors[type] ?? AppColors.lime;

/// М'який фон з кольору страви поверх картки (працює і в темній темі).
Color mealTint(BuildContext context, String type) =>
    Color.alphaBlend(mealColor(type).withValues(alpha: 0.22), Theme.of(context).colorScheme.surface);

/// Кольори, яких немає в ColorScheme: Theme.of(context).extension<Extra>()!
class Extra extends ThemeExtension<Extra> {
  const Extra({
    required this.leaf,
    required this.tomato,
    required this.tomatoBg,
    required this.saffronBg,
    required this.muted,
    required this.mint,
    required this.mintBg,
  });
  final Color leaf, tomato, tomatoBg, saffronBg, muted, mint, mintBg;

  static Extra of(BuildContext context) => Theme.of(context).extension<Extra>()!;

  @override
  Extra copyWith({Color? leaf, Color? tomato, Color? tomatoBg, Color? saffronBg, Color? muted, Color? mint, Color? mintBg}) =>
      Extra(
        leaf: leaf ?? this.leaf,
        tomato: tomato ?? this.tomato,
        tomatoBg: tomatoBg ?? this.tomatoBg,
        saffronBg: saffronBg ?? this.saffronBg,
        muted: muted ?? this.muted,
        mint: mint ?? this.mint,
        mintBg: mintBg ?? this.mintBg,
      );

  @override
  Extra lerp(ThemeExtension<Extra>? other, double t) => this;
}

/// Заголовки — Unbounded (українська розробка), текст — Manrope.
TextStyle display(double size, {Color? color, FontWeight weight = FontWeight.w700}) =>
    GoogleFonts.unbounded(fontSize: size, fontWeight: weight, color: color, height: 1.15, letterSpacing: -0.3);

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final line = dark ? AppColors.lineDark : AppColors.line;
  final scheme = ColorScheme(
    brightness: b,
    primary: dark ? AppColors.violetDark : AppColors.violet,
    onPrimary: dark ? AppColors.ink : Colors.white,
    secondary: AppColors.lime,
    onSecondary: AppColors.ink,
    tertiary: AppColors.berry,
    onTertiary: Colors.white,
    error: dark ? AppColors.tomatoDark : AppColors.tomato,
    onError: Colors.white,
    surface: dark ? AppColors.cardDark : Colors.white,
    onSurface: dark ? const Color(0xFFF4F1FF) : AppColors.ink,
    surfaceContainerHighest: dark ? AppColors.violetTintDark : AppColors.violetTint,
    outline: line,
    outlineVariant: line,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: b);
  final text = GoogleFonts.manropeTextTheme(base.textTheme).apply(
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
  );
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
    // Головні кнопки — лайм з темним текстом
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.lime,
        foregroundColor: AppColors.ink,
        disabledBackgroundColor: AppColors.lime.withValues(alpha: 0.4),
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
      checkmarkColor: scheme.surface,
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
      indicatorColor: AppColors.lime,
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
        leaf: dark ? AppColors.violetTintDark : AppColors.violetTint,
        tomato: dark ? AppColors.tomatoDark : AppColors.tomato,
        tomatoBg: dark ? AppColors.tomatoBgDark : AppColors.tomatoBg,
        saffronBg: dark ? AppColors.saffronBgDark : AppColors.saffronBg,
        muted: dark ? const Color(0xFFA79FC6) : AppColors.muted,
        mint: dark ? AppColors.mintDark : AppColors.mint,
        mintBg: dark ? AppColors.mintBgDark : AppColors.mintBg,
      ),
    ],
  );
}
