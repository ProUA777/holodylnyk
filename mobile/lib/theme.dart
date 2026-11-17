import 'package:flutter/material.dart';

/// Brand colours that stay the same in both themes.
class Brand {
  static const red = Color(0xFFD7261E);
  static const yellow = Color(0xFFF6C624);
  static const blue = Color(0xFF1F5FBF);
  static const green = Color(0xFF2E8B57);
  static const amber = Color(0xFFE08A00);

  static const purple = Color(0xFF7B4FB0);

  static Color difficulty(String d) => switch (d) { 'easy' => green, 'hard' => red, 'expert' => purple, _ => amber };
}

/// Surface colours that change with the theme.
@immutable
class Palette extends ThemeExtension<Palette> {
  final Color plate, stud, card, card2, ink, muted, line, chip;

  const Palette({
    required this.plate,
    required this.stud,
    required this.card,
    required this.card2,
    required this.ink,
    required this.muted,
    required this.line,
    required this.chip,
  });

  static const light = Palette(
    plate: Color(0xFFEEF1E8),
    stud: Color(0xFFE1E6D8),
    card: Color(0xFFFFFFFF),
    card2: Color(0xFFF6F8F2),
    ink: Color(0xFF1D2433),
    muted: Color(0xFF5E6676),
    line: Color(0xFFDDE2D4),
    chip: Color(0xFFF1F3EC),
  );

  static const dark = Palette(
    plate: Color(0xFF14171D),
    stud: Color(0xFF1A1E26),
    card: Color(0xFF1F242E),
    card2: Color(0xFF252B36),
    ink: Color(0xFFEEF0F4),
    muted: Color(0xFFA3AAB8),
    line: Color(0xFF2E3542),
    chip: Color(0xFF2A303C),
  );

  static Palette of(BuildContext context) => Theme.of(context).extension<Palette>()!;

  @override
  Palette copyWith({Color? plate, Color? stud, Color? card, Color? card2, Color? ink, Color? muted, Color? line, Color? chip}) =>
      Palette(
        plate: plate ?? this.plate,
        stud: stud ?? this.stud,
        card: card ?? this.card,
        card2: card2 ?? this.card2,
        ink: ink ?? this.ink,
        muted: muted ?? this.muted,
        line: line ?? this.line,
        chip: chip ?? this.chip,
      );

  @override
  Palette lerp(ThemeExtension<Palette>? other, double t) {
    if (other is! Palette) return this;
    return Palette(
      plate: Color.lerp(plate, other.plate, t)!,
      stud: Color.lerp(stud, other.stud, t)!,
      card: Color.lerp(card, other.card, t)!,
      card2: Color.lerp(card2, other.card2, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      chip: Color.lerp(chip, other.chip, t)!,
    );
  }
}

/// Display face (variable font: weight is set through the 'wght' axis).
TextStyle display(double size, {double weight = 600, Color? color, double? height}) => TextStyle(
      fontFamily: 'Fredoka',
      fontSize: size,
      fontWeight: weight >= 600 ? FontWeight.w600 : FontWeight.w500,
      fontVariations: [FontVariation('wght', weight)],
      color: color,
      height: height,
      letterSpacing: -0.2,
    );

TextStyle body(double size, {double weight = 500, Color? color, double? height}) => TextStyle(
      fontFamily: 'Nunito',
      fontSize: size,
      fontWeight: weight >= 700 ? FontWeight.w700 : (weight >= 600 ? FontWeight.w600 : FontWeight.w500),
      fontVariations: [FontVariation('wght', weight)],
      color: color,
      height: height,
    );

ThemeData buildTheme(Brightness b) {
  final p = b == Brightness.dark ? Palette.dark : Palette.light;
  final scheme = ColorScheme.fromSeed(seedColor: Brand.red, brightness: b).copyWith(
    primary: Brand.red,
    onPrimary: Colors.white,
    surface: p.card,
    onSurface: p.ink,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true, brightness: b, fontFamily: 'Nunito');
  return base.copyWith(
    scaffoldBackgroundColor: p.plate,
    extensions: [p],
    textTheme: base.textTheme.apply(bodyColor: p.ink, displayColor: p.ink),
    appBarTheme: AppBarTheme(
      backgroundColor: p.plate,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: p.ink,
      titleTextStyle: display(20, color: p.ink),
    ),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: p.ink, contentTextStyle: body(15, color: p.plate)),
    dialogTheme: DialogThemeData(backgroundColor: p.card, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: p.card, surfaceTintColor: Colors.transparent),
  );
}

/// Studded baseplate background.
class Baseplate extends StatelessWidget {
  final Widget child;
  const Baseplate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return ColoredBox(color: p.plate, child: CustomPaint(painter: _StudsPainter(p.stud), child: child));
  }
}

class _StudsPainter extends CustomPainter {
  final Color color;
  _StudsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const step = 28.0;
    final paint = Paint()..color = color;
    for (double y = step / 2; y < size.height; y += step) {
      for (double x = step / 2; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 7, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_StudsPainter old) => old.color != color;
}

/// Rounded card used for every content block.
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  final double radius;

  const SurfaceCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color, this.onTap, this.radius = 22});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: color ?? p.card,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: dark ? 0.28 : 0.07), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
      ),
    );
  }
}
