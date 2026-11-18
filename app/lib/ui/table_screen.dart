import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../api/poker.dart';
import '../l10n/app_localizations.dart';
import '../state/realtime.dart';
import '../state/session.dart';
import 'cards.dart';
import 'common.dart';
import 'lobby_screen.dart' show LinkBanner;

const _rail = Color(0xFF5B3A1E);
const _railLight = Color(0xFF8A5A2B);
const _gold = Color(0xFFFFC400);

/// Sentence for an error code of the realtime protocol.
String intentError(AppLocalizations l, String code) => switch (code) {
  'not_your_turn' => l.wsNotYourTurn,
  'seat_taken' => l.wsSeatTaken,
  'already_seated' => l.wsAlreadySeated,
  'illegal_action' || 'bad_amount' => l.wsIllegal,
  'rate_limited' => l.errRateLimited,
  'spectators_off' => l.wsSpectatorsOff,
  'sng_started' => l.wsSngStarted,
  'too_few_players' => l.wsTooFewPlayers,
  'host_or_admin_only' => l.wsHostOnly,
  'offline' || 'timeout' => l.reconnecting,
  _ => l.errGeneric(code),
};

/// One table: the felt, the seats, the board, the action bar and the chat.
class TableScreen extends ConsumerStatefulWidget {
  const TableScreen({super.key, required this.tableId});

  final String tableId;

  @override
  ConsumerState<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends ConsumerState<TableScreen> {
  late final RealtimeController _rt = ref.read(realtimeProvider.notifier);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _rt.watch(widget.tableId));
  }

  @override
  void dispose() {
    final rt = _rt, id = widget.tableId;
    Future.microtask(() => rt.unwatch(id));
    super.dispose();
  }

  Future<void> _do(Future<String?> Function() intent) async {
    final err = await intent();
    if (err != null && mounted) toast(context, intentError(context.l, err));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final rt = ref.watch(realtimeProvider);
    ref.listen(realtimeProvider.select((s) => s.lastError), (_, e) {
      if (e != null) {
        toast(context, intentError(l, e));
        _rt.clearError();
      }
    });
    final v = rt.watching == widget.tableId ? rt.view : null;
    final me = v?.me;
    return Scaffold(
      backgroundColor: const Color(0xFF16261D),
      appBar: AppBar(
        leading: IconButton(key: const Key('back-lobby'), icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
        title: Text(v?.settings.name ?? l.table),
        actions: [
          if (v != null && v.seated)
            PopupMenuButton<String>(
              key: const Key('seat-menu'),
              onSelected: (a) => _do(switch (a) {
                'sitout' => _rt.sitOut,
                'comeback' => _rt.comeBack,
                _ => _rt.leave,
              }),
              itemBuilder: (_) => [
                if (me != null && !me.sittingOut && me.stack > 0)
                  PopupMenuItem(key: const Key('menu-sitout'), value: 'sitout', child: Text(l.sitOut)),
                if (me != null && (me.sittingOut || me.stack == 0))
                  PopupMenuItem(key: const Key('menu-comeback'), value: 'comeback', child: Text(l.comeBack)),
                PopupMenuItem(key: const Key('menu-leave'), value: 'leave', child: Text(l.leaveSeat)),
              ],
            ),
          Builder(
            builder: (ctx) => IconButton(
              key: const Key('open-chat'),
              tooltip: l.chat,
              icon: Badge(isLabelVisible: rt.chat.isNotEmpty, label: Text('${rt.chat.length}'), child: const Icon(Icons.chat)),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: const ChatDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            LinkBanner(rt.link),
            if (v == null)
              const Expanded(child: SizedBox.shrink())
            else if (v.closed)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l.tableClosed,
                        key: const Key('table-closed'),
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: () => context.go('/'), child: Text(l.backToLobby)),
                    ],
                  ),
                ),
              )
            else ...[
              if (v.sng != null) SngBar(view: v, onStart: () => _do(_rt.startSng)),
              if (!v.seated && !(v.sng?.finished ?? false))
                Container(
                  key: const Key('spectator-banner'),
                  width: double.infinity,
                  color: Colors.black26,
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    l.watchingHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              if (v.sng?.finished ?? false)
                Expanded(
                  child: Standings(sng: v.sng!, me: ref.watch(sessionProvider).user?.id ?? ''),
                )
              else
                Expanded(
                  child: TableFelt(view: v, onSit: (seat) => _do(() => _rt.sit(seat))),
                ),
              if (v.sng?.finished ?? false)
                const SizedBox.shrink()
              else if (v.myLegal != null)
                ActionBar(
                  key: ValueKey('bar-${v.handNo}-${v.hand?.street}-${v.hand?.currentBet}'),
                  legal: v.myLegal!,
                  hand: v.hand!,
                  seats: v.seats,
                  bigBlind: v.settings.bigBlind,
                  onAct: (a, [to]) => _do(() => _rt.act(a, to)),
                )
              else
                _StatusLine(view: v),
            ],
          ],
        ),
      ),
    );
  }
}

