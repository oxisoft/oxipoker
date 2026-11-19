import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oxipoker/media/call.dart';

import 'fake_server.dart';
import 'game_test.dart' show FakeHub, openTable, playerView, pumpGame, settings;

/// A call room that records what the app asked of it.
class FakeCallRoom implements CallRoom {
  final log = <String>[];
  final _events = StreamController<CallEvent>.broadcast();
  bool mic = false, camera = false, speaker = true;
  bool failConnect = false;
  bool refuseMic = false, refuseCamera = false;
  var others = <CallPeer>[];

  void emit(CallEvent e) => _events.add(e);

  @override
  Stream<CallEvent> get events => _events.stream;
  @override
  Future<void> connect(String url, String token) async {
    log.add('connect $url $token');
    if (failConnect) throw StateError('no route');
  }

  @override
  Future<void> disconnect() async => log.add('disconnect');
  @override
  Future<void> setMicrophone(bool on) async {
    if (on && refuseMic) throw StateError('NotAllowedError');
    mic = on;
  }

  @override
  Future<void> setCamera(bool on) async {
    if (on && refuseCamera) throw StateError('NotAllowedError');
    camera = on;
  }
  @override
  Future<void> setSpeaker(bool on) async => speaker = on;
  @override
  Future<void> switchCamera() async => log.add('switch');
  @override
  bool get micOn => mic;
  @override
  bool get cameraOn => camera;
  @override
  bool speaking = false;
  @override
  Widget? video(String identity) {
    final on = identity == 'u1' ? camera : others.any((p) => p.identity == identity && p.camera);
    return on ? ColoredBox(key: Key('fake-video-$identity'), color: Colors.blue) : null;
  }

  final hidden = <String>{};
  @override
  void hide(Set<String> users) => hidden
    ..clear()
    ..addAll(users);

  @override
  List<CallPeer> get peers => others;
}

FakeHub _hub() => FakeHub()
  ..lobby = [
    {'id': 't1', 'host': 'u1', 'settings': settings, 'taken': 2, 'players': ['alice', 'bob'], 'hand_no': 4},
  ]
  ..views = {'t1': playerView()};

Future<(FakeServer, FakeHub, List<FakeCallRoom>)> _pump(WidgetTester tester, {bool media = true}) async {
  final rooms = <FakeCallRoom>[];
  final hub = _hub();
  final (f, _) = await pumpGame(
    tester,
    hub: hub,
    server: FakeServer()..media = media,
    overrides: [
      callRoomFactoryProvider.overrideWithValue(() {
        final r = FakeCallRoom();
        rooms.add(r);
        return r;
      }),
    ],
  );
  await openTable(tester, hub);
  return (f, hub, rooms);
}

