import 'passkey.dart';

/// Native apps get passkeys through the platform plugin in a later step; until
/// then they sign in with a password.
PasskeyClient platformPasskeys() => const _Unavailable();

class _Unavailable implements PasskeyClient {
  const _Unavailable();

  @override
  bool get available => false;

  @override
  Future<Object> get(Map<String, dynamic> options) => throw const PasskeyCancelled();

  @override
  Future<Object> create(Map<String, dynamic> options) => throw const PasskeyCancelled();
}
