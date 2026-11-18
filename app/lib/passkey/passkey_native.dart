import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'passkey.dart';

/// Native apps. Android runs the ceremonies through Credential Manager (the
/// method channel in MainActivity.kt); the server publishes assetlinks.json so
/// Android offers passkeys for its domain. Other platforms sign in with a
/// password for now.
PasskeyClient platformPasskeys() =>
    defaultTargetPlatform == TargetPlatform.android ? const AndroidPasskeys() : const _Unavailable();

class _Unavailable implements PasskeyClient {
  const _Unavailable();

  @override
  bool get available => false;

  @override
  Future<Object> get(Map<String, dynamic> options) => throw const PasskeyCancelled();

  @override
  Future<Object> create(Map<String, dynamic> options) => throw const PasskeyCancelled();
}

/// Passes the server's WebAuthn JSON to Android unchanged and returns the
/// credential JSON Android produces.
class AndroidPasskeys implements PasskeyClient {
  const AndroidPasskeys();

  static const channel = MethodChannel('io.oxisoft.oxipoker/passkeys');

  @override
  bool get available => true;

  Future<Object> _run(String method, Map<String, dynamic> options) async {
    final pk = options['publicKey'] ?? options;
    try {
      final res = await channel.invokeMethod<String>(method, {'options': jsonEncode(pk)});
      if (res == null) throw const PasskeyCancelled();
      return jsonDecode(res) as Object;
    } on PlatformException {
      // cancelled, no passkey for this server, or the device refused.
      throw const PasskeyCancelled();
    } on MissingPluginException {
      throw const PasskeyCancelled();
    }
  }

  @override
  Future<Object> get(Map<String, dynamic> options) => _run('get', options);

  @override
  Future<Object> create(Map<String, dynamic> options) => _run('create', options);
}
