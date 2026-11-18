import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oxipoker/api/poker.dart';
import 'package:oxipoker/main.dart';
import 'package:oxipoker/realtime/socket.dart';
import 'package:oxipoker/state/realtime.dart';
import 'package:oxipoker/state/session.dart';
import 'package:oxipoker/ui/cards.dart';
import 'package:oxipoker/ui/table_screen.dart';

import 'fake_server.dart';

/// In-memory realtime server: answers intents and pushes views.
class FakeHub {
  final sockets = <FakeSocket>[];
  final sent = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> lobby = [];
  Map<String, Map<String, dynamic>> views = {};

  PokerSocket open(Uri uri, String? token) {
    expect(uri.path, '/api/v1/ws');
    final s = FakeSocket(this);
    sockets.add(s);
    return s;
  }

  void handle(FakeSocket s, Map<String, dynamic> m) {
    sent.add(m);
    switch (m['type']) {
      case 'lobby':
        if (m['on'] == true) s.push({'type': 'lobby', 'tables': lobby});
      case 'watch':
        final v = views[m['table']];
        if (v != null) s.push({'type': 'view', 'view': v});
      case 'chat':
        s.push({'type': 'ok', 'id': m['id']});
        s.push({'type': 'chat', 'table': 't1', 'user': 'u1', 'name': 'Alice', 'text': m['text'], 'at': '2026-11-18T14:00:00Z'});
      default:
        if (m['id'] != null) s.push({'type': 'ok', 'id': m['id']});
    }
  }

  Iterable<Map<String, dynamic>> ofType(String t) => sent.where((m) => m['type'] == t);
}

class FakeSocket implements PokerSocket {
  FakeSocket(this.hub);

  final FakeHub hub;
  final _in = StreamController<String>();

  @override
  Future<void> get ready => Future.value();

  @override
  Stream<String> get messages => _in.stream;

  @override
  void send(String text) => scheduleMicrotask(() => hub.handle(this, jsonDecode(text) as Map<String, dynamic>));

  void push(Map<String, dynamic> m) {
    if (!_in.isClosed) _in.add(jsonEncode(m));
  }

  /// The network went away (a phone that slept).
  Future<void> drop() => _in.close();

  @override
  Future<void> close() async {
    if (!_in.isClosed) await _in.close();
  }
}

const settings = {
  'name': 'Friday',
  'seats': 3,
  'small_blind': 5,
  'big_blind': 10,
  'starting_stack': 1000,
  'turn_time': 30,
  'spectators': true,
};

Map<String, dynamic> playerView() => {
  'id': 't1',
  'version': 7,
  'settings': settings,
  'host': 'u1',
  'your_seat': 0,
  'hand_no': 4,
  'seats': [
    {
      'user': 'u1',
      'name': 'Alice',
      'stack': 990,
      'in_hand': true,
      'has_cards': true,
      'cards': ['As', 'Kh'],
    },
    {'user': 'u2', 'name': 'bob', 'stack': 980, 'in_hand': true, 'has_cards': true, 'bet': 20},
    {'user': 'u3', 'name': 'carol', 'stack': 990, 'in_hand': true, 'has_cards': true, 'bet': 10},
  ],
  'hand': {
    'street': 'preflop',
    'board': [],
    'pots': [],
    'button': 1,
    'sb': 2,
    'bb': 1,
    'to_act': 0,
    'current_bet': 20,
    'legal': {'seat': 0, 'fold': true, 'check': false, 'call': 20, 'bet_kind': 'raise', 'min_to': 40, 'max_to': 990},
    'events': [],
  },
};

Map<String, dynamic> spectatorView() => {
  'id': 't1',
  'version': 7,
  'settings': settings,
  'host': 'u2',
  'your_seat': -1,
  'hand_no': 4,
  'seats': [
    null,
    {'user': 'u2', 'name': 'bob', 'stack': 980, 'in_hand': true, 'has_cards': true, 'bet': 20},
    {'user': 'u3', 'name': 'carol', 'stack': 990, 'in_hand': true, 'has_cards': true, 'bet': 10},
  ],
  'hand': {
    'street': 'flop',
    'board': ['2c', '7d', 'Th'],
    'pots': [
      {
        'amount': 40,
        'eligible': [1, 2],
      },
    ],
    'button': 1,
    'sb': 2,
    'bb': 1,
    'to_act': 2,
    'current_bet': 20,
    'events': [],
  },
};

