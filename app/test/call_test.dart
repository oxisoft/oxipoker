import 'dart:async';

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
  Future<void> setMicrophone(bool on) async => mic = on;
  @override
  Future<void> setCamera(bool on) async => camera = on;
  @override
  Future<void> setSpeaker(bool on) async => speaker = on;
  @override
  Future<void> switchCamera() async => log.add('switch');
  @override
  bool get micOn => mic;
  @override
  bool get cameraOn => camera;
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
    expect(find.byIcon(Icons.mic_off), findsOneWidget);
    expect(find.byIcon(Icons.videocam_off), findsOneWidget);
    expect(find.text('In the call: 1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('call-mic')));
    await tester.pumpAndSettle();
    expect(room.mic, isTrue);
    expect(find.byIcon(Icons.mic), findsOneWidget);
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

  testWidgets('a host taking us out of the call says so', (tester) async {
    final (_, _, rooms) = await _pump(tester);
    await tester.tap(find.byKey(const Key('call-join')));
    await tester.pumpAndSettle();
    rooms.single.emit(CallEvent.removed);
    await tester.pumpAndSettle();
    expect(find.text('You were taken out of the call.'), findsOneWidget);
    expect(find.byKey(const Key('call-join')), findsOneWidget);
  });
}
