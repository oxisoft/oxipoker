import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'models.dart';

/// An error answer of the server: HTTP status plus the `error` code.
class ApiException implements Exception {
  const ApiException(this.status, this.code, {this.retryAfter});

  final int status;
  final String code;
  final Duration? retryAfter;

  @override
  String toString() => 'ApiException($status, $code)';
}

/// Answer of a sign-in step: either signed in, or a TOTP challenge.
class SignInResult {
  const SignInResult({this.user, this.token, this.totpChallenge});

  final User? user;
  final String? token;
  final String? totpChallenge;

  bool get needsTotp => totpChallenge != null;

  factory SignInResult.fromJson(Map<String, dynamic> j) => SignInResult(
        user: j['user'] == null ? null : User.fromJson(j['user'] as Map<String, dynamic>),
        token: j['token'] as String?,
        totpChallenge: j['totp_required'] == true ? j['challenge'] as String? : null,
      );
}

/// Thin client of the Oxi Poker HTTP API (docs/API.md).
///
/// The web app talks to its own origin and relies on the session cookie;
/// native apps pass [token] as a bearer token and send `client: app` at
/// sign-in so the server answers with a token.
class Api {
  Api({required this.server, this.token, required this.native, http.Client? client})
      : _http = client ?? http.Client();

  final Uri server;
  final String? token;
  final bool native;
  final http.Client _http;

  Uri _u(String path, [Map<String, String>? query]) =>
      server.replace(path: '/api/v1$path', queryParameters: query == null || query.isEmpty ? null : query);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> _send(String method, String path, {Object? body, Map<String, String>? query}) async {
    final req = http.Request(method, _u(path, query))..headers.addAll(_headers);
    if (body != null) req.body = jsonEncode(body);
    final res = await http.Response.fromStream(await _http.send(req));
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    final ok = res.statusCode >= 200 && res.statusCode < 300;
    dynamic data;
    if (res.body.isNotEmpty) {
      try {
        data = jsonDecode(res.body);
      } catch (_) {
        data = null;
      }
    }
    if (ok) return data;
    final code = data is Map && data['error'] is String ? data['error'] as String : 'http_${res.statusCode}';
    final ra = int.tryParse(res.headers['retry-after'] ?? '');
    throw ApiException(res.statusCode, code, retryAfter: ra == null ? null : Duration(seconds: ra));
  }

  Map<String, dynamic> _client(Map<String, dynamic> body) => native ? {...body, 'client': 'app'} : body;

  // Health and sign-in.

  Future<ServerInfo> health() async => ServerInfo.fromJson(await _send('GET', '/health') as Map<String, dynamic>);

  Future<SignInResult> signIn(String username, String password) async => SignInResult.fromJson(
      await _send('POST', '/auth/signin', body: _client({'username': username, 'password': password})));

  Future<SignInResult> totp(String challenge, String code) async =>
      SignInResult.fromJson(await _send('POST', '/auth/totp', body: _client({'challenge': challenge, 'code': code})));

  Future<Map<String, dynamic>> passkeySignInBegin() async =>
      await _send('POST', '/auth/passkey/begin', body: const {}) as Map<String, dynamic>;

  Future<SignInResult> passkeySignInFinish(String ceremony, Object credential) async => SignInResult.fromJson(
      await _send('POST', '/auth/passkey/finish', body: _client({'ceremony': ceremony, 'credential': credential})));

  Future<void> signOut() => _send('POST', '/auth/signout', body: const {});

  // Invitations (no session needed).

  Future<InvitationInfo> checkInvitation(String token) async =>
      InvitationInfo.fromJson(await _send('POST', '/invitations/check', body: {'token': token}));

  Future<SignInResult> signUp(String inviteToken, String username, String displayName, String password) async =>
      SignInResult.fromJson(await _send('POST', '/auth/signup',
          body: _client({
            'token': inviteToken,
            'username': username,
            if (displayName.isNotEmpty) 'display_name': displayName,
            'password': password,
          })));

  Future<Map<String, dynamic>> signUpPasskeyBegin(String inviteToken, String username, String displayName) async =>
      await _send('POST', '/auth/signup/passkey/begin', body: {
        'token': inviteToken,
        'username': username,
        if (displayName.isNotEmpty) 'display_name': displayName,
      }) as Map<String, dynamic>;

  Future<SignInResult> signUpPasskeyFinish(String ceremony, Object credential) async => SignInResult.fromJson(
      await _send('POST', '/auth/signup/passkey/finish', body: _client({'ceremony': ceremony, 'credential': credential})));

  // Own account.

  Future<User> me() async => User.fromJson(await _send('GET', '/me'));

  Future<User> setDisplayName(String name) async =>
      User.fromJson(await _send('PATCH', '/me', body: {'display_name': name}));

  Future<void> changePassword(String? current, String next) => _send('POST', '/me/password',
      body: {if (current != null && current.isNotEmpty) 'current_password': current, 'new_password': next});

  Future<void> deleteAccount(String password) => _send('DELETE', '/me', body: {'password': password});

