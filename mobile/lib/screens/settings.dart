import 'package:flutter/material.dart';

import '../app.dart';
import '../i18n.dart';
import '../theme.dart';
import 'scan.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(t('settings'))),
        body: Baseplate(
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 28), children: [
            _Group(title: t('language'), children: [
              RadioGroup<String>(
                groupValue: app.lang,
                onChanged: (v) => app.setLang(v!),
                child: Column(children: [
                  for (final e in langNames.entries)
                    RadioListTile<String>(value: e.key, activeColor: Brand.red, title: Text(e.value, style: body(16, weight: 700))),
                ]),
              ),
            ]),
            const SizedBox(height: 14),
            _Group(title: t('theme'), children: [
              RadioGroup<ThemeMode>(
                groupValue: app.theme,
                onChanged: (v) => app.setTheme(v!),
                child: Column(children: [
                  for (final (m, k) in [(ThemeMode.system, 'themeSystem'), (ThemeMode.light, 'themeLight'), (ThemeMode.dark, 'themeDark')])
                    RadioListTile<ThemeMode>(value: m, activeColor: Brand.red, title: Text(t(k), style: body(16, weight: 700))),
                ]),
              ),
            ]),
            const SizedBox(height: 14),
            const PhotoTips(),
            const SizedBox(height: 14),
            SurfaceCard(
              color: Color.alphaBlend(Brand.green.withValues(alpha: .10), p.card),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('👨‍👩‍👧 ${t('forParents')}', style: display(18)),
                const SizedBox(height: 8),
                Text(t('forParentsText'), style: body(14.5, color: p.muted, height: 1.4)),
              ]),
            ),
            const SizedBox(height: 14),
            _Group(title: t('about'), children: [
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(t('privacy'), style: body(16, weight: 700)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyScreen())),
              ),
              ListTile(
                leading: const Icon(Icons.replay_rounded),
                title: Text(t('showIntro'), style: body(16, weight: 700)),
                onTap: () {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                  app.showOnboardingAgain();
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: Text('${t('version')} ${AppConfig.version}', style: body(16, weight: 700)),
                subtitle: Text(AppConfig.credits, style: body(13, color: p.muted)),
              ),
            ]),
            const SizedBox(height: 18),
            Center(
              child: Image.asset(
                Theme.of(context).brightness == Brightness.dark ? 'assets/brand/koreec_light.png' : 'assets/brand/koreec_dark.png',
                width: 150,
                semanticLabel: 'Koreec Project Group',
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Group({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => SurfaceCard(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(title, style: display(18))),
          const SizedBox(height: 4),
          ...children,
        ]),
      );
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(t('privacy'))),
        body: Baseplate(
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 28), children: [
            SurfaceCard(child: SelectableText(privacyText[app.lang] ?? privacyText['en']!, style: body(15, height: 1.5))),
          ]),
        ),
      );
}
