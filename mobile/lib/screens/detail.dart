import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../data/api.dart';
import '../data/catalog.dart';
import '../i18n.dart';
import '../render/iso.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'build_mode.dart';

/// Opens a catalog model. [steps] lets the scan result pass a repainted copy, [note] says why the AI picked it.
void openModel(BuildContext context, BrickModel m, {List<BuildStep>? steps, String? note}) => Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DetailScreen(
        id: m.id,
        title: pick(m.title, app.lang),
        emoji: m.emoji,
        diff: m.diff,
        minutes: m.minutes,
        desc: [if (note != null && note.isNotEmpty) '💡 $note', pick(m.desc, app.lang)].join('\n'),
        cat: m.cat,
        steps: steps ?? m.steps,
      ),
    ));

void openAiIdea(BuildContext context, AiIdea i) => Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DetailScreen(
        id: i.id,
        title: i.title,
        emoji: i.emoji,
        diff: i.diff,
        minutes: i.minutes,
        desc: i.desc,
        steps: i.steps,
        uses: i.uses,
        fromAi: true,
      ),
    ));

class DetailScreen extends StatefulWidget {
  final String id, title, emoji, diff, desc;
  final String? cat;
  final int minutes;
  final List<BuildStep> steps;
  final List<String> uses;
  final bool fromAi;

