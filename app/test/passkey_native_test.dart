import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oxipoker/passkey/passkey.dart';
import 'package:oxipoker/passkey/passkey_native.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(AndroidPasskeys.channel, null));

  test('Android passkeys pass the publicKey JSON through and decode the credential', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(AndroidPasskeys.channel, (call) async {
      calls.add(call);
      return '{"id":"abc","type":"public-key","response":{}}';
    });
    const pk = AndroidPasskeys();
    final cred = await pk.get({
      'publicKey': {'challenge': 'xyz', 'rpId': 'poker.example'},
    });
    expect((cred as Map)['id'], 'abc');
    expect(calls.single.method, 'get');
    expect((calls.single.arguments as Map)['options'], '{"challenge":"xyz","rpId":"poker.example"}');

    await pk.create({'challenge': 'c'});
    expect(calls.last.method, 'create');
    expect((calls.last.arguments as Map)['options'], '{"challenge":"c"}');
  });

  test('a cancelled or refused prompt becomes PasskeyCancelled', () async {
    messenger.setMockMethodCallHandler(AndroidPasskeys.channel, (call) async {
      throw PlatformException(code: 'cancelled');
    });
    expect(() => const AndroidPasskeys().get({'challenge': 'x'}), throwsA(isA<PasskeyCancelled>()));
  });
}
