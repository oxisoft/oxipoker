// Game models: lobby entries, per-viewer table views, hand history.
// The app holds no game logic; these classes only carry what the server sends.

int _int(Object? v) => (v as num?)?.toInt() ?? 0;
List<String> _cards(Object? v) => (v as List?)?.cast<String>() ?? const [];
DateTime? _time(Object? v) => v is String && v.isNotEmpty ? DateTime.tryParse(v)?.toLocal() : null;

const _streets = ['preflop', 'flop', 'turn', 'river', 'showdown'];

/// Streets arrive as names in views and as numbers in stored events.
String _street(Object? v) => v is num ? (v.toInt() < _streets.length ? _streets[v.toInt()] : '') : (v as String? ?? '');

class TableSettings {
  const TableSettings({
    required this.name,
    this.seats = 6,
    this.smallBlind = 5,
    this.bigBlind = 10,
    this.startingStack = 1000,
    this.turnTime = 30,
    this.spectators = true,
  });

  final String name;
  final int seats;
  final int smallBlind;
  final int bigBlind;
  final int startingStack;
  final int turnTime; // seconds
  final bool spectators;

  factory TableSettings.fromJson(Map<String, dynamic> j) => TableSettings(
        name: j['name'] as String? ?? '',
        seats: _int(j['seats']),
        smallBlind: _int(j['small_blind']),
        bigBlind: _int(j['big_blind']),
        startingStack: _int(j['starting_stack']),
        turnTime: _int(j['turn_time']),
        spectators: j['spectators'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'seats': seats,
        'small_blind': smallBlind,
        'big_blind': bigBlind,
        'starting_stack': startingStack,
        'turn_time': turnTime,
        'spectators': spectators,
      };
}

/// One open table in the lobby.
class TableEntry {
  const TableEntry({required this.id, required this.host, required this.settings, this.taken = 0, this.players = const [], this.handNo = 0});

  final String id;
  final String host;
  final TableSettings settings;
  final int taken;
  final List<String> players;
  final int handNo;

  factory TableEntry.fromJson(Map<String, dynamic> j) => TableEntry(
        id: j['id'] as String,
        host: j['host'] as String? ?? '',
        settings: TableSettings.fromJson(j['settings'] as Map<String, dynamic>),
        taken: _int(j['taken']),
        players: (j['players'] as List?)?.cast<String>() ?? const [],
        handNo: _int(j['hand_no']),
      );
}

class SeatView {
  const SeatView({
    required this.user,
    required this.name,
    required this.stack,
    this.sittingOut = false,
    this.inHand = false,
    this.folded = false,
    this.allIn = false,
    this.bet = 0,
    this.hasCards = false,
    this.cards = const [],
  });

  final String user;
  final String name;
  final int stack;
  final bool sittingOut;
  final bool inHand;
  final bool folded;
  final bool allIn;
  final int bet;
  final bool hasCards;
  final List<String> cards;

  factory SeatView.fromJson(Map<String, dynamic> j) => SeatView(
        user: j['user'] as String? ?? '',
        name: j['name'] as String? ?? '',
        stack: _int(j['stack']),
        sittingOut: j['sitting_out'] as bool? ?? false,
        inHand: j['in_hand'] as bool? ?? false,
        folded: j['folded'] as bool? ?? false,
        allIn: j['all_in'] as bool? ?? false,
        bet: _int(j['bet']),
        hasCards: j['has_cards'] as bool? ?? false,
        cards: _cards(j['cards']),
      );
}

/// What the player to act may do; only sent to that player.
class Legal {
  const Legal({required this.seat, this.fold = false, this.check = false, this.call = 0, this.betKind = '', this.minTo = 0, this.maxTo = 0});

  final int seat;
  final bool fold;
  final bool check;
  final int call;
  final String betKind; // 'bet', 'raise' or '' when no bet is possible
  final int minTo;
  final int maxTo;

  bool get canBet => betKind.isNotEmpty && maxTo > 0;

  factory Legal.fromJson(Map<String, dynamic> j) => Legal(
        seat: _int(j['seat']),
        fold: j['fold'] as bool? ?? false,
        check: j['check'] as bool? ?? false,
        call: _int(j['call']),
        betKind: j['bet_kind'] as String? ?? '',
        minTo: _int(j['min_to']),
        maxTo: _int(j['max_to']),
      );
}

class Pot {
  const Pot(this.amount, this.eligible);

  final int amount;
  final List<int> eligible;

