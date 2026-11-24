import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api.dart';
import '../l10n.dart';
import '../main.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/brand.dart';
import '../widgets/outfit_card.dart';
import 'photos_screen.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _picker = ImagePicker();

  Future<void> _pick(ImageSource source) async {
    try {
      final List<XFile> picked;
      if (source == ImageSource.camera) {
        final x = await _picker.pickImage(source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
        picked = [if (x != null) x];
      } else {
        picked = await _picker.pickMultiImage(
            maxWidth: 1600, maxHeight: 1600, imageQuality: 85, limit: PhotosScreen.maxPhotos);
      }
      if (picked.isEmpty || !mounted) return;
      // Далі — екран, де можна додати ще полицю чи взуття
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PhotosScreen(initial: picked.take(PhotosScreen.maxPhotos).map((x) => File(x.path)).toList()),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.of(context).noCamera)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extra = Extra.of(context);
    final scope = AppScope.of(context);
    final t = L10n.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(t.homeTitle, style: display(32)),
          const SizedBox(height: 8),
          Text(t.homeSubtitle, style: theme.textTheme.bodyLarge?.copyWith(color: extra.muted)),
          const SizedBox(height: 20),
          const _QuickChips(),
          const SizedBox(height: 14),
          _Viewfinder(onTap: () => _pick(ImageSource.camera)),
          const SizedBox(height: 10),
          _SoftButton(icon: Icons.photo_library_outlined, label: t.gallery, onTap: () => _pick(ImageSource.gallery)),
          const _FromWardrobe(),
          const SizedBox(height: 20),
          const _TodayLook(),
          const SizedBox(height: 16),
          ValueListenableBuilder(
            valueListenable: scope.prefs,
            builder: (context, p, _) => Material(
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: theme.colorScheme.outline),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                leading: const Icon(Icons.tune),
                title: Text(t.settings, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(t.settingsSummary(p)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showPrefsSheet(context),
              ),
            ),
          ),
          const SizedBox(height: 28),
          const BrandFooter(),
        ],
      ),
    );
  }
}

/// Куди й яка погода — одним дотиком, прямо на головній
class _QuickChips extends StatelessWidget {
  const _QuickChips();

  @override
  Widget build(BuildContext context) {
    final prefs = AppScope.of(context).prefs;
    final t = L10n.of(context);
    Widget row<T>(List<T> values, Map<T, String> labels, T selected, ValueChanged<T> onPick) => SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final v in values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(label: Text(labels[v]!), selected: v == selected, onSelected: (_) => onPick(v)),
                ),
            ],
          ),
        );
    return ValueListenableBuilder(
      valueListenable: prefs,
      builder: (context, p, _) => Column(children: [
        row(Occasion.values, t.occasionLabels, p.occasion, (o) => prefs.value = p.copyWith(occasion: o)),
        const SizedBox(height: 8),
        row(Weather.values, {for (final w in Weather.values) w: '${_weatherEmoji[w]} ${t.weatherLabels[w]}'}, p.weather,
            (w) => prefs.value = p.copyWith(weather: w)),
      ]),
    );
  }
}

const _weatherEmoji = {
  Weather.any: '🌤️',
  Weather.hot: '☀️',
  Weather.warm: '🌿',
  Weather.cool: '🍂',
  Weather.cold: '❄️',
  Weather.rain: '🌧️',
};

/// Якщо гардероб уже є — образи без нового фото
class _FromWardrobe extends StatelessWidget {
  const _FromWardrobe();

  @override
  Widget build(BuildContext context) {
    final wardrobe = AppScope.of(context).wardrobe;
    final t = L10n.of(context);
    return ListenableBuilder(
      listenable: wardrobe,
      builder: (context, _) {
        if (wardrobe.items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ResultScreen(images: []))),
            icon: const Icon(Icons.checkroom),
            label: Text('${t.fromWardrobe} · ${t.itemsN(wardrobe.items.length)}'),
          ),
        );
      },
    );
  }
}

