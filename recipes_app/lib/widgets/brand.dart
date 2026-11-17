import 'package:flutter/material.dart';

import '../config.dart';
import '../theme.dart';

/// Логотип Koreec Project Group + підпис. Однаковий у всіх апках на двигуні PhotoAI.
class BrandFooter extends StatelessWidget {
  const BrandFooter({super.key, this.appName, this.logoHeight = 72});

  /// Назва й версія апки над підписом (напр. в «Налаштуваннях»); null — лише логотип і ©.
  final String? appName;
  final double logoHeight;

  @override
  Widget build(BuildContext context) {
    final muted = Extra.of(context).muted;
    final small = Theme.of(context).textTheme.bodySmall?.copyWith(color: muted);
    return Semantics(
      label: AppConfig.credit,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Image.asset(AppConfig.logo, height: logoHeight, fit: BoxFit.contain, excludeFromSemantics: true),
        const SizedBox(height: 8),
        if (appName != null) Text('$appName · ${AppConfig.version}', style: small?.copyWith(fontWeight: FontWeight.w700)),
        Text(AppConfig.credit, textAlign: TextAlign.center, style: small),
      ]),
    );
  }
}
