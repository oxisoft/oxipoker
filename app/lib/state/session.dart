import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api.dart';
import '../api/models.dart';

/// Where a native app keeps its server address and session token. The token
/// goes to the platform keystore; the web app keeps neither (same origin,
/// HttpOnly cookie).
abstract class SessionStore {
  Future<Uri?> loadServer();
  Future<void> saveServer(Uri? server);
  Future<String?> loadToken();
  Future<void> saveToken(String? token);
}

class DeviceSessionStore implements SessionStore {
  static const _serverKey = 'server';
  static const _tokenKey = 'session_token';
  final _secure = const FlutterSecureStorage();

  @override
  Future<Uri?> loadServer() async {
    final s = (await SharedPreferences.getInstance()).getString(_serverKey);
    return s == null ? null : Uri.tryParse(s);
  }

  @override
  Future<void> saveServer(Uri? server) async {
    final p = await SharedPreferences.getInstance();
    server == null ? await p.remove(_serverKey) : await p.setString(_serverKey, server.toString());
  }

  @override
  Future<String?> loadToken() => _secure.read(key: _tokenKey);

  @override
  Future<void> saveToken(String? token) =>
      token == null ? _secure.delete(key: _tokenKey) : _secure.write(key: _tokenKey, value: token);
}

/// Keeps everything in memory: the web app and tests.
class MemorySessionStore implements SessionStore {
  MemorySessionStore({this.server, this.token});

  Uri? server;
  String? token;

  @override
  Future<Uri?> loadServer() async => server;
  @override
  Future<void> saveServer(Uri? s) async => server = s;
  @override
  Future<String?> loadToken() async => token;
  @override
  Future<void> saveToken(String? t) async => token = t;
}

/// True for the Android and desktop apps, false for the web app.
final nativeProvider = Provider<bool>((ref) => !kIsWeb);

final sessionStoreProvider = Provider<SessionStore>(
    (ref) => ref.watch(nativeProvider) ? DeviceSessionStore() : MemorySessionStore(server: Uri.parse(Uri.base.origin)));

final httpClientProvider = Provider<http.Client>((ref) {
  final c = http.Client();
  ref.onDispose(c.close);
  return c;
});

/// The invitation token the app was opened with (web: `/invite#token`).
final initialInviteProvider = Provider<String?>((ref) => null);

class SessionState {
  const SessionState({this.loading = true, this.server, this.token, this.user, this.inviteToken});

  final bool loading;
  final Uri? server;
  final String? token;
  final User? user;
  final String? inviteToken;

  bool get signedIn => user != null;

  SessionState copyWith({
    bool? loading,
    Uri? server,
    String? token,
    User? user,
    String? inviteToken,
    bool clearServer = false,
    bool clearToken = false,
    bool clearUser = false,
    bool clearInvite = false,
  }) =>
      SessionState(
        loading: loading ?? this.loading,
        server: clearServer ? null : server ?? this.server,
        token: clearToken ? null : token ?? this.token,
        user: clearUser ? null : user ?? this.user,
        inviteToken: clearInvite ? null : inviteToken ?? this.inviteToken,
      );
}

class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() {
    Future.microtask(_restore);
    return SessionState(inviteToken: ref.read(initialInviteProvider));
  }

  SessionStore get _store => ref.read(sessionStoreProvider);

  /// An API client for [server] (or the current one) with the current token.
  Api api([Uri? server]) => Api(
        server: server ?? state.server!,
        token: state.token,
        native: ref.read(nativeProvider),
        client: ref.read(httpClientProvider),
      );

  Future<void> _restore() async {
    final server = await _store.loadServer();
    final token = await _store.loadToken();
    var next = state.copyWith(loading: false, server: server, token: token);
    if (server != null && (token != null || !ref.read(nativeProvider))) {
      try {
        final me = await Api(server: server, token: token, native: ref.read(nativeProvider), client: ref.read(httpClientProvider)).me();
        next = next.copyWith(user: me);
      } on ApiException catch (e) {
        if (e.status == 401) {
          await _store.saveToken(null);
          next = next.copyWith(clearToken: true);
        }
      } catch (_) {
        // Server unreachable: stay signed out, the sign-in screen tells why.
      }
    }
    state = next;
  }

  /// Checks that [server] answers as an Oxi Poker server, then keeps it.
  Future<ServerInfo> connect(Uri server, {String? inviteToken}) async {
    final info = await Api(server: server, native: true, client: ref.read(httpClientProvider)).health();
    await _store.saveServer(server);
    if (state.server != server) await _store.saveToken(null);
    state = SessionState(loading: false, server: server, inviteToken: inviteToken ?? state.inviteToken);
    return info;
  }

  Future<void> forgetServer() async {
    await _store.saveServer(null);
    await _store.saveToken(null);
    state = const SessionState(loading: false);
  }

  void setInvite(String? token) =>
      state = token == null ? state.copyWith(clearInvite: true) : state.copyWith(inviteToken: token);

  /// Stores the outcome of a finished sign-in or sign-up.
  Future<void> signedIn(SignInResult r) async {
    if (r.token != null) await _store.saveToken(r.token);
    state = state.copyWith(token: r.token, user: r.user, clearInvite: true);
  }

  void updateUser(User u) => state = state.copyWith(user: u);

  Future<void> refreshUser() async => updateUser(await api().me());

  Future<void> signOut() async {
    try {
      await api().signOut();
    } catch (_) {
      // Signed out locally anyway.
    }
    await _store.saveToken(null);
    state = state.copyWith(clearToken: true, clearUser: true);
  }

  /// The server ended the session (401): forget it locally.
  Future<void> expired() async {
    await _store.saveToken(null);
    state = state.copyWith(clearToken: true, clearUser: true);
  }
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(SessionController.new);