Future<(FakeServer, FakeHub)> pumpGame(WidgetTester tester, {FakeHub? hub}) async {
  final f = FakeServer()..signedIn = 'u1';
  final h = hub ?? FakeHub();
  await tester.binding.setSurfaceSize(const Size(1000, 1400));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        nativeProvider.overrideWithValue(false),
        sessionStoreProvider.overrideWithValue(MemorySessionStore(server: Uri.parse('https://poker.example.com'))),
        httpClientProvider.overrideWithValue(f.client),
        socketFactoryProvider.overrideWithValue(h.open),
        seatAvatarsProvider.overrideWithValue(false),
      ],
      child: const OxiPokerApp(),
    ),
  );
  await tester.pumpAndSettle();
  return (f, h);
}

Future<void> openTable(WidgetTester tester, FakeHub hub) async {
  await tester.tap(find.byKey(const Key('table-t1')));
  await tester.pumpAndSettle();
}

void main() {
  test('reconnect delay grows and stays bounded', () {
    for (var a = 0; a < 20; a++) {
      final d = reconnectDelay(a).inMilliseconds;
      expect(d, greaterThanOrEqualTo(250));
      expect(d, lessThanOrEqualTo(15000));
    }
    expect(reconnectDelay(0).inMilliseconds, lessThanOrEqualTo(500));
  });

  test('views parse cards, legal actions and seats', () {
    final v = TableView.fromJson(playerView());
    expect(v.me!.cards, ['As', 'Kh']);
    expect(v.myLegal!.call, 20);
    expect(v.myLegal!.betKind, 'raise');
    final s = TableView.fromJson(spectatorView());
    expect(s.seated, isFalse);
    expect(s.myLegal, isNull);
    expect(s.seats[0], isNull);
    expect(s.hand!.potTotal, 40);
  });

  testWidgets('lobby lists live tables and creates one', (tester) async {
    final hub = FakeHub()
      ..lobby = [
        {
          'id': 't1',
          'host': 'u2',
          'settings': settings,
          'taken': 2,
          'players': ['bob', 'carol'],
          'hand_no': 4,
        },
      ];
    final (f, _) = await pumpGame(tester, hub: hub);
    expect(hub.ofType('lobby').first['on'], true);
    expect(find.byKey(const Key('table-t1')), findsOneWidget);
    expect(find.text('Friday'), findsOneWidget);
    expect(find.textContaining('bob, carol'), findsOneWidget);
    // Alice is an admin: she may close any table.
    expect(find.byKey(const Key('close-t1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('create-table')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('table-bb')), '1');
    await tester.tap(find.byKey(const Key('table-create')));
    await tester.pumpAndSettle();
    expect(find.text('Blinds must be at least 1, and the small blind not above the big blind.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('table-bb')), '10');
    await tester.enterText(find.byKey(const Key('table-name')), 'Saturday');
    await tester.tap(find.byKey(const Key('table-create')));
    await tester.pumpAndSettle();
    expect(f.requests, contains('POST /tables'));
    expect(f.tables.single['settings']['name'], 'Saturday');
    expect(f.tables.single['settings']['big_blind'], 10);
    expect(hub.ofType('watch').last['table'], 't9');
  });

  testWidgets('sit-and-go: create, register, start, level clock, standings', (tester) async {
    final sngSettings = {...settings, 'kind': 'sng', 'structure': 'turbo'};
    Map<String, dynamic> sngView(Map<String, dynamic> sng) => {
      'id': 't1',
      'version': 3,
      'settings': sngSettings,
      'host': 'u1',
      'your_seat': 0,
      'hand_no': 0,
      'seats': [
        {'user': 'u1', 'name': 'Alice', 'stack': 1000},
        {'user': 'u2', 'name': 'bob', 'stack': 1000},
        null,
      ],
      'sng': sng,
    };
    final hub = FakeHub()
      ..lobby = [
        {
          'id': 't1',
          'host': 'u1',
          'settings': sngSettings,
          'taken': 2,
          'players': ['Alice', 'bob'],
          'hand_no': 0,
        },
      ]
      ..views = {
        't1': sngView({'phase': 'registering', 'places': []}),
      };
    final (f, _) = await pumpGame(tester, hub: hub);
    expect(find.textContaining('Sit-and-go'), findsOneWidget);

    // The create dialog sends kind and structure.
    await tester.tap(find.byKey(const Key('create-table')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('table-structure')), findsNothing);
    await tester.tap(find.byKey(const Key('kind-sng')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('table-structure')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('structure-turbo')).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('table-create')));
    await tester.pumpAndSettle();
    expect(f.tables.single['settings']['kind'], 'sng');
    expect(f.tables.single['settings']['structure'], 'turbo');

    // Registration: the host starts the game.
    await tester.tap(find.byKey(const Key('back-lobby')));
    await tester.pumpAndSettle();
    await openTable(tester, hub);
    expect(find.textContaining('Registration: 2 seated'), findsOneWidget);
    await tester.tap(find.byKey(const Key('sng-start')));
    await tester.pumpAndSettle();
    expect(hub.ofType('start'), hasLength(1));

    // Running: the level and the server's clock.
    hub.sockets.last.push({
      'type': 'view',
      'view': sngView({
        'phase': 'running',
        'level': 1,
        'small_blind': 10,
        'big_blind': 15,
        'next_small_blind': 10,
        'next_big_blind': 20,
        'level_ends': DateTime.now().toUtc().add(const Duration(seconds: 125)).toIso8601String(),
        'places': [],
      }),
    });
    await tester.pump();
    await tester.pump();
    expect(find.text('Level 2: 10/15'), findsOneWidget);
    expect(find.textContaining('next 10/20 in 2:0'), findsOneWidget);
    expect(find.byKey(const Key('sng-start')), findsNothing);

    // Finished: standings replace the felt.
    hub.sockets.last.push({
      'type': 'view',
      'view': sngView({
        'phase': 'finished',
        'level': 3,
        'small_blind': 20,
        'big_blind': 40,
        'places': [
          {'place': 1, 'user': 'u2', 'name': 'bob'},
          {'place': 2, 'user': 'u1', 'name': 'Alice'},
        ],
      }),
    });
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('standings')), findsOneWidget);
    expect(find.byKey(const Key('felt')), findsNothing);
    expect(find.text('1. bob'), findsOneWidget);
    expect(find.text('You finished #2'), findsOneWidget);
  });

  test('stats parse sit-and-go fields', () {
    final s = PlayerStats.fromJson({'hands_played': 3, 'sng_games': 2, 'sng_wins': 1, 'sng_best_place': 1});
    expect((s.handsPlayed, s.sngGames, s.sngWins, s.sngBest), (3, 2, 1, 1));
  });

  testWidgets('player to act sees only legal actions and raises a pot', (tester) async {
    final hub = FakeHub()
      ..lobby = [
        {
          'id': 't1',
          'host': 'u1',
          'settings': settings,
          'taken': 3,
          'players': ['Alice', 'bob', 'carol'],
          'hand_no': 4,
        },
      ]
      ..views = {'t1': playerView()};
    await pumpGame(tester, hub: hub);
    await openTable(tester, hub);
    expect(hub.ofType('watch').last['table'], 't1');
    expect(find.byKey(const Key('felt')), findsOneWidget);
    expect(find.byKey(const Key('dealer-button')), findsOneWidget);
    expect(find.byKey(const Key('action-bar')), findsOneWidget);
    // Facing a bet: call, no check.
    expect(find.byKey(const Key('act-check')), findsNothing);
    expect(find.text('Call 20'), findsOneWidget);
    expect(find.text('Raise to 40'), findsOneWidget);
    // Own cards face up, others face down.
    final mine = tester.widgetList<PlayingCard>(find.descendant(of: find.byKey(const Key('cards-0')), matching: find.byType(PlayingCard)));
    expect(mine.map((c) => c.card), ['As', 'Kh']);
    final bobs = tester.widgetList<PlayingCard>(find.descendant(of: find.byKey(const Key('cards-1')), matching: find.byType(PlayingCard)));
    expect(bobs.map((c) => c.card), [null, null]);

    // Pot: bets 30 + call 20 = 50 on top of the current bet of 20.
    await tester.tap(find.byKey(const Key('preset-pot')));
    await tester.pump();
    expect(find.text('Raise to 70'), findsOneWidget);
    await tester.tap(find.byKey(const Key('act-bet')));
    await tester.pumpAndSettle();
    final act = hub.ofType('act').last;
    expect(act['action'], 'raise');
    expect(act['to'], 70);

    await tester.tap(find.byKey(const Key('preset-allin')));
    await tester.pump();
    expect(find.text('All-in 990'), findsOneWidget);

    await tester.tap(find.byKey(const Key('act-fold')));
    await tester.pumpAndSettle();
    expect(hub.ofType('act').last['action'], 'fold');

    // The server moves on: no legal actions for us, the bar goes away.
    final next = playerView();
    (next['hand'] as Map).remove('legal');
    (next['hand'] as Map)['to_act'] = 1;
    hub.sockets.last.push({'type': 'view', 'view': next});
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('action-bar')), findsNothing);
    expect(find.text('Waiting for bob'), findsOneWidget);
  });

  testWidgets('spectator sees no hole cards, can sit and chat', (tester) async {
    final hub = FakeHub()
      ..lobby = [
        {
          'id': 't1',
          'host': 'u2',
          'settings': settings,
          'taken': 2,
          'players': ['bob', 'carol'],
          'hand_no': 4,
        },
      ]
      ..views = {'t1': spectatorView()};
    await pumpGame(tester, hub: hub);
    await openTable(tester, hub);
    expect(find.byKey(const Key('spectator-banner')), findsOneWidget);
    expect(find.byKey(const Key('action-bar')), findsNothing);
    for (final seat in ['cards-1', 'cards-2']) {
      final cards = tester.widgetList<PlayingCard>(find.descendant(of: find.byKey(Key(seat)), matching: find.byType(PlayingCard)));
      expect(cards.every((c) => c.card == null), isTrue, reason: seat);
    }
    final board = tester.widgetList<PlayingCard>(find.descendant(of: find.byKey(const Key('board')), matching: find.byType(PlayingCard)));
    expect(board.map((c) => c.card), ['2c', '7d', 'Th']);
    expect(find.text('Pot 40'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sit-0')));
    await tester.pumpAndSettle();
    expect(hub.ofType('sit').last['seat'], 0);

    await tester.tap(find.byKey(const Key('open-chat')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('chat-field')), 'nice hand');
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    expect(hub.ofType('chat').last['text'], 'nice hand');
    expect(find.descendant(of: find.byKey(const Key('chat-list')), matching: find.text('nice hand')), findsOneWidget);
  });

  testWidgets('a dropped connection reconnects and watches the table again', (tester) async {
    final hub = FakeHub()
      ..lobby = [
        {
          'id': 't1',
          'host': 'u2',
          'settings': settings,
          'taken': 2,
          'players': ['bob', 'carol'],
          'hand_no': 4,
        },
      ]
      ..views = {'t1': spectatorView()};
    await pumpGame(tester, hub: hub);
    await openTable(tester, hub);
    expect(hub.sockets, hasLength(1));
    final watches = hub.ofType('watch').length;

    await hub.sockets.last.drop();
    await tester.pump();
    expect(find.byKey(const Key('link-banner')), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(hub.sockets, hasLength(2));
    expect(hub.ofType('watch').length, watches + 1);
    expect(hub.ofType('watch').last['table'], 't1');
    expect(find.byKey(const Key('link-banner')), findsNothing);
    expect(find.byKey(const Key('spectator-banner')), findsOneWidget);
  });

  testWidgets('hand history replays a hand; stats on the account screen', (tester) async {
    await pumpGame(tester);
    await tester.tap(find.byKey(const Key('open-hands')));
    await tester.pumpAndSettle();
    expect(find.text('Friday #3'), findsOneWidget);
    expect(find.text('+30'), findsOneWidget);
    await tester.tap(find.byKey(const Key('hand-1')));
    await tester.pumpAndSettle();
    expect(find.text('Alice is dealt As Ks'), findsOneWidget);
    expect(find.text('Alice wins 40'), findsOneWidget);
    expect(find.text('9 of 9'), findsOneWidget);

    await tester.tap(find.byKey(const Key('replay-start')));
    await tester.pumpAndSettle();
    expect(find.text('0 of 9'), findsOneWidget);
    expect(find.byKey(const Key('event-0')), findsNothing);
    await tester.tap(find.byKey(const Key('replay-next')));
    await tester.pumpAndSettle();
    expect(find.text('bob posts the small blind 5'), findsOneWidget);
    final board = tester.widgetList<PlayingCard>(
      find.descendant(of: find.byKey(const Key('replay-board')), matching: find.byType(PlayingCard)),
    );
    expect(board, isEmpty);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-account')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stats-card')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('stat-played'))).data, '12');
    expect(tester.widget<Text>(find.byKey(const Key('stat-won'))).data, '5');
  });

  test('chips groups thousands', () {
    expect(chips(990), '990');
    expect(chips(1450), '1\u202f450');
    expect(chips(-1000000), '-1\u202f000\u202f000');
  });
}
