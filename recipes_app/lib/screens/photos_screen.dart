import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n.dart';
import '../main.dart';
import '../theme.dart';
import 'results_screen.dart';

/// Після першого фото: можна доповнити морозилкою чи полицею (до 3 фото) — AI побачить більше продуктів.
class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key, required this.initial});
  final List<File> initial;

  static const maxPhotos = 3;

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  late final List<File> _photos = List.of(widget.initial);
  final _picker = ImagePicker();

  Future<void> _add(ImageSource source) async {
    final left = PhotosScreen.maxPhotos - _photos.length;
    if (left <= 0) return;
    try {
      final List<XFile> picked;
      if (source == ImageSource.camera) {
        final x = await _picker.pickImage(source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
        picked = [if (x != null) x];
      } else if (left == 1) {
        final x = await _picker.pickImage(source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
        picked = [if (x != null) x];
      } else {
        picked = await _picker.pickMultiImage(maxWidth: 1600, maxHeight: 1600, imageQuality: 85, limit: left);
      }
      if (!mounted) return;
      setState(() => _photos.addAll(picked.take(left).map((x) => File(x.path))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.of(context).noCamera)));
    }
  }

  void _go() {
    final params = AppScope.of(context).prefs.value;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => ResultsScreen(images: List.of(_photos), params: params),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final theme = Theme.of(context);
    final extra = Extra.of(context);
    final canAdd = _photos.length < PhotosScreen.maxPhotos;

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(t.photosTitle, style: display(28)),
          const SizedBox(height: 6),
          Text(t.photosHint, style: theme.textTheme.bodyLarge?.copyWith(color: extra.muted)),
          const SizedBox(height: 4),
          Text(t.maxPhotos(PhotosScreen.maxPhotos),
              style: theme.textTheme.bodySmall?.copyWith(color: extra.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.78,
            children: [
              for (var i = 0; i < _photos.length; i++)
                Stack(fit: StackFit.expand, children: [
                  ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.file(_photos[i], fit: BoxFit.cover)),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: AppColors.ink.withValues(alpha: 0.75),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => setState(() => _photos.removeAt(i)),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.close, size: 16, color: Colors.white, semanticLabel: t.remove),
                        ),
                      ),
                    ),
                  ),
                ]),
              if (canAdd)
                Material(
                  color: extra.leaf,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _add(ImageSource.camera),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_a_photo_outlined, color: theme.colorScheme.primary, size: 30),
                      const SizedBox(height: 8),
                      Text(t.addPhoto,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
                    ]),
                  ),
                ),
            ],
          ),
          if (canAdd) ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _add(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(t.camera),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _add(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(t.gallery),
                ),
              ),
            ]),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton.icon(
            onPressed: _photos.isEmpty ? null : _go,
            icon: const Icon(Icons.auto_awesome),
            label: Text(t.findRecipes),
          ),
        ),
      ),
    );
  }
}