  const DetailScreen({
    super.key,
    required this.id,
    required this.title,
    required this.emoji,
    required this.diff,
    required this.minutes,
    required this.desc,
    required this.steps,
    this.cat,
    this.uses = const [],
    this.fromAi = false,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late final List<Placed> _all = flatten(widget.steps);
  late final bool _has3d = _all.isNotEmpty;
  late int _step = widget.steps.isEmpty ? 0 : app.progressOf(widget.id).clamp(0, widget.steps.length - 1);
  int _quarters = 0;
  int _flash = 0; // -1 left, 1 right: brief highlight where the stage was tapped
  bool _pulse = false; // finish button bounce when tapping past the last step
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    if (_step > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t('resumed').replaceAll('{k}', '${_step + 1}')),
          action: SnackBarAction(label: t('startOver'), onPressed: () => _jump(0)),
        ));
      });
    }
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    app.announceProgress();
    super.dispose();
  }

  void _jump(int step) {
    setState(() => _step = step);
    app.saveProgress(widget.id, step);
  }

  Future<void> _openBuildMode() async {
    final r = await BuildModeScreen.open(
      context,
      BuildModeScreen(
        id: widget.id,
        title: widget.title,
        emoji: widget.emoji,
        steps: widget.steps,
        bricks: _all,
        initialStep: _step,
        initialQuarters: _quarters,
      ),
    );
    if (r == null || !mounted) return;
    setState(() {
      _step = r.step;
      _quarters = r.quarters;
    });
    if (r.finished) _finish();
  }

  /// Step forward (+1) or back (-1) from a tap or swipe on the 3D stage.
  void _go(int delta) {
    final n = widget.steps.length;
    final next = _step + delta;
    app.markStepHintSeen();
    _flashTimer?.cancel();
    if (next < 0) {
      HapticFeedback.lightImpact();
      setState(() => _flash = -1);
    } else if (next >= n) {
      HapticFeedback.mediumImpact();
      setState(() {
        _flash = 1;
        _pulse = true;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(t('lastStep')), duration: const Duration(seconds: 2)));
    } else {
      HapticFeedback.selectionClick();
      setState(() {
        _step = next;
        _flash = delta;
      });
      app.saveProgress(widget.id, next);
    }
    _flashTimer = Timer(const Duration(milliseconds: 220), () {
      if (mounted) setState(() => _flash = _pulse ? _flash : 0);
      _flashTimer = Timer(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _flash = 0;
            _pulse = false;
          });
        }
      });
    });
  }
  final Set<int> _checked = {};

  String _stepText(BuildStep s) => s.text?.isNotEmpty == true ? s.text! : pick(catalog.stepLabels[s.label] ?? const {}, app.lang);

  void _finish() {
    final isNew = app.addBuild(BuildRecord(
      id: widget.id,
      title: widget.title,
      emoji: widget.emoji,
      diff: widget.diff,
      minutes: widget.minutes,
      cat: widget.cat,
      date: DateTime.now(),
    ));
    if (isNew) ConfettiOverlay.show(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(height: 150, child: _has3d ? ModelPicture(bricks: _all, maxA: 26) : Center(child: Text(widget.emoji, style: const TextStyle(fontSize: 80)))),
            Text(isNew ? t('doneTitle') : widget.title, style: display(26)),
            const SizedBox(height: 6),
            Text(isNew ? t('doneText') : t('alreadyBuilt'), textAlign: TextAlign.center, style: body(15, color: Palette.of(sheet).muted)),
            const SizedBox(height: 20),
            BrickButton(
              label: t('toMine'),
              icon: Icons.star_rounded,
              onTap: () {
                Navigator.of(sheet).pop();
                Navigator.of(context).popUntil((r) => r.isFirst);
                app.tab.value = 2;
              },
            ),
            TextButton(
              onPressed: () {
                Navigator.of(sheet).pop();
                Navigator.of(context).popUntil((r) => r.isFirst);
                app.tab.value = 1;
              },
              child: Text(t('another'), style: body(15, weight: 800)),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final n = widget.steps.length;
    final k = _step.clamp(0, n == 0 ? 0 : n - 1);
    return Scaffold(
      appBar: AppBar(actions: [
        if (widget.cat != null && !widget.fromAi)
          ListenableBuilder(
            listenable: app,
            builder: (context, _) {
              final fav = app.isFavorite(widget.id);
              return IconButton(
                tooltip: t(fav ? 'removeFav' : 'addFav'),
                icon: Icon(fav ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: fav ? Brand.red : null),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  app.toggleFavorite(widget.id);
                },
              );
            },
          ),
        if (widget.fromAi)
          ReportButton(content: '${widget.title}: ${widget.desc}\n${[for (final s in widget.steps) s.text ?? ''].join('\n')}'),
      ]),
      body: Baseplate(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 28), children: [
          Text('${widget.emoji} ${widget.title}', style: display(28, height: 1.1)),
          const SizedBox(height: 6),
          DiffMeta(diff: widget.diff, minutes: widget.minutes),
          if (widget.desc.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(widget.desc, style: body(15, color: p.muted, height: 1.4)),
          ],
          const SizedBox(height: 14),
          if (_has3d && n > 0) ..._stepper(context, k, n) else ..._checklist(context),
        ]),
      ),
    );
  }

  List<Widget> _stepper(BuildContext context, int k, int n) {
    final p = Palette.of(context);
    final step = widget.steps[k];
    final level = step.bricks.isEmpty ? 1 : step.bricks.map((b) => b.z).reduce((a, b) => a < b ? a : b).round() + 1;
    return [
      Semantics(
        label: '${t('step')} ${k + 1} ${t('of')} $n. ${t('stageA11y')}',
        child: LayoutBuilder(
          builder: (context, box) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            // left third → back, the rest → next (like stories)
            onTapUp: (d) => _go(d.localPosition.dx < box.maxWidth / 3 ? -1 : 1),
            onHorizontalDragEnd: (d) {
              final v = d.primaryVelocity ?? 0;
              if (v < -150) _go(1);
              if (v > 150) _go(-1);
            },
            child: Container(
              height: 290,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: RadialGradient(center: const Alignment(0, -.6), radius: 1.1, colors: [Color.alphaBlend(Brand.blue.withValues(alpha: .12), p.card), p.card]),
              ),
              child: Stack(children: [
                // tap highlight on the side that was touched
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: _flash == 0 ? 0 : 1,
                    duration: const Duration(milliseconds: 160),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: _flash < 0 ? Alignment.centerLeft : Alignment.centerRight,
                          end: Alignment.center,
                          colors: [(_pulse ? Brand.red : p.ink).withValues(alpha: .10), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(bottom: 24, child: IgnorePointer(child: StepModelView(bricks: _all, step: k, quarters: _quarters))),
                // side arrows
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 24,
                  child: Center(child: SideArrow(icon: Icons.chevron_left_rounded, visible: k > 0, active: _flash < 0)),
                ),
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 24,
                  child: Center(
                    child: SideArrow(
                      icon: k < n - 1 ? Icons.chevron_right_rounded : Icons.celebration_rounded,
                      visible: true,
                      active: _flash > 0,
                      color: k < n - 1 ? null : Brand.red,
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: p.ink, borderRadius: BorderRadius.circular(99)),
                    child: Text('${t('step')} ${k + 1} ${t('of')} $n', style: body(13, weight: 800, color: p.plate)),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(children: [
                    _StageButton(
                      icon: Icons.rotate_90_degrees_cw_rounded,
                      tooltip: t('rotate'),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _quarters = (_quarters + 1) % 4);
                      },
                    ),
                    const SizedBox(width: 6),
                    _StageButton(icon: Icons.fullscreen_rounded, tooltip: t('fullscreen'), onTap: _openBuildMode),
                  ]),
                ),
                if (!app.stepHintSeen)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 30,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(color: p.ink.withValues(alpha: .86), borderRadius: BorderRadius.circular(99)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.touch_app_rounded, size: 18, color: p.plate),
                          const SizedBox(width: 6),
                          Flexible(child: Text(t('tapHint'), textAlign: TextAlign.center, style: body(12.5, weight: 700, color: p.plate))),
                        ]),
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 12,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (var j = 0; j < n; j++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: j == k ? 22 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: j < k ? Brand.green : (j == k ? p.ink : p.line),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: FilledButton.tonalIcon(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 13),
            backgroundColor: Brand.blue.withValues(alpha: .12),
            foregroundColor: Brand.blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _openBuildMode,
          icon: const Icon(Icons.fullscreen_rounded),
          label: Text('${t('buildMode')} · ${t('fullscreen').toLowerCase()}', style: display(16, color: Brand.blue)),
        ),
      ),
      const SizedBox(height: 12),
      SurfaceCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_stepText(step), style: body(19, weight: 750, height: 1.3)),
          if (step.bricks.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(t('stepHint').replaceAll('{n}', '${step.bricks.length}').replaceAll('{l}', '$level'),
                style: body(14, weight: 700, color: p.muted)),
            const SizedBox(height: 12),
            Text(t('addNow'), style: body(13, weight: 800, color: p.muted)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: partChips(context, step.bricks)),
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              flex: 2,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: p.line, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: k == 0 ? null : () => _go(-1),
                child: Text('← ${t('prev')}', style: display(16, color: p.ink)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: AnimatedScale(
                scale: _pulse ? 1.07 : 1,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutBack,
                child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: k < n - 1 ? Brand.green : Brand.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: k < n - 1 ? () => _go(1) : _finish,
                child: Text(k < n - 1 ? '${t('next')} →' : '${t('finish')} 🎉', style: display(17, color: Colors.white)),
              ),
              ),
            ),
          ]),
          if (k > 0)
            Center(
              child: TextButton.icon(
                onPressed: () => _jump(0),
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: Text(t('startOver'), style: body(14, weight: 700, color: p.muted)),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 14),
      SurfaceCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t('allParts'), style: display(18)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: partChips(context, [for (final s in widget.steps) ...s.bricks])),
        ]),
      ),
    ];
  }

  /// AI ideas that came without a 3D layout: a plain checklist.
  List<Widget> _checklist(BuildContext context) {
    final p = Palette.of(context);
    return [
      Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(24)),
        child: Text(widget.emoji, style: const TextStyle(fontSize: 96)),
      ),
      const SizedBox(height: 12),
      if (widget.uses.isNotEmpty) ...[
        Text(t('uses'), style: body(13, weight: 800, color: p.muted)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [for (final u in widget.uses) Tag(u)]),
        const SizedBox(height: 12),
      ],
      SurfaceCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t('steps'), style: display(18)),
          for (final (j, s) in widget.steps.indexed)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: Brand.green,
              value: _checked.contains(j),
              onChanged: (v) => setState(() => v == true ? _checked.add(j) : _checked.remove(j)),
              title: Text(
                '${j + 1}. ${_stepText(s)}',
                style: body(15, height: 1.35).copyWith(
                  decoration: _checked.contains(j) ? TextDecoration.lineThrough : null,
                  color: _checked.contains(j) ? p.muted : null,
                ),
              ),
            ),
          const SizedBox(height: 12),
          BrickButton(label: t('finish'), icon: Icons.celebration_rounded, color: Brand.green, onTap: _finish),
        ]),
      ),
    ];
  }
}

class _StageButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _StageButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: p.card.withValues(alpha: .9),
        shape: const CircleBorder(),
        elevation: 1,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 38, height: 38, child: Icon(icon, size: 21, color: p.ink)),
        ),
      ),
    );
  }
}
