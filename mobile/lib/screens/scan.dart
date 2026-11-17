import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app.dart';
import '../data/api.dart';
import '../i18n.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'result.dart';

/// Pick a photo, then analyse it on a dedicated screen.
Future<void> startScan(BuildContext context, ImageSource source) async {
  final XFile? file;
  try {
    file = await ImagePicker().pickImage(source: source, maxWidth: 2048, maxHeight: 2048, imageQuality: 85);
  } catch (_) {
    if (context.mounted) _snack(context, t('eBadPhoto'));
    return;
  }
  if (file == null || !context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ScanScreen(photo: File(file!.path))));
}

void _snack(BuildContext context, String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

String errorText(ApiError e) => switch (e) {
      ApiError.limit => t('eLimit'),
      ApiError.badPhoto => t('eBadPhoto'),
      ApiError.network => t('eNetwork'),
      ApiError.server => t('eServer'),
      ApiError.generic => t('eGeneric'),
    };

class ScanScreen extends StatefulWidget {
  final File photo;
  const ScanScreen({super.key, required this.photo});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  ApiError? _error;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() => _error = null);
    try {
      final r = await Api.analyze(widget.photo, lang: app.lang, deviceId: app.deviceId);
      if (!mounted || _cancelled) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ResultScreen.scan(r, widget.photo)));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.kind);
    } catch (_) {
      if (mounted) setState(() => _error = ApiError.generic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      appBar: AppBar(leading: CloseButton(onPressed: () {
        _cancelled = true;
        Navigator.of(context).pop();
      })),
      body: Baseplate(
        child: SafeArea(
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(widget.photo, width: 140, height: 140, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 24),
            if (_error == null) ...[
              const SizedBox(height: 130, child: _Stacking()),
              const SizedBox(height: 18),
              Text(t('analyzing'), textAlign: TextAlign.center, style: display(22)),
              const SizedBox(height: 6),
              Text(t('wait'), textAlign: TextAlign.center, style: body(14, color: p.muted)),
              const SizedBox(height: 28),
              const PhotoTips(),
            ] else ...[
              Icon(_error == ApiError.network ? Icons.wifi_off_rounded : Icons.sentiment_dissatisfied_rounded, size: 56, color: Brand.red),
              const SizedBox(height: 12),
              Text(errorText(_error!), textAlign: TextAlign.center, style: body(17, weight: 700, height: 1.4)),
              const SizedBox(height: 24),
              if (_error != ApiError.limit && _error != ApiError.badPhoto)
                BrickButton(label: t('again'), icon: Icons.refresh_rounded, color: Brand.blue, onTap: _run),
              const SizedBox(height: 8),
              TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t('back'), style: body(15, weight: 800))),
            ],
          ]),
        ),
      ),
    );
  }
}

class PhotoTips extends StatelessWidget {
  const PhotoTips({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return SurfaceCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t('tipsTitle'), style: display(18)),
        const SizedBox(height: 10),
        for (final (icon, k) in [('🧱', 'tip1'), ('⬜', 'tip2'), ('💡', 'tip3')])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(child: Text(t(k), style: body(14.5, color: p.muted, height: 1.35))),
            ]),
          ),
      ]),
    );
  }
}

/// Three bricks dropping onto a stack, on repeat.
class _Stacking extends StatefulWidget {
  const _Stacking();

  @override
  State<_Stacking> createState() => _StackingState();
}

class _StackingState extends State<_Stacking> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bricks = [(Brand.red, 6), (Brand.blue, 4), (Brand.yellow, 2)];
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value * 4;
        return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          for (var i = bricks.length - 1; i >= 0; i--)
            Opacity(
              opacity: (t - i).clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, -60 * (1 - Curves.bounceOut.transform((t - i).clamp(0.0, 1.0)))),
                child: BrickShape(color: bricks[i].$1, studs: bricks[i].$2, unit: 26),
              ),
            ),
        ]);
      },
    );
  }
}
