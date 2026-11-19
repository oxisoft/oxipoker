import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../api/api.dart';
import '../l10n/app_localizations.dart';
import '../media/call.dart';
import 'common.dart';

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
