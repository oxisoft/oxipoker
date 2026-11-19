import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_background/flutter_background.dart';

/// Keeps a call alive on Android while the app is in the background: a
/// foreground service of type microphone with a notification, started once
/// the player turns the microphone on (Android starts that service type only
/// from the foreground and only with the microphone permission granted) and
/// stopped when the call ends. Other platforms need nothing.
class CallBackground {
  CallBackground._();

  /// Notification texts in the player's language, set by the call bar.
  static String title = 'Oxi Poker';
  static String text = '';

  static bool get _android => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> start() async {
    if (!_android || FlutterBackground.isBackgroundExecutionEnabled) return;
    try {
      final ok = await FlutterBackground.initialize(
        androidConfig: FlutterBackgroundAndroidConfig(
          notificationTitle: title,
          notificationText: text,
          notificationImportance: AndroidNotificationImportance.normal,
          enableWifiLock: true,
        ),
      );
      if (ok) await FlutterBackground.enableBackgroundExecution();
    } catch (_) {
      // Without the service the call still works while the app is open.
    }
  }

  static Future<void> stop() async {
    if (!_android || !FlutterBackground.isBackgroundExecutionEnabled) return;
    try {
      await FlutterBackground.disableBackgroundExecution();
    } catch (_) {}
  }
}