/// Нижня шторка: мова й чиї образи (жіночі, чоловічі, будь-які).
Future<void> showPrefsSheet(BuildContext context) {
  final scope = AppScope.of(context);
  final prefs = scope.prefs;
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => ValueListenableBuilder(
      valueListenable: prefs,
      builder: (ctx, p, _) {
        final theme = Theme.of(ctx);
        final t = L10n.of(ctx);
        Widget label(String s) => Padding(
              padding: const EdgeInsets.only(top: 18, bottom: 8),
              child: Text(s, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            );
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.settings, style: display(20)),
                label(t.language),
                Wrap(
                  spacing: 8,
                  children: supportedStrings.values
                      .map((s) => ChoiceChip(
                            label: Text(s.languageName),
                            selected: t.code == s.code,
                            onSelected: (_) => scope.setLanguage(s.code),
                          ))
                      .toList(),
                ),
                label(t.styleFor),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: StyleFor.values
                      .map((v) => ChoiceChip(
                            label: Text(t.styleLabels[v]!),
                            selected: p.styleFor == v,
                            onSelected: (_) => prefs.value = p.copyWith(styleFor: v),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(t.done)),
                const SizedBox(height: 22),
                BrandFooter(appName: t.appName, logoHeight: 56),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// Головний елемент екрана — велика кнопка-видошукач камери.
class _Viewfinder extends StatelessWidget {
  const _Viewfinder({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const primary = AppColors.mustard; // фон видошукача — гірчиця
    const onPrimary = AppColors.ink; // рамки, кнопка, текст
    final t = L10n.of(context);
    return Semantics(
      button: true,
      label: t.takePhoto,
      child: Material(
        color: primary,
        borderRadius: BorderRadius.circular(32),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(
              painter: _CornersPainter(onPrimary),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: onPrimary, width: 5)),
                    alignment: Alignment.center,
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: onPrimary),
                      child: Icon(Icons.photo_camera_outlined, color: primary, size: 28),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(t.takePhoto, style: display(21, color: onPrimary)),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      t.takePhotoHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: onPrimary.withValues(alpha: 0.75), fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CornersPainter extends CustomPainter {
  _CornersPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const inset = 22.0, len = 34.0;
    final r = Rect.fromLTRB(inset, inset, size.width - inset, size.height - inset);
    for (final c in [r.topLeft, r.topRight, r.bottomLeft, r.bottomRight]) {
      final dx = c.dx == r.left ? len : -len;
      final dy = c.dy == r.top ? len : -len;
      canvas.drawLine(c, c.translate(dx, 0), p);
      canvas.drawLine(c, c.translate(0, dy), p);
    }
  }

  @override
  bool shouldRepaint(_CornersPainter old) => old.color != color;
}

class _SoftButton extends StatelessWidget {
  const _SoftButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Extra.of(context).leaf,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: SizedBox(
          height: 58,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ]),
        ),
      ),
    );
  }
}


/// «Образ дня»: один образ з гардероба під погоду й справи на сьогодні. Не повторює те, що вдягали цього тижня.
class _TodayLook extends StatefulWidget {
  const _TodayLook();

  @override
  State<_TodayLook> createState() => _TodayLookState();
}

class _TodayLookState extends State<_TodayLook> {
  bool _busy = false;
  String? _error;

  Future<void> _make() async {
    final scope = AppScope.of(context);
    final t = L10n.of(context);
    final current = scope.looks.todayOutfit();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await scope.api.refine(
        scope.wardrobe.items,
        scope.prefs.value.copyWith(outfitCount: 1),
        excludeTitles: [...scope.looks.recentlyWorn(), if (current != null) current.title],
      );
      if (r.outfits.isEmpty) {
        if (mounted) setState(() => _error = t.errGeneric);
      } else {
        await scope.looks.setToday(r.outfits.first);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = t.error(e));
    } catch (_) {
      if (mounted) setState(() => _error = t.errGeneric);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = L10n.of(context);
    final extra = Extra.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([scope.wardrobe, scope.looks]),
      builder: (context, _) {
        final today = scope.looks.todayOutfit();
        final enough = scope.wardrobe.items.length >= 3;
        return Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          decoration: BoxDecoration(color: extra.sunBg, borderRadius: BorderRadius.circular(24)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('☀️ ${t.ootdTitle}', style: display(19))),
              if (today != null && !_busy)
                TextButton.icon(onPressed: _make, icon: const Icon(Icons.refresh, size: 18), label: Text(t.ootdAnother)),
            ]),
            const SizedBox(height: 4),
            if (!enough)
              Text(t.ootdNeedItems, style: TextStyle(color: extra.muted, height: 1.35))
            else if (_busy) ...[
              const SizedBox(height: 8),
              Row(children: [
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5)),
                const SizedBox(width: 12),
                Text(t.ootdLoading, style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 8),
            ] else if (today != null) ...[
              const SizedBox(height: 6),
              OutfitCard(outfit: today, known: scope.wardrobe.items),
            ] else ...[
              Text(t.ootdHint, style: TextStyle(color: extra.muted, height: 1.35)),
              const SizedBox(height: 10),
              FilledButton.icon(onPressed: _make, icon: const Icon(Icons.auto_awesome), label: Text(t.ootdBtn)),
            ],
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_error!, style: TextStyle(color: extra.coral))),
          ]),
        );
      },
    );
  }
}