  factory Pot.fromJson(Map<String, dynamic> j) =>
      Pot(_int(j['amount']), (j['eligible'] as List?)?.map(_int).toList() ?? const []);
}

class PotResult {
  const PotResult(this.winners, this.shares);

  final List<int> winners;
  final List<int> shares;

  factory PotResult.fromJson(Map<String, dynamic> j) => PotResult(
      (j['winners'] as List?)?.map(_int).toList() ?? const [], (j['shares'] as List?)?.map(_int).toList() ?? const []);
}

class HandEvent {
  const HandEvent({required this.kind, required this.seat, required this.street, this.amount = 0, this.allIn = false, this.cards = const []});

  final String kind; // post_sb, post_bb, hole, fold, check, call, bet, raise, return, board, show, win
  final int seat;
  final String street;
  final int amount;
  final bool allIn;
  final List<String> cards;

  factory HandEvent.fromJson(Map<String, dynamic> j) => HandEvent(
        kind: j['kind'] as String? ?? '',
        seat: _int(j['seat']),
        street: _street(j['street']),
        amount: _int(j['amount']),
        allIn: j['all_in'] as bool? ?? false,
        cards: _cards(j['cards']),
      );
}

class HandView {
  const HandView({
    required this.street,
    this.board = const [],
    this.pots = const [],
    this.button = -1,
    this.sb = -1,
    this.bb = -1,
    this.toAct = -1,
    this.deadline,
    this.currentBet = 0,
    this.legal,
    this.events = const [],
    this.results = const [],
    this.done = false,
  });

  final String street;
  final List<String> board;
  final List<Pot> pots;
  final int button;
  final int sb;
  final int bb;
  final int toAct;
  final DateTime? deadline;
  final int currentBet;
  final Legal? legal;
  final List<HandEvent> events;
  final List<PotResult> results;
  final bool done;

  int get potTotal => pots.fold(0, (s, p) => s + p.amount);

  factory HandView.fromJson(Map<String, dynamic> j) => HandView(
        street: _street(j['street']),
        board: _cards(j['board']),
        pots: (j['pots'] as List?)?.map((e) => Pot.fromJson(e as Map<String, dynamic>)).toList() ?? const [],
        button: _int(j['button']),
        sb: _int(j['sb']),
        bb: _int(j['bb']),
        toAct: j['to_act'] == null ? -1 : _int(j['to_act']),
        deadline: _time(j['deadline']),
        currentBet: _int(j['current_bet']),
        legal: j['legal'] == null ? null : Legal.fromJson(j['legal'] as Map<String, dynamic>),
        events: (j['events'] as List?)?.map((e) => HandEvent.fromJson(e as Map<String, dynamic>)).toList() ?? const [],
        results: (j['results'] as List?)?.map((e) => PotResult.fromJson(e as Map<String, dynamic>)).toList() ?? const [],
        done: j['done'] as bool? ?? false,
      );
}

/// The table as this viewer may see it (built per viewer on the server).
class TableView {
  const TableView({
    required this.id,
    required this.settings,
    required this.host,
    this.version = 0,
    this.yourSeat = -1,
    this.seats = const [],
    this.handNo = 0,
    this.hand,
    this.closed = false,
  });

  final String id;
  final int version;
  final TableSettings settings;
  final String host;
  final int yourSeat; // -1 = spectator
  final List<SeatView?> seats;
  final int handNo;
  final HandView? hand;
  final bool closed;

  bool get seated => yourSeat >= 0;
  SeatView? get me => seated && yourSeat < seats.length ? seats[yourSeat] : null;

  /// The actions open to this viewer right now, or null.
  Legal? get myLegal {
    final l = hand?.legal;
    return l != null && seated && l.seat == yourSeat && !(hand?.done ?? true) ? l : null;
  }

  factory TableView.fromJson(Map<String, dynamic> j) => TableView(
        id: j['id'] as String,
        version: _int(j['version']),
        settings: TableSettings.fromJson(j['settings'] as Map<String, dynamic>),
        host: j['host'] as String? ?? '',
        yourSeat: j['your_seat'] == null ? -1 : _int(j['your_seat']),
        seats: (j['seats'] as List?)?.map((e) => e == null ? null : SeatView.fromJson(e as Map<String, dynamic>)).toList() ??
            const [],
        handNo: _int(j['hand_no']),
        hand: j['hand'] == null ? null : HandView.fromJson(j['hand'] as Map<String, dynamic>),
        closed: j['closed'] as bool? ?? false,
      );
}

class ChatMessage {
  const ChatMessage({required this.user, required this.name, required this.text, this.at});

