import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../app.dart';
import '../data/catalog.dart';
import '../i18n.dart';
import '../render/iso.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// What the full-screen builder hands back to the detail screen.
typedef BuildModeResult = ({int step, int quarters, bool finished});

/// Full-screen, distraction-free building: the model fills the screen, stories-style progress on top,
/// tap right / swipe left for the next step, tap left / swipe right to go back, parts panel at the bottom.
/// The screen stays awake and system bars are hidden while building.
class BuildModeScreen extends StatefulWidget {
  final String id, title, emoji;
  final List<BuildStep> steps;
  final List<Placed> bricks;
  final int initialStep, initialQuarters;

  const BuildModeScreen({
    super.key,
    required this.id,
    required this.title,
    required this.emoji,
    required this.steps,
    required this.bricks,
    this.initialStep = 0,
    this.initialQuarters = 0,
  });

  static Future<BuildModeResult?> open(BuildContext context, BuildModeScreen screen) =>
      Navigator.of(context).push<BuildModeResult>(PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (_, _, _) => screen,
        transitionsBuilder: (_, a, _, child) => FadeTransition(
          opacity: a,
          child: ScaleTransition(scale: Tween(begin: .96, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)), child: child),
        ),
      ));

  @override
  State<BuildModeScreen> createState() => _BuildModeScreenState();
}

