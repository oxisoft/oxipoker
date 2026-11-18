import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A tiny in-memory stand-in for the Oxi Poker API, enough for widget tests.
class FakeServer {
  final users = <String, Map<String, dynamic>>{
    'u1': {'id': 'u1', 'username': 'alice', 'display_name': 'Alice', 'is_admin': true, 'must_change_password': false},
    'u2': {'id': 'u2', 'username': 'bob', 'display_name': '', 'is_admin': false, 'must_change_password': false},
  };
  final passwords = {'alice': 'correct horse', 'bob': 'battery staple'};
  final totpUsers = <String>{};
  final invites = <String, Map<String, dynamic>>{'tok123': {'uses': 0, 'max': 1, 'note': 'Friday game'}};
  final requests = <String>[];
  String? signedIn;

  http.Response _json(int status, Object? body) =>
      http.Response(body == null ? '' : jsonEncode(body), status, headers: {'content-type': 'application/json'});

  http.Response _err(int status, String code) => _json(status, {'error': code});

  Map<String, dynamic> _signin(String id) {
    signedIn = id;
    return {'user': users[id], 'session': {'id': 's1'}, 'token': 'tok-$id'};
  }

  late final client = MockClient((req) async {
    final path = req.url.path.replaceFirst('/api/v1', '');
    requests.add('${req.method} $path');
    final body = req.body.isEmpty ? <String, dynamic>{} : jsonDecode(req.body) as Map<String, dynamic>;
    final me = signedIn == null ? null : users[signedIn];
    switch ('${req.method} $path') {
      case 'GET /health':
        return _json(200, {'status': 'ok', 'version': 'test', 'media': false});
      case 'POST /auth/signin':
        final u = users.values.where((u) => u['username'] == body['username']).firstOrNull;
        if (u == null || passwords[u['username']] != body['password']) return _err(401, 'invalid_credentials');
        if (totpUsers.contains(u['username'])) return _json(200, {'totp_required': true, 'challenge': 'ch-${u['id']}'});
        return _json(200, _signin(u['id'] as String));
      case 'POST /auth/totp':
        if (body['code'] != '123456') return _err(401, 'invalid_code');
        return _json(200, _signin((body['challenge'] as String).substring(3)));
      case 'POST /auth/signout':
        signedIn = null;
        return _json(204, null);
      case 'POST /invitations/check':
        final i = invites[body['token']];
        if (i == null) return _err(404, 'invitation_invalid');
        if (i['uses'] >= i['max']) return _err(410, 'invitation_used');
        return _json(200, {'expires_at': '2030-01-01T00:00:00Z', 'note': i['note'], 'passkeys': true});
      case 'POST /auth/signup':
        final i = invites[body['token']];
        if (i == null) return _err(404, 'invitation_invalid');
        if (i['uses'] >= i['max']) return _err(410, 'invitation_used');
        if (users.values.any((u) => u['username'] == body['username'])) return _err(409, 'username_taken');
        i['uses'] = i['uses'] + 1;
        final id = 'u${users.length + 1}';
        users[id] = {
          'id': id,
          'username': body['username'],
          'display_name': body['display_name'] ?? '',
          'is_admin': false,
          'must_change_password': false,
        };
        passwords[body['username'] as String] = body['password'] as String;
        return _json(200, _signin(id));
      case 'POST /auth/passkey/begin':
        return _json(200, {'ceremony': 'c1', 'options': {'publicKey': {'challenge': 'abc'}}});
      case 'POST /auth/passkey/finish':
        if (body['ceremony'] != 'c1' || (body['credential'] as Map)['id'] != 'cred-alice') {
          return _err(401, 'invalid_credentials');
        }
        return _json(200, _signin('u1'));
      case 'GET /me/totp':
        return _json(200, {'enabled': false, 'recovery_codes_left': 0});
      case 'GET /me/sessions':
        return _json(200, {
          'sessions': [
            {'id': 's1', 'kind': 'web', 'ip': '10.0.0.1', 'user_agent': 'Test browser', 'current': true, 'last_seen_at': '2026-11-18T10:00:00Z'},
          ]
        });
      case 'GET /me/passkeys':
        return _json(200, {
          'passkeys': [
            {'id': 'p1', 'name': 'Laptop', 'created_at': '2026-11-18T10:00:00Z', 'synced': true},
          ]
        });
      case 'GET /me':
        return me == null ? _err(401, 'unauthorized') : _json(200, me);
      case 'POST /me/password':
        if (me == null) return _err(401, 'unauthorized');
        me['must_change_password'] = false;
        passwords[me['username'] as String] = body['new_password'] as String;
        return _json(204, null);
      case 'GET /admin/users':
        if (me?['is_admin'] != true) return _err(403, 'admin_only');
        return _json(200, {'users': users.values.toList(), 'total': users.length});
      case 'POST /admin/users':
        final id = 'u${users.length + 1}';
        users[id] = {'id': id, 'username': body['username'], 'display_name': '', 'is_admin': false, 'must_change_password': true};
        return _json(201, {'user': users[id], 'temporary_password': 'temp-pass-0001'});
      case 'GET /admin/invitations':
        return _json(200, {'invitations': []});
      case 'POST /admin/invitations':
        return _json(201, {
          'invitation': {'id': 'i9'},
          'token': 'newtok',
          'url': 'https://poker.example.com/invite#newtok',
        });
    }
    return _err(404, 'not_found');
  });
}
