import 'package:flutter/material.dart';

import '../app.dart';
import '../i18n.dart';
import '../render/iso.dart';
import '../theme.dart';
import '../widgets/common.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  int _i = 0;

  static const _pages = [('ob1t', 'ob1d', 'mix'), ('ob2t', 'ob2d', 'castle'), ('ob3t', 'ob3d', 'dragon')];

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _next() {
    if (_i == _pages.length - 1) {
      app.completeOnboarding();
    } else {
      _page.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: app, builder: (context, _) => _build(context));

  Widget _build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      body: Baseplate(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: [
              Row(children: [
                _LangSwitch(),
                const Spacer(),
                if (_i < _pages.length - 1)
                  TextButton(onPressed: app.completeOnboarding, child: Text(t('skip'), style: body(15, weight: 800, color: p.muted))),
              ]),
              Expanded(
                child: PageView.builder(
                  controller: _page,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _i = i),
                  itemBuilder: (context, i) {
                    final (title, desc, art) = _pages[i];
                    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Expanded(
                        flex: 5,
                        child: art == 'mix'
                            ? PileArt(colors: [for (final c in catalog.piles.first.colors) catalog.colorOf(c.$1)], unit: 24)
                            : ModelPicture(bricks: flatten(catalog.byId[art]!.steps), maxA: 30, pad: 20),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(children: [
                          Text(t(title), textAlign: TextAlign.center, style: display(28, height: 1.1)),
                          const SizedBox(height: 12),
                          Text(t(desc), textAlign: TextAlign.center, style: body(16.5, color: p.muted, height: 1.4)),
                        ]),
                      ),
                    ]);
                  },
                ),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var k = 0; k < _pages.length; k++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: k == _i ? 22 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(color: k == _i ? p.ink : p.line, borderRadius: BorderRadius.circular(4)),
                  ),
              ]),
              const SizedBox(height: 22),
              BrickButton(
                label: _i == _pages.length - 1 ? t('start') : t('next'),
                icon: _i == _pages.length - 1 ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                color: _i == _pages.length - 1 ? Brand.red : Brand.blue,
                onTap: _next,
              ),
              const SizedBox(height: 16),
            ]),
          ),
        ),
      ),
    );
  }
}

class _LangSwitch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (final l in const ['uk', 'pl', 'en'])
          GestureDetector(
            onTap: () => app.setLang(l),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(color: app.lang == l ? p.ink : null, borderRadius: BorderRadius.circular(99)),
              child: Text(l == 'uk' ? 'UA' : l.toUpperCase(), style: body(13, weight: 800, color: app.lang == l ? p.plate : p.muted)),
            ),
          ),
      ]),
    );
  }
}