/// Sit-and-go strip above the felt: registration with the host's start
/// button, or the blind level with the time left. The clock is the server's;
/// this only counts down to the time it sent.
class SngBar extends ConsumerStatefulWidget {
  const SngBar({super.key, required this.view, required this.onStart});

  final TableView view;
  final VoidCallback onStart;

  @override
  ConsumerState<SngBar> createState() => _SngBarState();
}

class _SngBarState extends ConsumerState<SngBar> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(SngBar old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final ticking = widget.view.sng?.running == true && widget.view.sng?.levelEnds != null;
    if (ticking && _tick == null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) => mounted ? setState(() {}) : null);
    } else if (!ticking) {
      _tick?.cancel();
      _tick = null;
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  static String _left(Duration d) {
    final s = max(0, d.inSeconds);
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final g = widget.view.sng!;
    final user = ref.watch(sessionProvider).user;
    final Widget child;
    if (g.registering) {
      final n = widget.view.seats.whereType<SeatView>().length;
      final canStart = user != null && (user.id == widget.view.host || user.isAdmin);
      child = Row(
        children: [
          Expanded(
            child: Text(
              l.sngRegistering(n),
              key: const Key('sng-registering'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          if (canStart) FilledButton(key: const Key('sng-start'), onPressed: n >= 2 ? widget.onStart : null, child: Text(l.startGame)),
        ],
      );
    } else if (g.running) {
      final ends = g.levelEnds;
      final next = ends == null
          ? l.sngLastLevel
          : ends.isAfter(DateTime.now())
          ? l.sngNext(g.nextSmall, g.nextBig, _left(ends.difference(DateTime.now())))
          : l.sngNextHand(g.nextSmall, g.nextBig);
      child = Row(
        children: [
          const Icon(Icons.timer, color: _gold, size: 18),
          const SizedBox(width: 8),
          Text(
            l.sngLevel(g.level + 1, g.smallBlind, g.bigBlind),
            key: const Key('sng-level'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              next,
              key: const Key('sng-next'),
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
    return Container(
      key: const Key('sng-bar'),
      width: double.infinity,
      color: Colors.black38,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: child,
    );
  }
}

/// Final standings of a finished sit-and-go, winner first.
class Standings extends StatelessWidget {
  const Standings({super.key, required this.sng, required this.me});

  final SngView sng;
  final String me;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final mine = sng.places.where((p) => p.user == me && me.isNotEmpty).firstOrNull;
    return Center(
      child: Card(
        key: const Key('standings'),
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.standings, style: Theme.of(context).textTheme.titleLarge),
              if (mine != null) ...[const SizedBox(height: 4), Text(l.youFinished(mine.place), key: const Key('you-finished'))],
              const SizedBox(height: 12),
              for (final p in sng.places)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        child: p.place == 1 ? const Icon(Icons.emoji_events, color: _gold, size: 20) : const SizedBox.shrink(),
                      ),
                      Text(l.placeLine(p.place, p.name), key: Key('place-${p.place}')),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(onPressed: () => context.go('/'), child: Text(l.backToLobby)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.view});

  final TableView view;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final h = view.hand;
    final me = view.me;
    String text;
    if (me != null && me.sittingOut) {
      text = me.stack == 0 ? l.bustedHint : l.sittingOutHint;
    } else if (h == null || h.done) {
      text = view.seats.where((s) => s != null && !s.sittingOut && s.stack > 0).length < 2 ? l.waitingForPlayers : l.nextHandSoon;
    } else if (h.toAct >= 0 && h.toAct < view.seats.length) {
      text = l.waitingFor(view.seats[h.toAct]?.name ?? '');
    } else {
      text = '';
    }
    return Container(
      key: const Key('status-line'),
      height: 56,
      alignment: Alignment.center,
      color: Colors.black26,
      child: Text(text, style: const TextStyle(color: Colors.white70)),
    );
  }
}

/// The oval table with rail, felt, board, pots and seats around it. The
/// viewer's own seat is always at the bottom.
class TableFelt extends StatelessWidget {
  const TableFelt({super.key, required this.view, required this.onSit});

  final TableView view;
  final void Function(int seat) onSit;

  @override
  Widget build(BuildContext context) {
    final n = view.settings.seats;
    final bottom = view.seated ? view.yourSeat : 0;
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth, h = box.maxHeight;
        final seatW = min(120.0, w / 4.2);
        final seatH = seatW * 1.15;
        final rx = (w - seatW) / 2, ry = (h - seatH) / 2;
        final cx = w / 2, cy = h / 2;
        final cardW = min(44.0, w / 11);
        final hand = view.hand;
        return Stack(
          children: [
            // Rail and felt.
            Positioned(
              left: seatW * 0.35,
              right: seatW * 0.35,
              top: seatH * 0.35,
              bottom: seatH * 0.35,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.elliptical(w, h)),
                  gradient: const LinearGradient(colors: [_railLight, _rail], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 6))],
                ),
                padding: EdgeInsets.all(max(10, w / 40)),
                child: Container(
                  key: const Key('felt'),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.elliptical(w, h)),
                    gradient: const RadialGradient(colors: [Color(0xFF15834F), felt], radius: 0.9),
                  ),
                ),
              ),
            ),
            // Board and pots in the middle.
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hand != null) ...[
                      CardRow(key: const Key('board'), cards: hand.board, slots: 5, width: cardW),
                      const SizedBox(height: 8),
                      _Pots(hand: hand),
                      if (hand.done) _Results(view: view),
                    ] else
                      Text(view.settings.name, style: const TextStyle(color: Colors.white24, fontSize: 22)),
                  ],
                ),
              ),
            ),
            for (var s = 0; s < n; s++)
              () {
                final k = (s - bottom) % n;
                final a = pi / 2 + 2 * pi * k / n;
                return Positioned(
                  left: cx + rx * cos(a) - seatW / 2,
                  top: cy + ry * sin(a) - seatH / 2,
                  width: seatW,
                  height: seatH,
                  child: SeatBox(view: view, seat: s, cardW: cardW * 0.8, onSit: onSit),
                );
              }(),
          ],
        );
      },
    );
  }
}

