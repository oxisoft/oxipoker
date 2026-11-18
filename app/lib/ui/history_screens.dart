import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../api/poker.dart';
import '../l10n/app_localizations.dart';
import '../state/session.dart';
import 'cards.dart';
import 'common.dart';

/// The player's own finished hands, newest first.
class HandsScreen extends ConsumerStatefulWidget {
  const HandsScreen({super.key});

  @override
  ConsumerState<HandsScreen> createState() => _HandsScreenState();
}

class _HandsScreenState extends ConsumerState<HandsScreen> {
  static const _page = 50;
  final _hands = <HandSummary>[];
  bool _loading = false;
  bool _more = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading || !_more) return;
    setState(() => _loading = true);
    final page = await guard(
      context,
      ref,
      () => ref.read(sessionProvider.notifier).api().myHands(before: _hands.lastOrNull?.id, limit: _page),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (page != null) {
        _hands.addAll(page);
        _more = page.length == _page;
      } else {
        _more = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
        title: Text(l.handHistory),
      ),
      body: _hands.isEmpty && !_loading
          ? Center(child: Text(l.noHands, key: const Key('no-hands')))
          : ListView.builder(
              itemCount: _hands.length + (_more ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _hands.length) {
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Center(
                      child: TextButton(key: const Key('more-hands'), onPressed: _load, child: Text(l.loadMore)),
                    ),
                  );
                }
                final h = _hands[i];
                return ListTile(
                  key: Key('hand-${h.id}'),
                  leading: CardRow(cards: h.cards, width: 22),
                  title: Text('${h.tableName} #${h.handNo}'),
                  subtitle: Text('${formatDate(context, h.endedAt)} \u00b7 ${l.potLabel(chips(h.pot))}'),
                  trailing: Text(
                    h.net > 0 ? '+${chips(h.net)}' : chips(h.net),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: h.net > 0
                          ? Colors.green.shade700
                          : h.net < 0
                          ? Colors.red.shade700
                          : null,
                    ),
                  ),
                  onTap: () => context.go('/hands/${h.id}'),
                );
              },
            ),
    );
  }
}

/// Text for one history event, as it was seen at the table.
String eventText(AppLocalizations l, HandReplay r, HandEvent e) {
  final who = r.nameOf(e.seat);
  final amount = chips(e.amount);
  return switch (e.kind) {
        'post_sb' => l.evPostSb(who, amount),
        'post_bb' => l.evPostBb(who, amount),
        'hole' => l.evHole(who, e.cards.join(' ')),
        'fold' => l.evFold(who),
        'check' => l.evCheck(who),
        'call' => l.evCall(who, amount),
        'bet' => l.evBet(who, amount),
        'raise' => l.evRaise(who, amount),
        'return' => l.evReturn(who, amount),
        'board' => l.evBoard(e.street, e.cards.join(' ')),
        'show' => l.evShow(who, e.cards.join(' ')),
        'win' => l.evWin(who, amount),
        _ => e.kind,
      } +
      (e.allIn ? ' (${l.allIn})' : '');
}

/// Replays one stored hand step by step.
class ReplayScreen extends ConsumerStatefulWidget {
  const ReplayScreen({super.key, required this.handId});

  final int handId;

  @override
  ConsumerState<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends ConsumerState<ReplayScreen> {
  late final Future<HandReplay> _hand = ref.read(sessionProvider.notifier).api().hand(widget.handId);
  int? _step;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/hands')),
        title: Text(l.replay),
      ),
      body: FutureBuilder<HandReplay>(
        future: _hand,
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text(errorText(l, snap.error!)));
          final r = snap.data;
          if (r == null) return const SizedBox.shrink();
          final step = _step ?? r.events.length;
          final shown = r.events.take(step).toList();
          final board = [for (final e in shown.where((e) => e.kind == 'board')) ...e.cards];
          return Column(
            children: [
              Container(
                color: context.palette.felt,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '${r.tableName} #${r.handNo} \u00b7 ${l.blinds(r.smallBlind, r.bigBlind)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    CardRow(key: const Key('replay-board'), cards: board, slots: 5, width: 40),
                    const SizedBox(height: 12),
                    if (r.yourCards.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(l.yourCards, style: const TextStyle(color: Colors.white70)),
                          const SizedBox(width: 8),
                          CardRow(cards: r.yourCards, width: 30),
                        ],
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    key: const Key('replay-start'),
                    icon: const Icon(Icons.first_page),
                    onPressed: step > 0 ? () => setState(() => _step = 0) : null,
                  ),
                  IconButton(
                    key: const Key('replay-prev'),
                    icon: const Icon(Icons.chevron_left),
                    onPressed: step > 0 ? () => setState(() => _step = step - 1) : null,
                  ),
                  Text(l.stepOf(step, r.events.length)),
                  IconButton(
                    key: const Key('replay-next'),
                    icon: const Icon(Icons.chevron_right),
                    onPressed: step < r.events.length ? () => setState(() => _step = step + 1) : null,
                  ),
                  IconButton(
                    key: const Key('replay-end'),
                    icon: const Icon(Icons.last_page),
                    onPressed: step < r.events.length ? () => setState(() => _step = r.events.length) : null,
                  ),
                ],
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  children: [
                    for (var i = 0; i < shown.length; i++)
                      ListTile(dense: true, key: Key('event-$i'), title: Text(eventText(l, r, shown[i]))),
                    if (step == r.events.length) ...[
                      const Divider(),
                      for (final s in r.seats)
                        ListTile(
                          dense: true,
                          title: Text(s.name),
                          subtitle: Text('${chips(s.startStack)} \u2192 ${chips(s.endStack)}'),
                          trailing: s.won > 0 ? Text('+${chips(s.won)}', style: const TextStyle(fontWeight: FontWeight.bold)) : null,
                        ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Hands played, won and the biggest pot, for the account screen.
class StatsCard extends ConsumerStatefulWidget {
  const StatsCard({super.key});

  @override
  ConsumerState<StatsCard> createState() => _StatsCardState();
}

class _StatsCardState extends ConsumerState<StatsCard> {
  late final Future<PlayerStats> _stats = ref.read(sessionProvider.notifier).api().stats();

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Card(
      key: const Key('stats-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.stats, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            FutureBuilder<PlayerStats>(
              future: _stats,
              builder: (_, snap) {
                final s = snap.data;
                if (s == null) return Text(snap.hasError ? errorText(l, snap.error!) : '');
                return Wrap(
                  spacing: 24,
                  runSpacing: 8,
                  children: [
                    _Stat(l.handsPlayed, '${s.handsPlayed}', const Key('stat-played')),
                    _Stat(l.handsWon, '${s.handsWon}', const Key('stat-won')),
                    _Stat(l.biggestPot, chips(s.biggestPot), const Key('stat-biggest')),
                    _Stat(l.sngGames, '${s.sngGames}', const Key('stat-sng-games')),
                    _Stat(l.sngWins, '${s.sngWins}', const Key('stat-sng-wins')),
                    _Stat(l.sngBest, s.sngBest > 0 ? '#${s.sngBest}' : '-', const Key('stat-sng-best')),
                  ],
                );
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(key: const Key('stats-hands'), onPressed: () => context.go('/hands'), child: Text(l.handHistory)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.valueKey);

  final String label;
  final String value;
  final Key valueKey;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, key: valueKey, style: Theme.of(context).textTheme.headlineSmall),
      Text(label),
    ],
  );
}
