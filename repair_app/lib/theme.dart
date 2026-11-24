import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Палітра «Що зламалось?»: сигнальний помаранчевий + графіт, синій для дій, зелений «можна самому», червоний «небезпечно».
class AppColors {
  static const orange = Color(0xFFFF8A1F); // головний колір: видошукач, кнопки, значок
  static const ink = Color(0xFF1E1E24); // графіт: текст на помаранчевому
  static const steel = Color(0xFF2563EB); // посилання, іконки
  static const steelTint = Color(0xFFEEF2FB);
  static const amber = Color(0xFFF59E0B); // «обережно»
  static const amberBg = Color(0xFFFFF4DC);
  static const blue = Color(0xFF2563EB);
  static const blueBg = Color(0xFFE6EEFD);
  static const green = Color(0xFF16A34A); // «можна самому»
  static const greenBg = Color(0xFFE3F6EA);
  static const red = Color(0xFFDC2626); // «краще майстер»
  static const redBg = Color(0xFFFDE5E5);
  static const bg = Color(0xFFFFFFFF);
  static const muted = Color(0xFF63656F);
  static const line = Color(0xFFE7E7EC);

  // темна тема
  static const steelDark = Color(0xFFFFA654);
  static const steelTintDark = Color(0xFF26262E);
  static const bgDark = Color(0xFF141418);
  static const cardDark = Color(0xFF1C1C22);
  static const lineDark = Color(0xFF2E2E37);
  static const amberBgDark = Color(0xFF3A2C0E);
  static const blueBgDark = Color(0xFF14254A);
  static const redDark = Color(0xFFFF6B6B);
  static const redBgDark = Color(0xFF3D1717);
  static const greenBgDark = Color(0xFF123320);
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
    primary: dark ? AppColors.steelDark : AppColors.steel,
    onPrimary: dark ? AppColors.ink : Colors.white,
    secondary: AppColors.orange,
    onSecondary: AppColors.ink,
    tertiary: AppColors.blue,
    onTertiary: Colors.white,
    error: dark ? AppColors.redDark : AppColors.red,
    onError: Colors.white,
    surface: dark ? AppColors.cardDark : Colors.white,
    onSurface: dark ? const Color(0xFFF2F2F5) : AppColors.ink,
    surfaceContainerHighest: dark ? AppColors.steelTintDark : AppColors.steelTint,
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
        backgroundColor: AppColors.orange,
        foregroundColor: AppColors.ink,
        disabledBackgroundColor: AppColors.orange.withValues(alpha: 0.4),
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
      indicatorColor: AppColors.orange,
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
        leaf: dark ? AppColors.steelTintDark : AppColors.steelTint,
        muted: dark ? const Color(0xFFA6A7B2) : AppColors.muted,
        amberBg: dark ? AppColors.amberBgDark : AppColors.amberBg,
        blue: AppColors.blue,
        blueBg: dark ? AppColors.blueBgDark : AppColors.blueBg,
        red: dark ? AppColors.redDark : AppColors.red,
        redBg: dark ? AppColors.redBgDark : AppColors.redBg,
      ),
    ],
  );
}
