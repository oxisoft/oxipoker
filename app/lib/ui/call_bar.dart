import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../api/api.dart';
import '../api/poker.dart';
import '../l10n/app_localizations.dart';
import '../media/call.dart';
import '../state/realtime.dart';
import '../state/session.dart';
import 'common.dart';
import 'moderation.dart' show showCallUserMenu;
import 'table_screen.dart' show UserAvatar;

/// Phones get the speaker and camera switch buttons; desktop and web do not.
bool get _mobile =>
    !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

String callErrorText(AppLocalizations l, Object e) =>
    e is ApiException && e.code == 'call_lost' ? l.callLost : errorText(l, e);

/// The strip with the player's own call controls. Hidden when the server has
/// no voice and video. Everyone controls only their own microphone and camera.
class CallBar extends ConsumerWidget {
  const CallBar({super.key, required this.tableId});

  final String tableId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(mediaAvailableProvider)) return const SizedBox.shrink();
    final l = context.l;
    final c = ref.watch(callProvider);
    final call = ref.read(callProvider.notifier);
    ref.listen(callProvider, (prev, next) {
      if (next.table != tableId) return;
      if (next.status == CallStatus.failed && prev?.status != CallStatus.failed && next.error != null) {
        toast(context, callErrorText(l, next.error!));
      } else if (next.removed && !(prev?.removed ?? false)) {
        toast(context, l.callRemoved);
      }
    });
    final mine = c.table == tableId;
    const icon = Colors.white;
    Widget button(String key, IconData i, String tip, VoidCallback onTap, {bool on = false}) => IconButton(
      key: Key(key),
      tooltip: tip,
      isSelected: on,
      color: icon,
      style: IconButton.styleFrom(backgroundColor: on ? Colors.white24 : null),
      icon: Icon(i),
      onPressed: onTap,
    );
    return Container(
      key: const Key('call-bar'),
      width: double.infinity,
      color: Colors.black26,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          if (!mine || !c.active)
            TextButton.icon(
              key: const Key('call-join'),
              style: TextButton.styleFrom(foregroundColor: icon),
              icon: const Icon(Icons.call),
              label: Text(l.callJoin),
              onPressed: () => call.join(tableId),
            )
          else if (c.status == CallStatus.connecting) ...[
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            Text(l.callConnecting, style: const TextStyle(color: Colors.white70)),
            button('call-leave', Icons.call_end, l.callLeave, call.leave),
          ] else ...[
            button(
              'call-mic',
              c.mic ? Icons.mic : Icons.mic_off,
              c.mic ? l.callMicOff : l.callMicOn,
              () => call.setMic(!c.mic),
              on: c.mic,
            ),
            button(
              'call-camera',
              c.camera ? Icons.videocam : Icons.videocam_off,
              c.camera ? l.callCameraOff : l.callCameraOn,
              () => call.setCamera(!c.camera),
              on: c.camera,
            ),
            if (_mobile) ...[
              button('call-speaker', c.speaker ? Icons.volume_up : Icons.hearing, l.callSpeaker,
                  () => call.setSpeaker(!c.speaker), on: c.speaker),
              if (c.camera) button('call-switch', Icons.cameraswitch, l.callSwitchCamera, call.switchCamera),
            ],
            Text(l.callInCall(c.peers.length + 1), key: const Key('call-count'), style: const TextStyle(color: Colors.white70)),
            button('call-leave', Icons.call_end, l.callLeave, call.leave),
          ],
        ],
      ),
    );
  }
}

/// How [user] is in our connected call, or null when they are not in it.
({bool mic, bool camera, bool speaking})? callPresence(CallState c, String me, String user) {
  if (!c.connected) return null;
  if (user == me) return (mic: c.mic, camera: c.camera, speaking: c.speaking);
  for (final p in c.peers) {
    if (p.identity == user) return (mic: p.mic, camera: p.camera, speaking: p.speaking);
  }
  return null;
}

const _speakingColor = Color(0xFF3DDC84);

/// A user's picture in the call: the camera tile while that camera is on,
/// else [child] (the avatar); a ring while they speak, a crossed microphone
/// while muted. Outside a call it is just [child].
class SeatMedia extends ConsumerWidget {
  const SeatMedia({super.key, required this.user, required this.name, required this.child, this.size = 36});

  final String user;
  final String name;
  final Widget child;

  /// Height of the camera tile; it is a third wider than high.
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(callProvider);
    final me = ref.watch(sessionProvider.select((s) => s.user?.id ?? ''));
    final p = callPresence(c, me, user);
    if (p == null) return child;
    final video = p.camera ? ref.read(callProvider.notifier).video(user) : null;
    final tile = Stack(
      key: Key('call-tile-$user'),
      clipBehavior: Clip.none,
      children: [
        if (video != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(key: Key('call-video-$user'), width: size * 4 / 3, height: size, child: video),
          )
        else
          child,
        if (p.speaking)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                key: Key('call-speaking-$user'),
                decoration: BoxDecoration(
                  border: Border.all(color: _speakingColor, width: 2),
                  borderRadius: BorderRadius.circular(video != null ? 6 : size),
                ),
              ),
            ),
          ),
        if (!p.mic)
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              key: Key('call-muted-$user'),
              padding: const EdgeInsets.all(1),
              decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
              child: const Icon(Icons.mic_off, size: 11, color: Colors.white70),
            ),
          ),
      ],
    );
    final view = ref.watch(realtimeProvider.select((s) => s.view));
    final admin = ref.watch(sessionProvider.select((s) => s.user?.isAdmin ?? false));
    if (user == me || view == null || !(view.host == me || admin)) return tile;
    return GestureDetector(
      key: Key('call-menu-$user'),
      behavior: HitTestBehavior.opaque,
      onTap: () => showCallUserMenu(context, ref, user: user, name: name),
      child: tile,
    );
  }
}

/// Spectators in the call (and we ourselves while watching) in a strip under
/// the call bar; players appear at their seats.
class SpectatorStrip extends ConsumerWidget {
  const SpectatorStrip({super.key, required this.view});

  final TableView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(callProvider);
    if (!c.connected || c.table != view.id) return const SizedBox.shrink();
    final me = ref.watch(sessionProvider.select((s) => s.user));
    final seated = {for (final s in view.seats) ?s?.user};
    final watchers = [
      if (me != null && !seated.contains(me.id)) (id: me.id, name: me.shownName),
      for (final p in c.peers)
        if (!seated.contains(p.identity)) (id: p.identity, name: p.name),
    ];
    if (watchers.isEmpty) return const SizedBox.shrink();
    return Container(
      key: const Key('spectator-strip'),
      width: double.infinity,
      height: 64,
      color: Colors.black12,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final w in watchers)
            Padding(
              key: Key('spectator-${w.id}'),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SeatMedia(user: w.id, name: w.name, child: UserAvatar(user: w.id, name: w.name)),
                  const SizedBox(height: 2),
                  SizedBox(
                    width: 56,
                    child: Text(
                      w.name,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
