import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n.dart';
import '../main.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/brand.dart';
import 'photos_screen.dart';

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
      // Далі — екран, де можна доповнити фото листка зблизька чи ґрунту
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
          _ThirstyBanner(),
          _Viewfinder(onTap: () => _pick(ImageSource.camera)),
          const SizedBox(height: 10),
          _SoftButton(icon: Icons.photo_library_outlined, label: t.gallery, onTap: () => _pick(ImageSource.gallery)),
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

/// «Сьогодні полити: 2 рослини» — над видошукачем, якщо є кого поливати.
class _ThirstyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final garden = AppScope.of(context).garden;
    final t = L10n.of(context);
    final extra = Extra.of(context);
    return ListenableBuilder(
      listenable: garden,
      builder: (context, _) {
        final n = garden.thirstyCount(DateTime.now());
        if (n == 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: extra.waterBg,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Shell.openGarden(context),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Row(children: [
                  const Text('💧', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(t.thirsty(n), style: const TextStyle(fontWeight: FontWeight.w800))),
                  Text(t.openGarden, style: TextStyle(color: extra.water, fontWeight: FontWeight.w800)),
                  Icon(Icons.chevron_right, color: extra.water),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Нижня шторка: де росте рослина, тварини й діти (для попереджень про отруйність), мова.
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
                label(t.place),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: Place.values
                      .map((pl) => ChoiceChip(
                            label: Text(t.placeLabels[pl]!),
                            selected: p.place == pl,
                            onSelected: (_) => prefs.value = p.copyWith(place: pl),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('🐈 ${t.pets}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  value: p.pets,
                  onChanged: (v) => prefs.value = p.copyWith(pets: v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('🧒 ${t.kids}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  value: p.kids,
                  onChanged: (v) => prefs.value = p.copyWith(kids: v),
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
    const primary = AppColors.sprout; // фон видошукача — колір паростка
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

