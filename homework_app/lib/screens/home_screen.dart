import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n.dart';
import '../main.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/brand.dart';
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
        // текст має бути читабельним — тому трохи більша роздільність, ніж у інших апках
        final x = await _picker.pickImage(source: source, maxWidth: 2000, maxHeight: 2000, imageQuality: 88);
        picked = [if (x != null) x];
      } else {
        picked = await _picker.pickMultiImage(
            maxWidth: 2000, maxHeight: 2000, imageQuality: 88, limit: PhotosScreen.maxPhotos);
      }
      if (picked.isEmpty || !mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PhotosScreen(initial: picked.take(PhotosScreen.maxPhotos).map((x) => File(x.path)).toList()),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.of(context).noCamera)));
    }
  }

  /// Без фото: вписати умову (і свій розв'язок — у режимі перевірки)
  Future<void> _typeIn() async {
    final t = L10n.of(context);
    final check = AppScope.of(context).prefs.value.mode == Mode.check;
    final task = TextEditingController(), work = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.typeTitle),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: task, autofocus: true, minLines: 2, maxLines: 6, maxLength: 1500, decoration: InputDecoration(hintText: t.typeHint)),
            if (check)
              TextField(controller: work, minLines: 2, maxLines: 6, maxLength: 2000, decoration: InputDecoration(hintText: t.typeWorkHint)),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.solve)),
        ],
      ),
    );
    final text = task.text.trim(), mine = work.text.trim();
    task.dispose();
    work.dispose();
    if (ok != true || text.length < 2 || !mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ResultScreen(images: const [], tasks: [text], studentWork: [mine.isEmpty ? null : mine]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extra = Extra.of(context);
    final scope = AppScope.of(context);
    final t = L10n.of(context);
    return SafeArea(
      child: ValueListenableBuilder(
        valueListenable: scope.prefs,
        builder: (context, p, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text(t.homeTitle, style: display(32)),
            const SizedBox(height: 8),
            Text(t.homeSubtitle, style: theme.textTheme.bodyLarge?.copyWith(color: extra.muted)),
            const SizedBox(height: 18),
            SegmentedButton<Mode>(
              segments: [
                ButtonSegment(value: Mode.learn, icon: const Icon(Icons.lightbulb_outline), label: Text(t.modeLearn)),
                ButtonSegment(value: Mode.check, icon: const Icon(Icons.fact_check_outlined), label: Text(t.modeCheck)),
              ],
              selected: {p.mode},
              showSelectedIcon: false,
              onSelectionChanged: (s) => scope.prefs.value = p.copyWith(mode: s.first),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (final g in List.generate(12, (i) => i + 1))
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(t.gradeLabel(g)),
                      selected: p.grade == g,
                      onSelected: (_) => scope.prefs.value = p.copyWith(grade: g),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 14),
            _Viewfinder(
              onTap: () => _pick(ImageSource.camera),
              hint: p.mode == Mode.check ? t.takePhotoCheckHint : t.takePhotoHint,
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _SoftButton(icon: Icons.photo_library_outlined, label: t.gallery, onTap: () => _pick(ImageSource.gallery))),
              const SizedBox(width: 10),
              Expanded(child: _SoftButton(icon: Icons.keyboard_outlined, label: t.typeIn, onTap: _typeIn)),
            ]),
            const SizedBox(height: 16),
            Material(
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: theme.colorScheme.outline)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                leading: const Icon(Icons.translate),
                title: Text(t.language, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(t.languageName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showPrefsSheet(context),
              ),
            ),
            const SizedBox(height: 28),
            const BrandFooter(),
          ],
        ),
      ),
    );
  }
}

/// Нижня шторка: мова інтерфейсу й пояснень
Future<void> showPrefsSheet(BuildContext context) {
  final scope = AppScope.of(context);
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final t = L10n.of(ctx);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.language, style: display(20)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: supportedStrings.values
                  .map((s) => ChoiceChip(
                        label: Text(s.languageName),
                        selected: t.code == s.code,
                        onSelected: (_) {
                          scope.setLanguage(s.code);
                          Navigator.pop(ctx);
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 22),
            BrandFooter(appName: t.appName, logoHeight: 56),
          ]),
        ),
      );
    },
  );
}

/// Головний елемент екрана — велика кнопка-видошукач камери.
class _Viewfinder extends StatelessWidget {
  const _Viewfinder({required this.onTap, required this.hint});
  final VoidCallback onTap;
  final String hint;

  @override
  Widget build(BuildContext context) {
    const primary = AppColors.sky; // фон видошукача — небесно-блакитний
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
                      hint,
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