class _Pots extends StatelessWidget {
  const _Pots({required this.hand});

  final HandView hand;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    if (hand.pots.isEmpty) return const SizedBox(height: 20);
    return Wrap(
      key: const Key('pots'),
      spacing: 8,
      children: [
        for (var i = 0; i < hand.pots.length; i++)
          Chip(
            visualDensity: VisualDensity.compact,
            label: Text(i == 0 ? l.potMain(chips(hand.pots[i].amount)) : l.potSide(i, chips(hand.pots[i].amount))),
          ),
      ],
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.view});

  final TableView view;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final won = <int, int>{};
    for (final r in view.hand!.results) {
      for (var i = 0; i < r.winners.length && i < r.shares.length; i++) {
        won[r.winners[i]] = (won[r.winners[i]] ?? 0) + r.shares[i];
      }
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        key: const Key('results'),
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final e in won.entries)
            Text(
              l.wins(view.seats.elementAtOrNull(e.key)?.name ?? '#${e.key + 1}', chips(e.value)),
              style: const TextStyle(color: _gold, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}

/// One seat: avatar, name, stack, cards, bet, dealer button, turn timer.
class SeatBox extends StatelessWidget {
  const SeatBox({super.key, required this.view, required this.seat, required this.cardW, required this.onSit});

  final TableView view;
  final int seat;
  final double cardW;
  final void Function(int seat) onSit;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final p = seat < view.seats.length ? view.seats[seat] : null;
    final hand = view.hand;
    if (p == null) {
      return Center(
        child: !view.seated
            ? OutlinedButton(
                key: Key('sit-$seat'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
                onPressed: () => onSit(seat),
                child: Text(l.sit),
              )
            : Text(l.emptySeat, style: const TextStyle(color: Colors.white38)),
      );
    }
    final toAct = hand != null && !hand.done && hand.toAct == seat;
    final mine = seat == view.yourSeat;
    final winner = hand != null && hand.done && hand.results.any((r) => r.winners.contains(seat));
    final dim = p.folded || p.sittingOut;
    final status = p.sittingOut
        ? l.sittingOut
        : p.folded
        ? l.folded
        : p.allIn
        ? l.allIn
        : null;
    return Column(
      key: Key('seat-$seat'),
      mainAxisSize: MainAxisSize.min,
      children: [
        if (p.cards.isNotEmpty || p.hasCards)
          CardRow(key: Key('cards-$seat'), cards: p.cards, count: p.cards.isEmpty ? 2 : 0, width: mine ? cardW * 1.25 : cardW, dim: dim),
        const SizedBox(height: 2),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: dim ? 0.35 : 0.65),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: toAct || winner ? _gold : (mine ? Colors.white54 : Colors.transparent), width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Avatar(user: p.user, name: p.name),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          p.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        Text(
                          chips(p.stack),
                          key: Key('stack-$seat'),
                          style: const TextStyle(color: _gold, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        if (status != null) Text(status, style: const TextStyle(color: Colors.white60, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (hand != null && hand.button == seat)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  key: const Key('dealer-button'),
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Text(
                    'D',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
              ),
          ],
        ),
        if (toAct && hand.deadline != null) TurnTimer(deadline: hand.deadline!, total: view.settings.turnTime),
        if (p.bet > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Container(
              key: Key('bet-$seat'),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Text(chips(p.bet), style: const TextStyle(fontSize: 11, color: Colors.black)),
            ),
          ),
      ],
    );
  }
}

class _Avatar extends ConsumerWidget {
  const _Avatar({required this.user, required this.name});

  final String user;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initials = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    final hue = (user.hashCode % 360).abs().toDouble();
    final fallback = CircleAvatar(
      radius: 14,
      backgroundColor: HSLColor.fromAHSL(1, hue, 0.45, 0.4).toColor(),
      child: Text(initials, style: const TextStyle(fontSize: 12, color: Colors.white)),
    );
    if (!ref.watch(seatAvatarsProvider)) return fallback;
    final s = ref.watch(sessionProvider);
    final api = ref.read(sessionProvider.notifier).api();
    return ClipOval(
      child: Image.network(
        api.server.replace(path: '/api/v1/users/$user/avatar').toString(),
        width: 28,
        height: 28,
        fit: BoxFit.cover,
        headers: ref.read(nativeProvider) && s.token != null ? {'Authorization': 'Bearer ${s.token}'} : null,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

/// Avatars from the server on seats; widget tests switch them off.
final seatAvatarsProvider = Provider<bool>((ref) => true);

/// Bar under the seat of the player to act, from the deadline the server set.
class TurnTimer extends StatefulWidget {
  const TurnTimer({super.key, required this.deadline, required this.total});

  final DateTime deadline;
  final int total;

  @override
  State<TurnTimer> createState() => _TurnTimerState();
}

class _TurnTimerState extends State<TurnTimer> {
  Timer? _t;

  double get _left {
    final ms = widget.deadline.difference(DateTime.now()).inMilliseconds;
    return widget.total <= 0 ? 0 : (ms / (widget.total * 1000)).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(TurnTimer old) {
    super.didUpdateWidget(old);
    if (old.deadline != widget.deadline) _start();
  }

  void _start() {
    _t?.cancel();
    if (_left <= 0) return;
    _t = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_left <= 0) _t?.cancel();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 3),
    child: SizedBox(
      width: 70,
      child: LinearProgressIndicator(
        key: const Key('turn-timer'),
        value: _left,
        minHeight: 4,
        color: _left < 0.25 ? const Color(0xFFFF2A3D) : _gold,
        backgroundColor: Colors.white24,
      ),
    ),
  );
}

/// Fold, check or call, bet or raise with a slider and presets. Only what
/// the server lists as legal is enabled.
class ActionBar extends StatefulWidget {
  const ActionBar({super.key, required this.legal, required this.hand, required this.seats, required this.bigBlind, required this.onAct});

  final Legal legal;
  final HandView hand;
  final List<SeatView?> seats;
  final int bigBlind;
  final void Function(String action, [int? to]) onAct;

  @override
  State<ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends State<ActionBar> {
  late int _to = widget.legal.minTo;

  Legal get _l => widget.legal;

  /// Raise to the size of the pot (or a fraction of it) after calling.
  int _potTo(double fraction) {
    final bets = widget.seats.fold<int>(0, (s, p) => s + (p?.bet ?? 0));
    final pot = widget.hand.potTotal + bets + _l.call;
    final to = widget.hand.currentBet + (pot * fraction).round();
    return to.clamp(_l.minTo, _l.maxTo);
  }

  void _set(int v) => setState(() => _to = v.clamp(_l.minTo, _l.maxTo));

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final canBet = _l.canBet;
    final allIn = canBet && _to >= _l.maxTo;
    final betLabel = allIn ? l.allInTo(chips(_to)) : (_l.betKind == 'raise' ? l.raiseTo(chips(_to)) : l.betAmount(chips(_to)));
    return Container(
      key: const Key('action-bar'),
      color: Colors.black54,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canBet && _l.maxTo > _l.minTo) ...[
            Row(
              children: [
                for (final (key, label, value) in [
                  ('preset-min', l.presetMin, _l.minTo),
                  ('preset-half', l.presetHalfPot, _potTo(0.5)),
                  ('preset-pot', l.presetPot, _potTo(1)),
                  ('preset-allin', l.presetAllIn, _l.maxTo),
                ])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: OutlinedButton(
                        key: Key(key),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                        ),
                        onPressed: () => _set(value),
                        child: Text(label, maxLines: 1, overflow: TextOverflow.fade),
                      ),
                    ),
                  ),
              ],
            ),
            Slider(
              key: const Key('bet-slider'),
              min: _l.minTo.toDouble(),
              max: _l.maxTo.toDouble(),
              divisions: widget.bigBlind > 0 ? max(1, min(200, (_l.maxTo - _l.minTo) ~/ max(1, widget.bigBlind))) : null,
              value: _to.toDouble().clamp(_l.minTo.toDouble(), _l.maxTo.toDouble()),
              label: chips(_to),
              onChanged: (v) => _set(v == _l.maxTo ? _l.maxTo : v.round()),
            ),
          ],
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  key: const Key('act-fold'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8E1B2B)),
                  onPressed: _l.fold ? () => widget.onAct('fold') : null,
                  child: Text(l.fold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _l.check
                    ? FilledButton(key: const Key('act-check'), onPressed: () => widget.onAct('check'), child: Text(l.check))
                    : FilledButton(
                        key: const Key('act-call'),
                        onPressed: _l.call > 0 ? () => widget.onAct('call') : null,
                        child: Text(l.callAmount(chips(_l.call))),
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  key: const Key('act-bet'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB26A00)),
                  onPressed: canBet ? () => widget.onAct(_l.betKind, _to) : null,
                  child: Text(canBet ? betLabel : l.bet, maxLines: 1, overflow: TextOverflow.fade),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Table chat: players and spectators, kept only in memory.
class ChatDrawer extends ConsumerStatefulWidget {
  const ChatDrawer({super.key});

  @override
  ConsumerState<ChatDrawer> createState() => _ChatDrawerState();
}

class _ChatDrawerState extends ConsumerState<ChatDrawer> {
  final _text = TextEditingController();

  Future<void> _send() async {
    final t = _text.text.trim();
    if (t.isEmpty) return;
    final err = await ref.read(realtimeProvider.notifier).chat(t);
    if (!mounted) return;
    if (err == null) {
      _text.clear();
    } else {
      toast(context, intentError(context.l, err));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final chat = ref.watch(realtimeProvider.select((s) => s.chat));
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(title: Text(l.chat), subtitle: Text(l.chatNotStored)),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                key: const Key('chat-list'),
                reverse: true,
                itemCount: chat.length,
                itemBuilder: (_, i) {
                  final m = chat[chat.length - 1 - i];
                  return ListTile(dense: true, title: Text(m.text), subtitle: Text(m.name));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('chat-field'),
                      controller: _text,
                      maxLength: 300,
                      decoration: InputDecoration(hintText: l.chatHint, counterText: ''),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(key: const Key('chat-send'), icon: const Icon(Icons.send), onPressed: _send),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