  Future<List<SessionInfo>> sessions() async => ((await _send('GET', '/me/sessions'))['sessions'] as List)
      .map((e) => SessionInfo.fromJson(e as Map<String, dynamic>))
      .toList();

  Future<void> revokeSession(String id) => _send('DELETE', '/me/sessions/$id');

  Future<int> revokeOtherSessions() async =>
      (await _send('POST', '/me/sessions/revoke-others', body: const {}))['revoked'] as int? ?? 0;

  Future<TotpStatus> totpStatus() async => TotpStatus.fromJson(await _send('GET', '/me/totp'));

  Future<TotpEnrollment> totpBegin() async =>
      TotpEnrollment.fromJson(await _send('POST', '/me/totp/begin', body: const {}));

  Future<List<String>> totpConfirm(String code) async =>
      ((await _send('POST', '/me/totp/confirm', body: {'code': code}))['recovery_codes'] as List).cast<String>();

  Future<void> totpDisable(String code) => _send('POST', '/me/totp/disable', body: {'code': code});

  Future<List<PasskeyInfo>> passkeys() async => ((await _send('GET', '/me/passkeys'))['passkeys'] as List)
      .map((e) => PasskeyInfo.fromJson(e as Map<String, dynamic>))
      .toList();

  Future<Map<String, dynamic>> passkeyAddBegin() async =>
      await _send('POST', '/me/passkeys/begin', body: const {}) as Map<String, dynamic>;

  Future<void> passkeyAddFinish(String ceremony, Object credential, String name) => _send('POST', '/me/passkeys/finish',
      body: {'ceremony': ceremony, 'credential': credential, if (name.isNotEmpty) 'name': name});

  Future<void> renamePasskey(String id, String name) => _send('PATCH', '/me/passkeys/$id', body: {'name': name});

  Future<void> removePasskey(String id) => _send('DELETE', '/me/passkeys/$id');

  Future<User> uploadAvatar(Uint8List bytes) async {
    final req = http.Request('PUT', _u('/me/avatar'))
      ..headers.addAll({..._headers, 'Content-Type': 'application/octet-stream'})
      ..bodyBytes = bytes;
    return User.fromJson(_decode(await http.Response.fromStream(await _http.send(req))));
  }

  Future<void> removeAvatar() => _send('DELETE', '/me/avatar');

  Uri avatarUrl(User u) => _u('/users/${u.id}/avatar', {'v': u.avatar ?? ''});

  // Admin console.

  Future<UserPage> adminUsers({String q = '', int offset = 0}) async => UserPage.fromJson(
      await _send('GET', '/admin/users', query: {if (q.isNotEmpty) 'q': q, if (offset > 0) 'offset': '$offset'}));

  Future<(User, String)> adminCreateUser(String username, String displayName, bool isAdmin) async {
    final j = await _send('POST', '/admin/users',
        body: {'username': username, if (displayName.isNotEmpty) 'display_name': displayName, 'is_admin': isAdmin});
    return (User.fromJson(j['user'] as Map<String, dynamic>), j['temporary_password'] as String);
  }

  Future<User> adminUpdateUser(String id, {bool? disabled, bool? isAdmin}) async => User.fromJson(await _send(
      'PATCH', '/admin/users/$id',
      body: {'disabled': ?disabled, 'is_admin': ?isAdmin}));

  Future<void> adminDeleteUser(String id) => _send('DELETE', '/admin/users/$id');

  Future<String> adminResetPassword(String id) async =>
      (await _send('POST', '/admin/users/$id/reset-password', body: const {}))['temporary_password'] as String;

  Future<void> adminReset2fa(String id) => _send('POST', '/admin/users/$id/reset-2fa', body: const {});

  Future<List<Invitation>> invitations() async => ((await _send('GET', '/admin/invitations'))['invitations'] as List)
      .map((e) => Invitation.fromJson(e as Map<String, dynamic>))
      .toList();

  /// Returns the invitation link; the token inside it is shown only once.
  Future<String> createInvitation({required int hours, required int uses, String note = ''}) async =>
      (await _send('POST', '/admin/invitations',
          body: {'expires_in_hours': hours, 'max_uses': uses, if (note.isNotEmpty) 'note': note}))['url'] as String;

  Future<void> revokeInvitation(String id) => _send('DELETE', '/admin/invitations/$id');

  Future<ServerSettings> settings() async => ServerSettings.fromJson(await _send('GET', '/admin/settings'));

  Future<ServerSettings> updateSettings({String? tableCreation, int? maxUploadBytes}) async =>
      ServerSettings.fromJson(await _send('PATCH', '/admin/settings', body: {
        'table_creation': ?tableCreation,
        'max_upload_bytes': ?maxUploadBytes,
      }));

  Future<List<AuditEvent>> audit({String action = '', int? before}) async =>
      ((await _send('GET', '/admin/audit', query: {
        if (action.isNotEmpty) 'action': action,
        if (before != null) 'before': '$before',
      }))['events'] as List)
          .map((e) => AuditEvent.fromJson(e as Map<String, dynamic>))
          .toList();
}
