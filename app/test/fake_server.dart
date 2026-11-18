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
  final tables = <Map<String, dynamic>>[];
  final hands = <Map<String, dynamic>>[
    {
      'id': 1, 'table_name': 'Friday', 'hand_no': 3, 'big_blind': 10, 'pot': 60, 'board': ['Ah', 'Kd', '7c'],
      'seat': 0, 'cards': ['As', 'Ks'], 'won': 60, 'net': 30, 'ended_at': '2026-11-18T14:00:00Z',
    },
  ];
  final replay = <String, dynamic>{
    'id': 1, 'table_name': 'Friday', 'hand_no': 3, 'small_blind': 5, 'big_blind': 10, 'button': 1, 'pot': 60,
    'board': ['Ah', 'Kd', '7c'],
    'events': [
      {'kind': 'post_sb', 'seat': 1, 'street': 0, 'amount': 5},
      {'kind': 'post_bb', 'seat': 0, 'street': 0, 'amount': 10},
      {'kind': 'hole', 'seat': 0, 'street': 0, 'cards': ['As', 'Ks']},
      {'kind': 'call', 'seat': 1, 'street': 0, 'amount': 10},
      {'kind': 'check', 'seat': 0, 'street': 0},
      {'kind': 'board', 'seat': -1, 'street': 1, 'cards': ['Ah', 'Kd', '7c']},
      {'kind': 'bet', 'seat': 0, 'street': 1, 'amount': 20},
      {'kind': 'fold', 'seat': 1, 'street': 1},
      {'kind': 'win', 'seat': 0, 'street': 1, 'amount': 40},
    ],
    'results': [
      {'winners': [0], 'shares': [40]},
    ],
    'seats': [
      {'seat': 0, 'name': 'Alice', 'start_stack': 1000, 'end_stack': 1030, 'won': 40},
      {'seat': 1, 'name': 'bob', 'start_stack': 1000, 'end_stack': 970, 'won': 0},
    ],
    'your_seat': 0, 'your_cards': ['As', 'Ks'], 'ended_at': '2026-11-18T14:00:00Z',
  };
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
      case 'GET /tables':
        return _json(200, {'tables': tables});
      case 'POST /tables':
        if (me == null) return _err(401, 'unauthorized');
        final t = {'id': 't${tables.length + 9}', 'host': me['id'], 'settings': body, 'taken': 0, 'players': [], 'hand_no': 0};
        tables.add(t);
        return _json(201, t);
      case 'GET /me/hands':
        return _json(200, {'hands': hands});
      case 'GET /me/hands/1':
        return _json(200, replay);
      case 'GET /me/stats':
        return _json(200, {'hands_played': 12, 'hands_won': 5, 'biggest_pot': 1450});
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
