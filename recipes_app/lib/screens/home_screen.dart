import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n.dart';
import '../main.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/brand.dart';
import 'photos_screen.dart';
import 'results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _picker = ImagePicker();

  Future<void> _pick(ImageSource source) async {
    try {
      // Стискаємо ще на телефоні: швидша відправка, менше трафіку
      final List<XFile> picked;
      if (source == ImageSource.camera) {
        final x = await _picker.pickImage(source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
        picked = [if (x != null) x];
      } else {
        picked = await _picker.pickMultiImage(
            maxWidth: 1600, maxHeight: 1600, imageQuality: 85, limit: PhotosScreen.maxPhotos);
      }
      if (picked.isEmpty || !mounted) return;
      // Далі — екран, де можна доповнити фото морозилки чи полиці
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PhotosScreen(initial: picked.take(PhotosScreen.maxPhotos).map((x) => File(x.path)).toList()),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.of(context).noCamera)));
    }
  }

  void _manual() {
    final params = AppScope.of(context).prefs.value;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ResultsScreen(images: const [], params: params)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extra = Extra.of(context);
    final prefs = AppScope.of(context).prefs;
    final t = L10n.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(t.homeTitle, style: display(34)),
          const SizedBox(height: 8),
          Text(t.homeSubtitle,
              style: theme.textTheme.bodyLarge?.copyWith(color: extra.muted)),
          const SizedBox(height: 20),
          _Viewfinder(onTap: () => _pick(ImageSource.camera)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _SoftButton(icon: Icons.photo_library_outlined, label: t.gallery, onTap: () => _pick(ImageSource.gallery))),
            const SizedBox(width: 10),
            Expanded(child: _SoftButton(icon: Icons.edit_outlined, label: t.typeIn, onTap: _manual)),
          ]),
          const SizedBox(height: 16),
          ValueListenableBuilder(
            valueListenable: prefs,
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
                subtitle: Text('${t.prefsSummary(p)}, ${t.languageName}'),
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

/// Нижня шторка з дієтою, часом і порціями.
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
        Widget label(String t) => Padding(
              padding: const EdgeInsets.only(top: 18, bottom: 8),
              child: Text(t, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
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
                label(t.diet),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: Diet.values
                      .map((d) => ChoiceChip(
                            label: Text(t.dietLabels[d]!),
                            selected: p.diet == d,
                            onSelected: (_) => prefs.value = p.copyWith(diet: d),
                          ))
                      .toList(),
                ),
                label(t.timeAvailable),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <int?>[null, 15, 30, 60]
                      .map((m) => ChoiceChip(
                            label: Text(m == null ? t.anyTimeChip : t.upToMin(m)),
                            selected: p.maxTimeMinutes == m,
                            onSelected: (_) => prefs.value =
                                m == null ? p.copyWith(clearTime: true) : p.copyWith(maxTimeMinutes: m),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Text(t.servings, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton.outlined(
                    onPressed: p.servings > 1 ? () => prefs.value = p.copyWith(servings: p.servings - 1) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  SizedBox(width: 44, child: Text('${p.servings}', textAlign: TextAlign.center, style: display(20))),
                  IconButton.outlined(
                    onPressed: p.servings < 12 ? () => prefs.value = p.copyWith(servings: p.servings + 1) : null,
                    icon: const Icon(Icons.add),
                  ),
                ]),
                const SizedBox(height: 20),
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
    const primary = AppColors.lime; // фон видошукача
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
