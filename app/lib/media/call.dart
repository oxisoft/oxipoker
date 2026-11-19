import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart' show Widget;

import '../api/api.dart';
import '../api/models.dart';
import '../state/session.dart';
import 'livekit_room.dart';

/// Someone in a table's call, as the media layer sees them.
class CallPeer {
  const CallPeer({required this.identity, required this.name, this.mic = false, this.camera = false, this.speaking = false});

  /// The Oxi Poker user id (the server puts it in the token).
  final String identity;
  final String name;
  final bool mic;
  final bool camera;
  final bool speaking;
}

/// What the media layer reports to the controller.
enum CallEvent {
  /// Participants, tracks or speaking changed.
  changed,

  /// A host or admin took us out of the call, or the table's call room is gone.
  removed,

  /// The connection broke for another reason.
  lost,
}

/// The media transport of one call. [LiveKitCallRoom] in the app, a fake in
/// the widget tests. Oxi Poker writes no media code of its own: this only
/// starts, stops and reports what LiveKit carries.
abstract class CallRoom {
  Future<void> connect(String url, String token);
  Future<void> disconnect();
  Future<void> setMicrophone(bool on);
  Future<void> setCamera(bool on);
  Future<void> setSpeaker(bool on);
  Future<void> switchCamera();

  bool get micOn;
  bool get cameraOn;

  /// True while our own microphone carries speech.
  bool get speaking;

  /// The camera picture of [identity] (us or someone else), or null while
  /// that camera is off or its video has not arrived yet.
  Widget? video(String identity);

  /// Users we blocked: their tracks are not received and they are left out
  /// of [peers]. Called again whenever the set changes.
  void hide(Set<String> users);

  /// Everyone else in the call.
  List<CallPeer> get peers;
  Stream<CallEvent> get events;
}

typedef CallRoomFactory = CallRoom Function();

final callRoomFactoryProvider = Provider<CallRoomFactory>((ref) => LiveKitCallRoom.new);

/// The server's health answer: tells the app whether voice and video exist.
final serverInfoProvider = FutureProvider<ServerInfo>((ref) {
  ref.watch(sessionProvider.select((s) => s.server));
  return ref.read(sessionProvider.notifier).api().health();
});

/// True when the server has LiveKit configured; false while unknown.
final mediaAvailableProvider = Provider<bool>((ref) => ref.watch(serverInfoProvider).value?.media ?? false);

enum CallStatus { idle, connecting, connected, failed }

/// A device the player turns on or off in a call.
enum CallDevice { microphone, camera }

class CallState {
  const CallState({
    this.table,
    this.status = CallStatus.idle,
    this.mic = false,
    this.camera = false,
    this.speaker = true,
    this.speaking = false,
    this.peers = const [],
    this.error,
    this.removed = false,
    this.refused,
    this.refusals = 0,
  });

  final String? table;
  final CallStatus status;
  final bool mic;
  final bool camera;
  final bool speaker;

  /// We are speaking (the speaking ring on our own seat).
  final bool speaking;
  final List<CallPeer> peers;

  /// Why joining failed: an [ApiException] or any other error.
  final Object? error;

  /// The call ended because a host or admin removed us.
  final bool removed;

  /// The device the system or browser last refused to start (no permission,
  /// no device, or a page served without HTTPS).
  final CallDevice? refused;

  /// Counts refusals, so the same refusal twice still shows its message.
  final int refusals;

  bool get active => status == CallStatus.connecting || status == CallStatus.connected;

  bool get connected => status == CallStatus.connected;

  CallState copyWith({
    CallStatus? status,
    bool? mic,
    bool? camera,
    bool? speaker,
    bool? speaking,
    List<CallPeer>? peers,
    CallDevice? refused,
    int? refusals,
  }) => CallState(
    table: table,
    status: status ?? this.status,
    mic: mic ?? this.mic,
    camera: camera ?? this.camera,
    speaker: speaker ?? this.speaker,
    speaking: speaking ?? this.speaking,
    peers: peers ?? this.peers,
    error: error,
    removed: removed,
    refused: refused ?? this.refused,
    refusals: refusals ?? this.refusals,
  );
}

/// How long before a media token expires the app asks for the next one.
const tokenRefreshMargin = Duration(minutes: 2);

/// One call at a time: the call of the table on screen. Joining never turns
/// the microphone or the camera on; the player does that. A call that fails
/// leaves the table fully playable, the game never waits for media.
class CallController extends Notifier<CallState> {
  CallRoom? _room;
  StreamSubscription<CallEvent>? _sub;
  Timer? _refresh;
  int _gen = 0;
  Set<String> _hidden = {};

  @override
  CallState build() {
    ref.onDispose(() {
      _gen++;
      unawaited(_teardown());
    });
    return const CallState();
  }

  Api _api() => ref.read(sessionProvider.notifier).api();