void main() {
  testWidgets('no call controls when the server has no voice and video', (tester) async {
    final (f, _, rooms) = await _pump(tester, media: false);
    expect(find.byKey(const Key('action-bar')), findsOneWidget);
    expect(find.byKey(const Key('call-bar')), findsNothing);
    expect(find.byKey(const Key('call-join')), findsNothing);
    expect(rooms, isEmpty);
    expect(f.requests.where((r) => r.contains('media-token')), isEmpty);
  });

  testWidgets('joining keeps microphone and camera off; own controls work; leaving disconnects', (tester) async {
    final (f, _, rooms) = await _pump(tester);
    expect(find.byKey(const Key('call-mic')), findsNothing);
    await tester.tap(find.byKey(const Key('call-join')));
    await tester.pumpAndSettle();
    final room = rooms.single;
    expect(room.log, ['connect wss://media.example.com lk-u1']);
    expect(room.mic, isFalse);
    expect(room.camera, isFalse);
    expect(find.descendant(of: find.byKey(const Key('call-bar')), matching: find.byIcon(Icons.mic_off)), findsOneWidget);
    expect(find.byIcon(Icons.videocam_off), findsOneWidget);
    expect(find.text('In the call: 1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('call-mic')));
    await tester.pumpAndSettle();
    expect(room.mic, isTrue);
    expect(find.descendant(of: find.byKey(const Key('call-bar')), matching: find.byIcon(Icons.mic)), findsOneWidget);
    expect(find.byKey(const Key('call-switch')), findsNothing);
    await tester.tap(find.byKey(const Key('call-camera')));
    await tester.pumpAndSettle();
    expect(room.camera, isTrue);
    await tester.tap(find.byKey(const Key('call-switch')));
    await tester.tap(find.byKey(const Key('call-speaker')));
    await tester.pumpAndSettle();
    expect(room.log, contains('switch'));
    expect(room.speaker, isFalse);

    room.others = [const CallPeer(identity: 'u2', name: 'bob', mic: true)];
    room.emit(CallEvent.changed);
    await tester.pumpAndSettle();
    expect(find.text('In the call: 2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('call-leave')));
    await tester.pumpAndSettle();
    expect(room.log.last, 'disconnect');
    expect(find.byKey(const Key('call-join')), findsOneWidget);
    // The game was playable all along.
    expect(find.byKey(const Key('action-bar')), findsOneWidget);
  });

  testWidgets('a refused token or a failed connection leaves the table playable', (tester) async {
    final (f, _, rooms) = await _pump(tester);
    f.mediaRefused.add('u1');
    await tester.tap(find.byKey(const Key('call-join')));
    await tester.pumpAndSettle();
    expect(rooms, isEmpty);
    expect(find.text('Join the table first to use voice and video.'), findsOneWidget);
    expect(find.byKey(const Key('call-join')), findsOneWidget);
    expect(find.byKey(const Key('action-bar')), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    f.mediaRefused.clear();
    await tester.tap(find.byKey(const Key('call-join')));
    await tester.pumpAndSettle();
    rooms.single.emit(CallEvent.lost);
    await tester.pumpAndSettle();
    expect(find.textContaining('The call dropped'), findsOneWidget);
    expect(rooms.single.log.last, 'disconnect');
    expect(find.byKey(const Key('action-bar')), findsOneWidget);
  });

  testWidgets('the token is renewed before it runs out and the call ends when the server refuses', (tester) async {
    final (f, _, rooms) = await _pump(tester);
    await tester.tap(find.byKey(const Key('call-join')));
    await tester.pumpAndSettle();
    int tokens() => f.requests.where((r) => r == 'POST /tables/t1/media-token').length;
    expect(tokens(), 1);
    await tester.pump(const Duration(minutes: 8, seconds: 1));
    await tester.pumpAndSettle();
    expect(tokens(), 2);
    expect(rooms.single.log, isNot(contains('disconnect')));

    // Removed from the call: the next renewal is refused and the call ends.
    f.mediaRefused.add('u1');
    await tester.pump(const Duration(minutes: 8, seconds: 1));
    await tester.pumpAndSettle();
    expect(tokens(), 3);
    expect(rooms.single.log.last, 'disconnect');
    expect(find.byKey(const Key('call-join')), findsOneWidget);
  });

  testWidgets('a refused microphone or camera says what to allow; the call goes on', (tester) async {
    final (_, _, rooms) = await _pump(tester);
    await tester.tap(find.byKey(const Key('call-join')));
    await tester.pumpAndSettle();
    final room = rooms.single
      ..refuseMic = true
      ..refuseCamera = true;
    await tester.tap(find.byKey(const Key('call-mic')));
    await tester.pumpAndSettle();
    expect(find.textContaining('may not use your microphone'), findsOneWidget);
    expect(room.mic, isFalse);
    expect(find.descendant(of: find.byKey(const Key('call-bar')), matching: find.byIcon(Icons.mic_off)), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // The same refusal again still shows its message.
    await tester.tap(find.byKey(const Key('call-mic')));
    await tester.pumpAndSettle();
    expect(find.textContaining('may not use your microphone'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('call-camera')));
    await tester.pumpAndSettle();
    expect(find.textContaining('may not use your camera'), findsOneWidget);
    expect(room.camera, isFalse);
    expect(room.log, isNot(contains('disconnect')));
    expect(find.byKey(const Key('call-leave')), findsOneWidget);
    expect(find.byKey(const Key('action-bar')), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    room.refuseMic = false;
    await tester.tap(find.byKey(const Key('call-mic')));
    await tester.pumpAndSettle();
    expect(room.mic, isTrue);
    expect(find.textContaining('may not use'), findsNothing);
  });

  testWidgets('a host taking us out of the call says so', (tester) async {
    final (_, _, rooms) = await _pump(tester);
    await tester.tap(find.byKey(const Key('call-join')));
    await tester.pumpAndSettle();
    rooms.single.emit(CallEvent.removed);
    await tester.pumpAndSettle();
    expect(find.text('You were taken out of the call.'), findsOneWidget);
    expect(find.byKey(const Key('call-join')), findsOneWidget);
  });

  testWidgets('seats show camera tiles, a speaking ring and muted microphones; spectators get a strip', (tester) async {
    final (_, _, rooms) = await _pump(tester);
    // Outside a call: plain avatars, no strip.
    expect(find.byKey(const Key('call-tile-u1')), findsNothing);
    expect(find.byKey(const Key('spectator-strip')), findsNothing);
    await tester.tap(find.byKey(const Key('call-join')));
    await tester.pumpAndSettle();
    final room = rooms.single;
    // In the call alone: my seat has a tile with a crossed microphone, no video.
    expect(find.byKey(const Key('call-tile-u1')), findsOneWidget);
    expect(find.byKey(const Key('call-muted-u1')), findsOneWidget);
    expect(find.byKey(const Key('call-video-u1')), findsNothing);
    expect(find.byKey(const Key('call-tile-u2')), findsNothing);

    await tester.tap(find.byKey(const Key('call-camera')));
    await tester.tap(find.byKey(const Key('call-mic')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fake-video-u1')), findsOneWidget);
    expect(find.byKey(const Key('call-muted-u1')), findsNothing);

    // bob (seat) speaks with his camera on; dave watches with only his microphone.
    room.others = [
      const CallPeer(identity: 'u2', name: 'bob', mic: true, camera: true, speaking: true),
      const CallPeer(identity: 'u9', name: 'dave'),
    ];
    room.speaking = true;
    room.emit(CallEvent.changed);
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byKey(const Key('seat-1')), matching: find.byKey(const Key('fake-video-u2'))), findsOneWidget);
    expect(find.byKey(const Key('call-speaking-u2')), findsOneWidget);
    expect(find.byKey(const Key('call-speaking-u1')), findsOneWidget);
    expect(find.byKey(const Key('call-tile-u3')), findsNothing);
    final strip = find.byKey(const Key('spectator-strip'));
    expect(find.descendant(of: strip, matching: find.byKey(const Key('spectator-u9'))), findsOneWidget);
    expect(find.descendant(of: strip, matching: find.text('dave')), findsOneWidget);
    expect(find.descendant(of: strip, matching: find.byKey(const Key('call-muted-u9'))), findsOneWidget);
    expect(find.descendant(of: strip, matching: find.byKey(const Key('spectator-u2'))), findsNothing);

    // bob's camera goes off: his avatar is back.
    room.others = [const CallPeer(identity: 'u2', name: 'bob', mic: true)];
    room.speaking = false;
    room.emit(CallEvent.changed);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fake-video-u2')), findsNothing);
    expect(find.byKey(const Key('call-tile-u2')), findsOneWidget);
    expect(find.byKey(const Key('call-speaking-u1')), findsNothing);
    expect(find.byKey(const Key('spectator-strip')), findsNothing);

    await tester.tap(find.byKey(const Key('call-leave')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('call-tile-u1')), findsNothing);
    expect(find.byKey(const Key('call-tile-u2')), findsNothing);
  });

  testWidgets('the host mutes and removes people in the call; blocked users are hidden and silenced', (tester) async {
    final (f, hub, rooms) = await _pump(tester);
    f.blocked.add('u3');
    await tester.tap(find.byKey(const Key('call-join')));
    await tester.pumpAndSettle();
    final room = rooms.single;
    // The block list is applied before connecting.
    expect(room.hidden, {'u3'});
    room.others = [
      const CallPeer(identity: 'u2', name: 'bob', mic: true, camera: true),
      const CallPeer(identity: 'u3', name: 'carol', mic: true, camera: true),
    ];
    room.emit(CallEvent.changed);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fake-video-u2')), findsOneWidget);
    expect(find.byKey(const Key('fake-video-u3')), findsNothing);
    expect(find.byKey(const Key('call-tile-u3')), findsNothing);
    expect(find.text('In the call: 2'), findsOneWidget);

    // No menu on our own tile.
    expect(find.byKey(const Key('call-menu-u1')), findsNothing);
    await tester.tap(find.byKey(const Key('call-menu-u2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('call-mute-mic')));
    await tester.pumpAndSettle();
    expect(hub.ofType('call_mute').last, containsPair('source', 'microphone'));
    expect(hub.ofType('call_mute').last['user'], 'u2');
    await tester.tap(find.byKey(const Key('call-menu-u2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('call-mute-camera')));
    await tester.pumpAndSettle();
    expect(hub.ofType('call_mute').last, containsPair('source', 'camera'));
    await tester.tap(find.byKey(const Key('call-menu-u2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('call-remove')));
    await tester.pumpAndSettle();
    expect(hub.ofType('call_remove').single['user'], 'u2');

    // Blocking bob from the chat silences him in the call at once.
    final ctrl = ProviderScope.containerOf(tester.element(find.byKey(const Key('call-bar')))).read(callProvider.notifier);
    ctrl.block('u2');
    await tester.pumpAndSettle();
    expect(room.hidden, {'u2', 'u3'});
    expect(find.byKey(const Key('call-tile-u2')), findsNothing);
    expect(find.text('In the call: 1'), findsOneWidget);
    ctrl.unblock('u3');
    await tester.pumpAndSettle();
    expect(room.hidden, {'u2'});
    expect(find.byKey(const Key('fake-video-u3')), findsOneWidget);
  });
}