  final String user;
  final String name;
  final String text;
  final DateTime? at;

  factory ChatMessage.fromJson(Map<String, dynamic> j) =>
      ChatMessage(user: j['user'] as String? ?? '', name: j['name'] as String? ?? '', text: j['text'] as String? ?? '', at: _time(j['at']));
}

/// One of the player's own finished hands.
class HandSummary {
  const HandSummary({
    required this.id,
    required this.tableName,
    required this.handNo,
    this.bigBlind = 0,
    this.pot = 0,
    this.board = const [],
    this.seat = 0,
    this.cards = const [],
    this.won = 0,
    this.net = 0,
    this.endedAt,
  });

  final int id;
  final String tableName;
  final int handNo;
  final int bigBlind;
  final int pot;
  final List<String> board;
  final int seat;
  final List<String> cards;
  final int won;
  final int net;
  final DateTime? endedAt;

  factory HandSummary.fromJson(Map<String, dynamic> j) => HandSummary(
        id: _int(j['id']),
        tableName: j['table_name'] as String? ?? '',
        handNo: _int(j['hand_no']),
        bigBlind: _int(j['big_blind']),
        pot: _int(j['pot']),
        board: _cards(j['board']),
        seat: _int(j['seat']),
        cards: _cards(j['cards']),
        won: _int(j['won']),
        net: _int(j['net']),
        endedAt: _time(j['ended_at']),
      );
}

class ReplaySeat {
  const ReplaySeat({required this.seat, required this.name, this.startStack = 0, this.endStack = 0, this.won = 0});

  final int seat;
  final String name;
  final int startStack;
  final int endStack;
  final int won;

  factory ReplaySeat.fromJson(Map<String, dynamic> j) => ReplaySeat(
        seat: _int(j['seat']),
        name: j['name'] as String? ?? '',
        startStack: _int(j['start_stack']),
        endStack: _int(j['end_stack']),
        won: _int(j['won']),
      );
}

/// A stored hand, replayable event by event.
class HandReplay {
  const HandReplay({
    required this.id,
    required this.tableName,
    required this.handNo,
    this.smallBlind = 0,
    this.bigBlind = 0,
    this.button = 0,
    this.pot = 0,
    this.board = const [],
    this.events = const [],
    this.results = const [],
    this.seats = const [],
    this.yourSeat = -1,
    this.yourCards = const [],
    this.endedAt,
  });

  final int id;
  final String tableName;
  final int handNo;
  final int smallBlind;
  final int bigBlind;
  final int button;
  final int pot;
  final List<String> board;
  final List<HandEvent> events;
  final List<PotResult> results;
  final List<ReplaySeat> seats;
  final int yourSeat;
  final List<String> yourCards;
  final DateTime? endedAt;

  String nameOf(int seat) => seats.where((s) => s.seat == seat).firstOrNull?.name ?? '#${seat + 1}';

  factory HandReplay.fromJson(Map<String, dynamic> j) => HandReplay(
        id: _int(j['id']),
        tableName: j['table_name'] as String? ?? '',
        handNo: _int(j['hand_no']),
        smallBlind: _int(j['small_blind']),
        bigBlind: _int(j['big_blind']),
        button: _int(j['button']),
        pot: _int(j['pot']),
        board: _cards(j['board']),
        events: (j['events'] as List?)?.map((e) => HandEvent.fromJson(e as Map<String, dynamic>)).toList() ?? const [],
        results: (j['results'] as List?)?.map((e) => PotResult.fromJson(e as Map<String, dynamic>)).toList() ?? const [],
        seats: (j['seats'] as List?)?.map((e) => ReplaySeat.fromJson(e as Map<String, dynamic>)).toList() ?? const [],
        yourSeat: j['your_seat'] == null ? -1 : _int(j['your_seat']),
        yourCards: _cards(j['your_cards']),
        endedAt: _time(j['ended_at']),
      );
}

class PlayerStats {
  const PlayerStats({this.handsPlayed = 0, this.handsWon = 0, this.biggestPot = 0});

  final int handsPlayed;
  final int handsWon;
  final int biggestPot;

  factory PlayerStats.fromJson(Map<String, dynamic> j) =>
      PlayerStats(handsPlayed: _int(j['hands_played']), handsWon: _int(j['hands_won']), biggestPot: _int(j['biggest_pot']));
}