  Future<void> join(String table) async {
    if (state.table == table && state.active) return;
    await leave();
    final gen = ++_gen;
    state = CallState(table: table, status: CallStatus.connecting, speaker: state.speaker);
    try {
      try {
        _hidden = {for (final b in await _api().blocks()) b.id};
      } catch (_) {
        // The block list is a courtesy here; the server keeps blocked users'
        // chat away anyway. Keep the set we already know.
      }
      if (gen != _gen) return;
      final t = await _api().mediaToken(table);
      if (gen != _gen) return;
      final room = ref.read(callRoomFactoryProvider)();
      _room = room;
      _sub = room.events.listen((e) => _onEvent(gen, e));
      room.hide(_hidden);
      await room.connect(t.url, t.token);
      if (gen != _gen) return;
      _schedule(gen, table, t.expiresAt);
      state = state.copyWith(
        status: CallStatus.connected,
        mic: room.micOn,
        camera: room.cameraOn,
        speaking: room.speaking,
        peers: _peers(room),
      );
    } catch (e) {
      if (gen != _gen || !ref.mounted) return;
      await _teardown();
      if (gen != _gen || !ref.mounted) return;
      state = CallState(table: table, status: CallStatus.failed, error: e, speaker: state.speaker);
    }
  }

  /// Leaves the current call, if any.
  Future<void> leave() async {
    if (!ref.mounted) return;
    _gen++;
    final speaker = state.speaker;
    await _teardown();
    if (ref.mounted) state = CallState(speaker: speaker);
  }

  /// Leaves the call only when it belongs to [table] (the table screen closes).
  Future<void> leaveTable(String table) async {
    if (ref.mounted && state.table == table) await leave();
  }

  Future<void> setMic(bool on) => _toggle(CallDevice.microphone, (r) => r.setMicrophone(on));
  Future<void> setCamera(bool on) => _toggle(CallDevice.camera, (r) => r.setCamera(on));

  Future<void> setSpeaker(bool on) async {
    state = state.copyWith(speaker: on);
    await _room?.setSpeaker(on);
  }

  Future<void> switchCamera() async => _room?.switchCamera();

  /// The camera picture of [identity] in the connected call, else null.
  Widget? video(String identity) =>
      state.connected && !_hidden.contains(identity) ? _room?.video(identity) : null;

  /// A user we just blocked: no sound or picture of them from now on.
  void block(String user) => _setHidden({..._hidden, user});

  /// A user we unblocked: heard and seen again.
  void unblock(String user) => _setHidden({..._hidden}..remove(user));

  void _setHidden(Set<String> users) {
    _hidden = users;
    final r = _room;
    if (r == null) return;
    r.hide(users);
    if (state.connected) state = state.copyWith(peers: _peers(r));
  }

  List<CallPeer> _peers(CallRoom r) => [
    for (final p in r.peers)
      if (!_hidden.contains(p.identity)) p,
  ];

  Future<void> _toggle(CallDevice device, Future<void> Function(CallRoom) f) async {
    final r = _room;
    if (r == null || state.status != CallStatus.connected) return;
    var refused = false;
    try {
      await f(r);
    } catch (_) {
      // Permission refused, no such device, or no HTTPS in the browser. The
      // call and the game go on; the bar tells the player what to change.
      refused = true;
    }
    if (!ref.mounted || !identical(r, _room)) return;
    state = refused
        ? state.copyWith(mic: r.micOn, camera: r.cameraOn, refused: device, refusals: state.refusals + 1)
        : state.copyWith(mic: r.micOn, camera: r.cameraOn);
  }

  void _onEvent(int gen, CallEvent e) {
    final r = _room;
    if (gen != _gen || r == null) return;
    switch (e) {
      case CallEvent.changed:
        state = state.copyWith(mic: r.micOn, camera: r.cameraOn, speaking: r.speaking, peers: _peers(r));
      case CallEvent.removed:
        _end(removed: true);
      case CallEvent.lost:
        _end(error: const ApiException(0, 'call_lost'));
    }
  }

  void _end({bool removed = false, Object? error}) {
    final table = state.table, speaker = state.speaker;
    _gen++;
    unawaited(_teardown());
    state = CallState(
      table: table,
      status: error == null ? CallStatus.idle : CallStatus.failed,
      speaker: speaker,
      removed: removed,
      error: error,
    );
  }

  /// Asks the server for the next token before this one runs out. The server
  /// refuses it for someone who left the table or was removed: then the call
  /// ends here too. LiveKit keeps a connected call alive by itself; the fresh
  /// token is the server's word that we may still be in it.
  void _schedule(int gen, String table, DateTime expiresAt) {
    _refresh?.cancel();
    var wait = expiresAt.difference(DateTime.now()) - tokenRefreshMargin;
    if (wait < const Duration(seconds: 10)) wait = const Duration(seconds: 10);
    _refresh = Timer(wait, () async {
      if (gen != _gen) return;
      try {
        final t = await _api().mediaToken(table);
        if (gen == _gen) _schedule(gen, table, t.expiresAt);
      } on ApiException catch (e) {
        if (gen != _gen) return;
        if (e.status == 403 || e.status == 404) {
          _end(error: e);
        } else {
          _schedule(gen, table, DateTime.now().add(tokenRefreshMargin + const Duration(seconds: 30)));
        }
      } catch (_) {
        if (gen == _gen) _schedule(gen, table, DateTime.now().add(tokenRefreshMargin + const Duration(seconds: 30)));
      }
    });
  }

  Future<void> _teardown() async {
    _refresh?.cancel();
    _refresh = null;
    final sub = _sub, room = _room;
    _sub = null;
    _room = null;
    // Events of an old call are ignored by generation, so the subscription
    // may end after the disconnect.
    unawaited(sub?.cancel());
    try {
      await room?.disconnect();
    } catch (_) {
      // Already gone.
    }
  }
}

final callProvider = NotifierProvider<CallController, CallState>(CallController.new);
