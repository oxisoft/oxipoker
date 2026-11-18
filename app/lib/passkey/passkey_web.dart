import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'passkey.dart';

/// Browser WebAuthn through the JSON helpers of PublicKeyCredential
/// (parseRequestOptionsFromJSON, parseCreationOptionsFromJSON, toJSON), so no
/// base64url juggling happens in Dart.
PasskeyClient platformPasskeys() => const _WebPasskeys();

@JS('JSON.parse')
external JSAny? _jsonParse(String s);

@JS('JSON.stringify')
external String _jsonStringify(JSAny? o);

class _WebPasskeys implements PasskeyClient {
  const _WebPasskeys();

  JSObject? get _pkc => globalContext.getProperty<JSObject?>('PublicKeyCredential'.toJS);

  @override
  bool get available {
    final pkc = _pkc;
    return pkc != null &&
        pkc.has('parseRequestOptionsFromJSON') &&
        pkc.has('parseCreationOptionsFromJSON') &&
        globalContext.has('isSecureContext') &&
        globalContext.getProperty<JSBoolean>('isSecureContext'.toJS).toDart;
  }

  Future<Object> _run(String parser, String method, Map<String, dynamic> options) async {
    final pk = options['publicKey'] ?? options;
    final parsed = _pkc!.callMethod<JSObject>(parser.toJS, _jsonParse(jsonEncode(pk)));
    final arg = JSObject()..setProperty('publicKey'.toJS, parsed);
    final container = globalContext.getProperty<JSObject>('navigator'.toJS).getProperty<JSObject>('credentials'.toJS);
    try {
      final cred = await container.callMethod<JSPromise<JSObject?>>(method.toJS, arg).toDart;
      if (cred == null) throw const PasskeyCancelled();
      return jsonDecode(_jsonStringify(cred.callMethod<JSAny?>('toJSON'.toJS))) as Object;
    } on PasskeyCancelled {
      rethrow;
    } catch (_) {
      // NotAllowedError (cancelled, timed out) and friends.
      throw const PasskeyCancelled();
    }
  }

  @override
  Future<Object> get(Map<String, dynamic> options) => _run('parseRequestOptionsFromJSON', 'get', options);

  @override
  Future<Object> create(Map<String, dynamic> options) => _run('parseCreationOptionsFromJSON', 'create', options);
}
