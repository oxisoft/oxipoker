import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/poker.dart';
import '../realtime/socket.dart';
import 'session.dart';

enum Link { offline, connecting, online }

/// The one realtime connection of this app: lobby, watched table, chat.
class RealtimeState {
  const RealtimeState({this.link = Link.offline, this.tables, this.watching, this.view, this.chat = const [], this.muted = const {}, this.lastError});

  final Link link;
  final List<TableEntry>? tables; // null until the first lobby message
  final String? watching;
  final TableView? view; // view of [watching], null until it arrives
  final List<ChatMessage> chat; // of the watched table, kept in memory only
  final Set<String> muted; // users the host muted at the watched table
  final String? lastError;

  RealtimeState copyWith({
    Link? link,
    List<TableEntry>? tables,
    String? watching,
    TableView? view,
    List<ChatMessage>? chat,
    Set<String>? muted,
    String? lastError,
    bool clearWatch = false,
    bool clearError = false,
  }) => RealtimeState(
    link: link ?? this.link,
    tables: tables ?? this.tables,
    watching: clearWatch ? null : watching ?? this.watching,
    view: clearWatch ? null : view ?? this.view,
    chat: clearWatch ? const [] : chat ?? this.chat,
    muted: clearWatch ? const {} : muted ?? this.muted,
    lastError: clearError ? null : lastError ?? this.lastError,
  );
}

/// How sockets are opened; tests put an in-memory server here.
final socketFactoryProvider = Provider<SocketFactory>((ref) => openSocket);

/// Delay before the n-th reconnect attempt: 0.5 s doubling up to 15 s, with jitter.
Duration reconnectDelay(int attempt, [Random? rnd]) {
  final base = min(15000, 500 * pow(2, min(attempt, 5)).toInt());
  return Duration(milliseconds: base ~/ 2 + (rnd ?? Random()).nextInt(base ~/ 2 + 1));
}

class RealtimeController extends Notifier<RealtimeState> {
  PokerSocket? _socket;
  StreamSubscription<String>? _sub;
  Timer? _retry;
  int _attempt = 0;
  int _nextId = 1;
  bool _wantLobby = false;
  bool _wanted = false;
  final _pending = <int, Completer<String?>>{};
  AppLifecycleListener? _lifecycle;
  bool _disposed = false;

  static const maxChat = 200;

  @override
  RealtimeState build() {
    ref.listen(sessionProvider, (prev, next) {
      if (!next.signedIn) stop();
    });
    ref.onDispose(() {
      _disposed = true;
      _lifecycle?.dispose();
      _teardown();
    });
    return const RealtimeState();
  }

  /// Opens the connection if it is not open; safe to call often.
  void ensure() {
    if (_disposed) return;
    _wanted = true;
    _lifecycle ??= AppLifecycleListener(
      onResume: () {
        // A phone or a browser tab that slept: reconnect at once, not after the backoff.
        if (_wanted && state.link == Link.offline) {
          _attempt = 0;
          _connect();
        }
      },
    );
    if (_socket == null && _retry == null) _connect();
  }

  void stop() {
    if (_disposed) return;
    _wanted = false;
    _wantLobby = false;
    _teardown();
    state = const RealtimeState();
  }

  void _teardown() {
    _retry?.cancel();
    _retry = null;
    _sub?.cancel();
    _sub = null;
    _socket?.close();
    _socket = null;
    for (final c in _pending.values) {
      if (!c.isCompleted) c.complete('offline');
    }
    _pending.clear();
  }

  Future<void> _connect() async {
    _retry?.cancel();
    _retry = null;
    if (_disposed) return;
    final s = ref.read(sessionProvider);
    if (!s.signedIn || s.server == null) return;
    final api = ref.read(sessionProvider.notifier).api();
    state = state.copyWith(link: Link.connecting);
    final sock = ref.read(socketFactoryProvider)(api.wsUri, ref.read(nativeProvider) ? s.token : null);
    _socket = sock;
    _sub = sock.messages.listen(_onMessage, onDone: () => _lost(sock), onError: (_) => _lost(sock), cancelOnError: true);
    try {
      await sock.ready;
    } catch (_) {
      _lost(sock);
      return;
    }
    if (_disposed || !identical(_socket, sock)) return;
    _attempt = 0;
    state = state.copyWith(link: Link.online, clearError: true);
    // Resume where we were: the server sends the lobby and the view at once.
    if (_wantLobby) _raw({'type': 'lobby', 'on': true});
    if (state.watching != null) _raw({'type': 'watch', 'table': state.watching});
  }

