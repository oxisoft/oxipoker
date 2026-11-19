import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:livekit_client/livekit_client.dart' as lk;

import 'call.dart';

/// [CallRoom] on top of livekit_client. Connecting publishes nothing: the
/// microphone and the camera stay off until the player turns them on.
class LiveKitCallRoom implements CallRoom {
  final _room = lk.Room(roomOptions: const lk.RoomOptions(adaptiveStream: true, dynacast: true));
  final _events = StreamController<CallEvent>.broadcast();
  lk.EventsListener<lk.RoomEvent>? _listener;
  var _position = lk.CameraPosition.front;
  var _leaving = false;

  /// The LiveKit room, for the video tiles.
  lk.Room get room => _room;

  @override
  Stream<CallEvent> get events => _events.stream;

  @override
  Future<void> connect(String url, String token) async {
    _listener = _room.createListener()
      ..listen((e) {
        if (e is lk.RoomDisconnectedEvent) {
          if (_leaving) return;
          final r = e.reason;
          _events.add(
            r == lk.DisconnectReason.participantRemoved || r == lk.DisconnectReason.roomDeleted
                ? CallEvent.removed
                : CallEvent.lost,
          );
        } else {
          _events.add(CallEvent.changed);
        }
      });
    await _room.connect(url, token);
    // Browsers start audio only after a user gesture; joining is one.
    if (kIsWeb) await _room.startAudio();
  }

  @override
  Future<void> disconnect() async {
    _leaving = true;
    await _listener?.dispose();
    _listener = null;
    await _room.disconnect();
    await _room.dispose();
    await _events.close();
  }

  @override
  bool get micOn => _room.localParticipant?.isMicrophoneEnabled() ?? false;

  @override
  bool get cameraOn => _room.localParticipant?.isCameraEnabled() ?? false;

  @override
  Future<void> setMicrophone(bool on) async => _room.localParticipant?.setMicrophoneEnabled(on);

  @override
  Future<void> setCamera(bool on) async => _room.localParticipant?.setCameraEnabled(
    on,
    cameraCaptureOptions: lk.CameraCaptureOptions(cameraPosition: _position),
  );

  @override
  Future<void> setSpeaker(bool on) async {
    if (kIsWeb) return;
    if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      await lk.AudioManager.instance.setSpeakerOutputPreferred(on);
    }
  }

  @override
  Future<void> switchCamera() async {
    _position = _position == lk.CameraPosition.front ? lk.CameraPosition.back : lk.CameraPosition.front;
    final track = _room.localParticipant?.videoTrackPublications.firstOrNull?.track;
    if (track is lk.LocalVideoTrack) await track.setCameraPosition(_position);
  }

  @override
  List<CallPeer> get peers => [
    for (final p in _room.remoteParticipants.values)
      CallPeer(
        identity: p.identity,
        name: p.name,
        mic: p.isMicrophoneEnabled(),
        camera: p.isCameraEnabled(),
        speaking: p.isSpeaking,
      ),
  ];
}
