import 'package:flutter/material.dart';

import '../history.dart';
import '../l10n.dart';
import '../main.dart';
import '../theme.dart';
import 'result_screen.dart';

/// «Мої завдання»: розібране раніше — повторити перед контрольною. ⭐ — не видаляються автоматично.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = AppScope.of(context).history;
    final t = L10n.of(context);
    final extra = Extra.of(context);
    return SafeArea(
      child: ListenableBuilder(
        listenable: history,
        builder: (context, _) {
          final items = List<Entry>.of(history.items)..sort((a, b) => a.starred == b.starred ? 0 : (a.starred ? -1 : 1));
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Text(t.historyTitle, style: display(30)),
              const SizedBox(height: 18),
              if (items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: extra.leaf, borderRadius: BorderRadius.circular(24)),
                  child: Column(children: [
                    const Text('📒', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 10),
                    Text(t.historyEmpty, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4)),
                  ]),
                )
              else
                for (final e in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Dismissible(
                      key: ValueKey(e.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(color: extra.redBg, borderRadius: BorderRadius.circular(20)),
                        child: Icon(Icons.delete_outline, color: extra.red),
                      ),
                      onDismissed: (_) => history.remove(e),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                          leading: Text(e.result.emoji, style: const TextStyle(fontSize: 28)),
                          title: Text(e.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text('${t.dateLabel(e.date)} · ${t.tasksN(e.result.solutions.length)}'),
                          trailing: IconButton(
                            tooltip: t.star,
                            onPressed: () => history.toggleStar(e),
                            icon: Icon(e.starred ? Icons.star : Icons.star_border, color: e.starred ? AppColors.amber : null),
                          ),
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ResultScreen(images: const [], saved: e.result),
                          )),
                        ),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
