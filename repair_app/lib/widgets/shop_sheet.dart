import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n.dart';
import '../models.dart';
import '../shops.dart';
import '../theme.dart';

/// «Де купити»: кнопки пошуку деталі в магазинах.
Future<void> showShopSheet(BuildContext context, Part part, {String? brandModel}) {
  final t = L10n.of(context);
  final shops = shopsFor(t.code);
  final query = shopQuery(part.name, brandModel: brandModel, isTool: part.isTool);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final extra = Extra.of(ctx);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('🛒 ${t.whereBuy}', style: display(22)),
            const SizedBox(height: 4),
            Text(query, style: const TextStyle(fontWeight: FontWeight.w800)),
            if (part.price != null) Text(part.price!, style: TextStyle(color: extra.muted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(t.whereBuyHint, style: TextStyle(color: extra.muted, height: 1.35)),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in shops)
                ActionChip(
                  avatar: Text(s.emoji),
                  label: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await launchUrl(s.search(query), mode: LaunchMode.externalApplication);
                  },
                ),
            ]),
          ]),
        ),
      );
    },
  );
}