class _BuildModeScreenState extends State<BuildModeScreen> {
  late int _step = widget.initialStep.clamp(0, widget.steps.length - 1);
  late int _quarters = widget.initialQuarters;
  bool _highlight = true;
  bool _panel = true;
  int _flash = 0;
  bool _pulse = false;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable().catchError((_) {});
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WakelockPlus.disable().catchError((_) {});
    super.dispose();
  }

  void _exit({bool finished = false}) =>
      Navigator.of(context).pop<BuildModeResult>((step: _step, quarters: _quarters, finished: finished));

  void _go(int delta) {
    final n = widget.steps.length, next = _step + delta;
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
        _panel = true;
      });
    } else {
      HapticFeedback.selectionClick();
      setState(() {
        _step = next;
        _flash = delta;
      });
      app.saveProgress(widget.id, next);
    }
    _flashTimer = Timer(const Duration(milliseconds: 380), () {
      if (mounted) {
        setState(() {
          _flash = 0;
          _pulse = false;
        });
      }
    });
  }

  void _rotate() {
    HapticFeedback.selectionClick();
    setState(() => _quarters = (_quarters + 1) % 4);
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final n = widget.steps.length, k = _step;
    final step = widget.steps[k];
    final pad = MediaQuery.of(context).padding;
    final last = k == n - 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        backgroundColor: p.plate,
        body: Stack(children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -.2),
                  radius: .9,
                  colors: [Color.alphaBlend(Brand.blue.withValues(alpha: .13), p.card), p.plate],
                ),
              ),
            ),
          ),
          // ── the model + tap/swipe zones ──
          Positioned.fill(
            child: Semantics(
              label: '${t('step')} ${k + 1} ${t('of')} $n. ${t('stageA11y')}',
              child: LayoutBuilder(
                builder: (context, box) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) => _go(d.localPosition.dx < box.maxWidth / 3 ? -1 : 1),
                  onLongPress: () => setState(() => _panel = !_panel),
                  onHorizontalDragEnd: (d) {
                    final v = d.primaryVelocity ?? 0;
                    if (v < -150) _go(1);
                    if (v > 150) _go(-1);
                  },
                  onVerticalDragEnd: (d) {
                    final v = d.primaryVelocity ?? 0;
                    if (v > 400) _exit(); // swipe down closes, like a photo viewer
                  },
                  child: Stack(children: [
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
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      left: 0,
                      right: 0,
                      top: pad.top + 74,
                      bottom: _panel ? 236 + pad.bottom : 40 + pad.bottom,
                      child: IgnorePointer(
                        child: StepModelView(
                          bricks: widget.bricks,
                          step: k,
                          quarters: _quarters,
                          highlight: _highlight,
                          maxA: 64,
                          pad: 28,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      top: 0,
                      bottom: 0,
                      child: Center(child: SideArrow(icon: Icons.chevron_left_rounded, visible: k > 0, active: _flash < 0)),
                    ),
                    Positioned(
                      right: 10,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: SideArrow(
                          icon: last ? Icons.celebration_rounded : Icons.chevron_right_rounded,
                          visible: true,
                          active: _flash > 0,
                          color: last ? Brand.red : null,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
          // ── top: stories-style progress + controls ──
          Positioned(
            left: 12,
            right: 12,
            top: pad.top + 8,
            child: Column(children: [
              Row(children: [
                for (var j = 0; j < n; j++)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: j < k ? Brand.green : (j == k ? p.ink : p.line),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                _RoundButton(icon: Icons.close_rounded, tooltip: t('exit'), onTap: _exit),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${widget.emoji} ${widget.title}', maxLines: 1, overflow: TextOverflow.ellipsis, style: display(17)),
                    Text('${t('step')} ${k + 1} ${t('of')} $n', style: body(13, weight: 800, color: p.muted)),
                  ]),
                ),
                _RoundButton(
                  icon: _highlight ? Icons.auto_awesome_rounded : Icons.auto_awesome_outlined,
                  tooltip: t('highlightNew'),
                  active: _highlight,
                  onTap: () => setState(() => _highlight = !_highlight),
                ),
                const SizedBox(width: 8),
                _RoundButton(icon: Icons.rotate_90_degrees_cw_rounded, tooltip: t('rotate'), onTap: _rotate),
              ]),
            ]),
          ),
          if (!app.stepHintSeen)
            Positioned(
              left: 24,
              right: 24,
              top: pad.top + 84,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: p.ink.withValues(alpha: .86), borderRadius: BorderRadius.circular(99)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.touch_app_rounded, size: 18, color: p.plate),
                    const SizedBox(width: 6),
                    Flexible(child: Text(t('tapHint'), textAlign: TextAlign.center, style: body(12.5, weight: 700, color: p.plate))),
                  ]),
                ),
              ),
            ),
          // ── bottom: what to add now ──
          AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            bottom: _panel ? 0 : -(236 + pad.bottom),
            height: 236 + pad.bottom,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + pad.bottom),
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .12), blurRadius: 20, offset: const Offset(0, -4))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(
                  child: GestureDetector(
                    onTap: () => setState(() => _panel = false),
                    child: Container(width: 40, height: 5, decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(3))),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  step.text?.isNotEmpty == true ? step.text! : pick(catalog.stepLabels[step.label] ?? const {}, app.lang),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: body(19, weight: 750, height: 1.25),
                ),
                const SizedBox(height: 2),
                Text(
                  t('stepHint').replaceAll('{n}', '${step.bricks.length}').replaceAll(
                      '{l}', '${step.bricks.isEmpty ? 1 : step.bricks.map((b) => b.z).reduce((a, b) => a < b ? a : b).round() + 1}'),
                  style: body(13.5, weight: 700, color: p.muted),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final c in partChips(context, step.bricks)) Padding(padding: const EdgeInsets.only(right: 8), child: c),
                    ],
                  ),
                ),
                const Spacer(),
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
                          backgroundColor: last ? Brand.red : Brand.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: last ? () => _exit(finished: true) : () => _go(1),
                        child: Text(last ? '${t('finish')} 🎉' : '${t('next')} →', style: display(17, color: Colors.white)),
                      ),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
          if (!_panel)
            Positioned(
              right: 16,
              bottom: 16 + pad.bottom,
              child: _RoundButton(icon: Icons.list_alt_rounded, tooltip: t('addNow'), onTap: () => setState(() => _panel = true)),
            ),
        ]),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;
  const _RoundButton({required this.icon, required this.tooltip, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active ? Brand.yellow.withValues(alpha: .35) : p.card,
        shape: const CircleBorder(),
        elevation: 2,
        shadowColor: Colors.black26,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 44, height: 44, child: Icon(icon, color: p.ink, size: 22)),
        ),
      ),
    );
  }
}
