import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n.dart';
import '../main.dart';
import '../shopping.dart';
import '../theme.dart';

/// Вкладка «Покупки»: усе, чого бракує для вибраних рецептів, в одному списку.
class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _addCustom(ShoppingStore store) {
    store.addCustom(_ctrl.text);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).shopping;
    final t = L10n.of(context);
    final theme = Theme.of(context);
    final extra = Extra.of(context);

    return SafeArea(
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final items = store.items;
          final hasDone = items.any((i) => i.done);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Text(t.shoppingTitle, style: display(30)),
              if (items.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(t.leftToBuy(store.leftCount), style: theme.textTheme.bodyMedium?.copyWith(color: extra.muted)),
              ],
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    maxLength: 60,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addCustom(store),
                    decoration: InputDecoration(
                      hintText: t.addOwnItem,
                      counterText: '',
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.lime,
                    foregroundColor: AppColors.ink,
                    minimumSize: const Size(52, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  tooltip: t.add,
                  onPressed: () => _addCustom(store),
                  icon: const Icon(Icons.add),
                ),
              ]),
              const SizedBox(height: 14),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: Column(children: [
                    const Text('🧺', style: TextStyle(fontSize: 44)),
                    const SizedBox(height: 10),
                    Text(t.shoppingEmpty,
                        textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: extra.muted)),
                  ]),
                ),
              for (final item in items)
                Dismissible(
                  key: ObjectKey(item),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 22),
                    color: extra.tomatoBg,
                    child: Icon(Icons.delete_outline, color: extra.tomato),
                  ),
                  onDismissed: (_) => store.remove(item),
                  child: _ItemTile(item: item, onTap: () => store.toggle(item), forWord: t.forRecipes),
                ),
              if (items.isNotEmpty) ...[
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: store.leftCount == 0
                      ? null
                      : () async {
                          await Clipboard.setData(ClipboardData(text: store.asText(t.shoppingHeader)));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.listCopied)));
                        },
                  icon: const Icon(Icons.copy),
                  label: Text(t.copyList),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: store.leftCount == 0 ? null : () => Share.share(store.asText(t.shoppingHeader)),
                  icon: const Icon(Icons.ios_share),
                  label: Text(t.share),
                ),
                if (hasDone) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: store.clearDone,
                    icon: const Icon(Icons.cleaning_services_outlined),
                    label: Text(t.clearBought),
                  ),
                ],
                const SizedBox(height: 10),
                Text(t.swipeToDelete,
                    textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: extra.muted)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item, required this.onTap, required this.forWord});
  final ShoppingItem item;
  final VoidCallback onTap;
  final String forWord;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extra = Extra.of(context);
    final sub = [
      if (item.amountText.isNotEmpty) item.amountText,
      if (item.recipes.isNotEmpty) '$forWord: ${item.recipes.join(', ')}',
    ].join('  ·  ');
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.colorScheme.outline))),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: item.done ? AppColors.lime : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: item.done ? AppColors.lime : theme.colorScheme.outline, width: 2),
            ),
            child: item.done ? const Icon(Icons.check, size: 18, color: AppColors.ink) : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                item.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  decoration: item.done ? TextDecoration.lineThrough : null,
                  color: item.done ? extra.muted : null,
                ),
              ),
              if (sub.isNotEmpty)
                Text(sub, style: theme.textTheme.bodySmall?.copyWith(color: extra.muted)),
            ]),
          ),
        ]),
      ),
    );
  }
}