  void _lost(PokerSocket sock) {
    if (_disposed || !identical(_socket, sock)) return;
    _sub?.cancel();
    _sub = null;
    _socket = null;
    for (final c in _pending.values) {
      if (!c.isCompleted) c.complete('offline');
    }
    _pending.clear();
    state = state.copyWith(link: Link.offline);
    if (!_wanted || !ref.read(sessionProvider).signedIn) return;
    _retry = Timer(reconnectDelay(_attempt++), _connect);
  }

  void _onMessage(String text) {
    if (_disposed) return;
    final Map<String, dynamic> m;
    try {
      m = jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    switch (m['type']) {
      case 'lobby':
        state = state.copyWith(
          tables: (m['tables'] as List? ?? const []).map((e) => TableEntry.fromJson(e as Map<String, dynamic>)).toList(),
        );
      case 'view':
        final v = TableView.fromJson(m['view'] as Map<String, dynamic>);
        if (v.id == state.watching) state = state.copyWith(view: v);
      case 'chat':
        if (m['table'] == state.watching) {
          final c = [...state.chat, ChatMessage.fromJson(m)];
          state = state.copyWith(chat: c.length > maxChat ? c.sublist(c.length - maxChat) : c);
        }
      case 'moderation':
        if (m['table'] == state.watching) {
          state = state.copyWith(muted: {...(m['muted'] as List? ?? const []).cast<String>()});
        }
      case 'removed':
        if (m['table'] == state.watching) state = state.copyWith(clearWatch: true, lastError: 'removed');
      case 'restarting':
        // The server stores its tables and restarts: reconnect quickly, the
        // table is watched again on its own once the server is back.
        _attempt = 0;
        state = state.copyWith(lastError: 'server_restarting');
      case 'ok':
        _pending.remove(m['id'])?.complete(null);
      case 'error':
        final code = m['error'] as String? ?? 'error';
        final c = _pending.remove(m['id']);
        if (c != null) {
          c.complete(code);
        } else {
          state = state.copyWith(lastError: code);
        }
    }
  }

  void _raw(Map<String, dynamic> msg) => _socket?.send(jsonEncode(msg));

  /// Sends an intent and waits for the answer: null = accepted, else the error code.
  Future<String?> send(Map<String, dynamic> msg) {
    if (_disposed || _socket == null || state.link != Link.online) return Future.value('offline');
    final id = _nextId++;
    final c = Completer<String?>();
    _pending[id] = c;
    _raw({...msg, 'id': id});
    return c.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _pending.remove(id);
        return 'timeout';
      },
    );
  }

  void lobby(bool on) {
    if (_disposed) return;
    _wantLobby = on;
    if (on) ensure();
    if (state.link == Link.online) _raw({'type': 'lobby', 'on': on});
  }

  void watch(String table) {
    if (_disposed) return;
    ensure();
    if (state.watching != table) state = state.copyWith(clearWatch: true).copyWith(watching: table);
    if (state.link == Link.online) _raw({'type': 'watch', 'table': table});
  }

  void unwatch(String table) {
    if (_disposed || state.watching != table) return;
    state = state.copyWith(clearWatch: true);
    if (state.link == Link.online) _raw({'type': 'unwatch'});
  }

  void clearError() => state = state.copyWith(clearError: true);

  Future<String?> sit(int seat) => send({'type': 'sit', 'seat': seat});
  Future<String?> sitOut() => send({'type': 'sitout'});
  Future<String?> comeBack() => send({'type': 'comeback'});
  Future<String?> leave() => send({'type': 'leave'});
  Future<String?> startSng() => send({'type': 'start'});
  Future<String?> act(String action, [int? to]) => send({'type': 'act', 'action': action, 'to': ?to});
  Future<String?> chat(String text) => send({'type': 'chat', 'text': text});
  Future<String?> mute(String user, bool on) => send({'type': on ? 'mute' : 'unmute', 'user': user});
  Future<String?> removeSpectator(String user) => send({'type': 'remove', 'user': user});

  /// Host or admin: switch off someone's `microphone` or `camera` in the call.
  Future<String?> callMute(String user, String source) => send({'type': 'call_mute', 'user': user, 'source': source});

  /// Host or admin: send someone out of the call until the table closes.
  Future<String?> callRemove(String user) => send({'type': 'call_remove', 'user': user});

  /// Drops a blocked user's lines already shown; the server sends no new ones.
  void hideChatOf(String user) => state = state.copyWith(chat: state.chat.where((c) => c.user != user).toList());
}

final realtimeProvider = NotifierProvider<RealtimeController, RealtimeState>(RealtimeController.new);
