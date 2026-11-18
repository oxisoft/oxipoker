import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'passkey_stub.dart' if (dart.library.js_interop) 'passkey_web.dart' as impl;

/// Thrown when the player cancels the passkey prompt or the device refuses.
class PasskeyCancelled implements Exception {
  const PasskeyCancelled();
}

/// Runs the WebAuthn ceremonies on this device. The server sends the options
/// as JSON (`{publicKey: ...}`, base64url fields) and takes the credential
/// back as JSON in the same encoding.
abstract class PasskeyClient {
  bool get available;

  /// `navigator.credentials.get` for sign-in; returns the credential JSON.
  Future<Object> get(Map<String, dynamic> options);

  /// `navigator.credentials.create` for registration; returns the credential JSON.
  Future<Object> create(Map<String, dynamic> options);
}

final passkeyProvider = Provider<PasskeyClient>((ref) => impl.platformPasskeys());
