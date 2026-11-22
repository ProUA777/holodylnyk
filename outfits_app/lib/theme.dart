import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Палітра «Що вдягнути?»: гірчиця + денім, корал для акцентів і «докупити».
class AppColors {
  static const mustard = Color(0xFFFFD23F); // головний колір: видошукач, кнопки, значок
  static const ink = Color(0xFF1B2A4A); // темно-синій деніму: текст на гірчиці
  static const denim = Color(0xFF3B5BDB); // посилання, іконки
  static const denimTint = Color(0xFFEDF1FF);
  static const coral = Color(0xFFFF6B5B); // «докупити», зберегти
  static const coralBg = Color(0xFFFFE9E6);
  static const sunBg = Color(0xFFFFF6D6);
  static const bg = Color(0xFFFFFFFF);
  static const muted = Color(0xFF616A80);
  static const line = Color(0xFFE6E9F2);

  // темна тема
  static const denimDark = Color(0xFF8EA2FF);
  static const denimTintDark = Color(0xFF1E2A4A);
  static const bgDark = Color(0xFF0E1424);
  static const cardDark = Color(0xFF161E33);
  static const lineDark = Color(0xFF26314F);
  static const coralDark = Color(0xFFFF8A7D);
  static const coralBgDark = Color(0xFF3D1D1A);
  static const sunBgDark = Color(0xFF3A3210);
}

/// Кольори, яких немає в ColorScheme: Extra.of(context)
class Extra extends ThemeExtension<Extra> {
  const Extra({
    required this.leaf,
    required this.muted,
    required this.sunBg,
    required this.coral,
    required this.coralBg,
  });
  final Color leaf, muted, sunBg, coral, coralBg;

  static Extra of(BuildContext context) => Theme.of(context).extension<Extra>()!;

  @override
  Extra copyWith({Color? leaf, Color? muted, Color? sunBg, Color? coral, Color? coralBg}) => Extra(
        leaf: leaf ?? this.leaf,
        muted: muted ?? this.muted,
        sunBg: sunBg ?? this.sunBg,
        coral: coral ?? this.coral,
        coralBg: coralBg ?? this.coralBg,
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
    primary: dark ? AppColors.denimDark : AppColors.denim,
    onPrimary: dark ? AppColors.ink : Colors.white,
    secondary: AppColors.mustard,
    onSecondary: AppColors.ink,
    tertiary: AppColors.coral,
    onTertiary: Colors.white,
    error: dark ? AppColors.coralDark : AppColors.coral,
    onError: Colors.white,
    surface: dark ? AppColors.cardDark : Colors.white,
    onSurface: dark ? const Color(0xFFF1F3FA) : AppColors.ink,
    surfaceContainerHighest: dark ? AppColors.denimTintDark : AppColors.denimTint,
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
        backgroundColor: AppColors.mustard,
        foregroundColor: AppColors.ink,
        disabledBackgroundColor: AppColors.mustard.withValues(alpha: 0.4),
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
      indicatorColor: AppColors.mustard,
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
        leaf: dark ? AppColors.denimTintDark : AppColors.denimTint,
        muted: dark ? const Color(0xFFA3ABC2) : AppColors.muted,
        sunBg: dark ? AppColors.sunBgDark : AppColors.sunBg,
        coral: dark ? AppColors.coralDark : AppColors.coral,
        coralBg: dark ? AppColors.coralBgDark : AppColors.coralBg,
      ),
    ],
  );
}
