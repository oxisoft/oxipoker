import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oxipoker/api/models.dart';
import 'package:oxipoker/main.dart';
import 'package:oxipoker/passkey/passkey.dart';
import 'package:oxipoker/router.dart';
import 'package:oxipoker/state/session.dart';
import 'package:oxipoker/ui/appearance.dart';

import 'fake_server.dart';

Future<(FakeServer, MemorySessionStore)> pumpApp(
  WidgetTester tester, {
  bool native = false,
  Uri? server,
  String? invite,
  FakeServer? fake,
  PasskeyClient? passkeys,
}) async {
  final f = fake ?? FakeServer();
  final store = MemorySessionStore(server: native ? server : (server ?? Uri.parse('https://poker.example.com')));
  await tester.binding.setSurfaceSize(const Size(1000, 1400));
  await tester.pumpWidget(ProviderScope(
    overrides: [
      nativeProvider.overrideWithValue(native),
      sessionStoreProvider.overrideWithValue(store),
      httpClientProvider.overrideWithValue(f.client),
      initialInviteProvider.overrideWithValue(invite),
      if (passkeys != null) passkeyProvider.overrideWithValue(passkeys),
    ],
    child: const OxiPokerApp(),
  ));
  await tester.pumpAndSettle();
  return (f, store);
}

Future<void> signIn(WidgetTester tester, String user, String pass) async {
  await tester.enterText(find.byKey(const Key('username-field')), user);
  await tester.enterText(find.byKey(const Key('password-field')), pass);
  await tester.tap(find.byKey(const Key('sign-in')));
  await tester.pumpAndSettle();
}

class FakePasskeys implements PasskeyClient {
  FakePasskeys({this.cancel = false, this.available = true});

  final bool cancel;

  @override
  final bool available;

  @override
  Future<Object> get(Map<String, dynamic> options) async {
    if (cancel) throw const PasskeyCancelled();
    expect((options['publicKey'] as Map)['challenge'], 'abc');
    return {'id': 'cred-alice', 'type': 'public-key'};
  }

  @override
  Future<Object> create(Map<String, dynamic> options) async => {'id': 'new', 'type': 'public-key'};
}

void main() {
  group('helpers', () {
    test('invitation links split into server and token', () {
      final r = parseInviteLink('https://poker.example.com/invite#abc');
      expect(r!.$1.toString(), 'https://poker.example.com');
      expect(r.$2, 'abc');
      expect(parseInviteLink('https://poker.example.com/'), isNull);
      expect(parseInviteLink('https://poker.example.com/invite'), isNull);
    });

    test('server addresses get https and lose paths', () {
      expect(parseServerAddress('poker.example.com/x?y')!.toString(), 'https://poker.example.com');
      expect(parseServerAddress('http://10.0.0.2:8080')!.toString(), 'http://10.0.0.2:8080');
      expect(parseServerAddress('ftp://x'), isNull);
      expect(parseServerAddress('  '), isNull);
    });

    test('redirects follow the session', () {
      const u = User(id: '1', username: 'a', displayName: '');
      const admin = User(id: '1', username: 'a', displayName: '', isAdmin: true);
      const temp = User(id: '1', username: 'a', displayName: '', mustChangePassword: true);
      final s = Uri.parse('https://x');
      expect(redirectFor(const SessionState(), '/', native: true), '/splash');
      expect(redirectFor(const SessionState(loading: false), '/', native: true), '/server');
      expect(redirectFor(SessionState(loading: false, server: s), '/', native: true), '/signin');
      expect(redirectFor(SessionState(loading: false, server: s, inviteToken: 't'), '/signin', native: false), '/invite');
      expect(redirectFor(SessionState(loading: false, server: s, user: u), '/signin', native: false), '/');
      expect(redirectFor(SessionState(loading: false, server: s, user: u), '/admin', native: false), '/');
      expect(redirectFor(SessionState(loading: false, server: s, user: admin), '/admin', native: false), isNull);
      expect(redirectFor(SessionState(loading: false, server: s, user: temp), '/', native: false), '/password');
      // Deep links survive the splash and sign-in screens.
      expect(redirectFor(const SessionState(), '/table/T1', native: false), '/splash?from=%2Ftable%2FT1');
      expect(redirectFor(SessionState(loading: false, server: s), '/splash', native: false, from: '/table/T1'),
          '/signin?from=%2Ftable%2FT1');
      expect(redirectFor(SessionState(loading: false, server: s, user: u), '/signin', native: false, from: '/table/T1'),
          '/table/T1');
      expect(redirectFor(SessionState(loading: false, server: s, user: u), '/splash', native: false, from: '//evil.example'),
          '/');
      expect(redirectFor(SessionState(loading: false, server: s, user: u), '/signin', native: false, from: '/signin'), '/');
    });
  });

  group('sign-in', () {
    testWidgets('password sign-in opens the lobby', (tester) async {
      await pumpApp(tester);
      expect(find.text('Sign in'), findsWidgets);
      await signIn(tester, 'alice', 'correct horse');
      expect(find.text('Welcome, Alice'), findsOneWidget);
      expect(find.byKey(const Key('open-admin')), findsOneWidget);
    });

    testWidgets('a wrong password shows one message for both cases', (tester) async {
      await pumpApp(tester);
      await signIn(tester, 'alice', 'nope');
      expect(find.text('Wrong username or password.'), findsOneWidget);
      await signIn(tester, 'nobody', 'nope');
      expect(find.text('Wrong username or password.'), findsOneWidget);
    });

    testWidgets('two-factor accounts get a code step', (tester) async {
      final fake = FakeServer()..totpUsers.add('bob');
      await pumpApp(tester, fake: fake);
      await signIn(tester, 'bob', 'battery staple');
      expect(find.text('Two-factor code'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('totp-field')), '000000');
      await tester.tap(find.byKey(const Key('verify')));
      await tester.pumpAndSettle();
      expect(find.text('That code is not valid.'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('totp-field')), '123456');
      await tester.tap(find.byKey(const Key('verify')));
      await tester.pumpAndSettle();
      expect(find.text('Welcome, bob'), findsOneWidget);
      expect(find.byKey(const Key('open-admin')), findsNothing);
    });

    testWidgets('passkey sign-in', (tester) async {
      await pumpApp(tester, passkeys: FakePasskeys());
      await tester.tap(find.byKey(const Key('sign-in-passkey')));
      await tester.pumpAndSettle();
      expect(find.text('Welcome, Alice'), findsOneWidget);
    });

    testWidgets('a cancelled passkey prompt stays quiet', (tester) async {
      await pumpApp(tester, passkeys: FakePasskeys(cancel: true));
      await tester.tap(find.byKey(const Key('sign-in-passkey')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('form-error')), findsNothing);
      expect(find.text('Sign in with a passkey'), findsOneWidget);
    });

    testWidgets('no passkey button where the device has none', (tester) async {
      await pumpApp(tester, passkeys: FakePasskeys(available: false));
      expect(find.byKey(const Key('sign-in-passkey')), findsNothing);
    });

    testWidgets('theme and card back are picked on the account screen', (tester) async {
      final (fake, _) = await pumpApp(tester, passkeys: FakePasskeys());
      await signIn(tester, 'alice', 'correct horse');
      await tester.tap(find.byKey(const Key('open-account')));
      await tester.pumpAndSettle();
      // Server default (classic-blue here) until the user picks one.
      expect(Theme.of(tester.element(find.byKey(const Key('theme-picker')))).extension<TablePalette>(), TablePalette.classic);
      expect(find.byKey(const Key('back-classic-blue')), findsNWidgets(2));
      await tester.tap(find.text('Cyberpunk'));
      await tester.pumpAndSettle();
      expect(fake.users['u1']!['theme'], 'cyberpunk');
      expect(Theme.of(tester.element(find.byKey(const Key('theme-picker')))).extension<TablePalette>(), TablePalette.cyberpunk);
      await tester.ensureVisible(find.byKey(const Key('pick-back-cyber-grid')));
      await tester.tap(find.byKey(const Key('pick-back-cyber-grid')));
      await tester.pumpAndSettle();
      expect(fake.users['u1']!['card_back'], 'cyber-grid');
      final container = ProviderScope.containerOf(tester.element(find.byKey(const Key('theme-picker'))));
      expect(container.read(cardBackProvider), 'cyber-grid');
      await tester.tap(find.byKey(const Key('pick-back-default')));
      await tester.pumpAndSettle();
      expect(container.read(cardBackProvider), 'classic-blue');
    });

    testWidgets('account screen lists passkeys and sessions', (tester) async {
      await pumpApp(tester, passkeys: FakePasskeys());
      await signIn(tester, 'alice', 'correct horse');
      await tester.tap(find.byKey(const Key('open-account')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('totp-enable')), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Test browser'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('Laptop'), findsOneWidget);
      expect(find.text('Test browser'), findsOneWidget);
      expect(find.byKey(const Key('add-passkey')), findsOneWidget);
      await tester.tap(find.byKey(const Key('sign-out')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sign-in')), findsOneWidget);
    });

    testWidgets('native app keeps the token after sign-in', (tester) async {
      final (_, store) = await pumpApp(tester, native: true, server: Uri.parse('https://poker.example.com'));
      await signIn(tester, 'alice', 'correct horse');
      expect(store.token, 'tok-u1');
    });
  });

  group('invitations', () {
    testWidgets('native app: pasting an invitation link leads to sign-up', (tester) async {
      final (fake, store) = await pumpApp(tester, native: true);
      expect(find.text('Connect to a server'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('server-field')), 'https://poker.example.com/invite#tok123');
      await tester.tap(find.byKey(const Key('connect')));
      await tester.pumpAndSettle();
      expect(store.server.toString(), 'https://poker.example.com');
      expect(find.text('Note from your host: Friday game'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('username-field')), 'carol');
      await tester.enterText(find.byKey(const Key('password-field')), 'long enough pw');
      await tester.enterText(find.byKey(const Key('password2-field')), 'long enough pw');
      await tester.tap(find.byKey(const Key('sign-up')));
      await tester.pumpAndSettle();
      expect(find.text('Welcome, carol'), findsOneWidget);
      expect(fake.invites['tok123']!['uses'], 1);
    });

    testWidgets('web: a used link refuses', (tester) async {
      final fake = FakeServer();
      fake.invites['tok123']!['uses'] = 1;
      await pumpApp(tester, invite: 'tok123', fake: fake);
      expect(find.text('This invitation link has already been used.'), findsOneWidget);
    });

    testWidgets('different passwords are caught before the server', (tester) async {
      final (fake, _) = await pumpApp(tester, invite: 'tok123');
      await tester.enterText(find.byKey(const Key('username-field')), 'carol');
      await tester.enterText(find.byKey(const Key('password-field')), 'long enough pw');
      await tester.enterText(find.byKey(const Key('password2-field')), 'other pw 1234');
      await tester.tap(find.byKey(const Key('sign-up')));
      await tester.pumpAndSettle();
      expect(find.text('The passwords do not match.'), findsOneWidget);
      expect(fake.requests, isNot(contains('POST /auth/signup')));
    });
  });

  group('admin console', () {
    testWidgets('settings pick the default card back and delete uploads', (tester) async {
      final (fake, _) = await pumpApp(tester);
      await signIn(tester, 'alice', 'correct horse');
      await tester.tap(find.byKey(const Key('open-admin')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tab-settings')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('default-back')), findsOneWidget);
      await tester.scrollUntilVisible(find.byKey(const Key('upload-back')), 200, scrollable: find.byType(Scrollable).last);
      expect(find.byKey(const Key('delete-back-classic-red')), findsNothing); // built-ins stay
      await tester.tap(find.byKey(const Key('delete-back-u-mine')));
      await tester.pumpAndSettle();
      expect(fake.deletedBacks, ['u-mine']);
    });
    testWidgets('lists users and shows a temporary password once', (tester) async {
      await pumpApp(tester);
      await signIn(tester, 'alice', 'correct horse');
      await tester.tap(find.byKey(const Key('open-admin')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('user-bob')), findsOneWidget);
      await tester.tap(find.byKey(const Key('new-user')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('new-username')), 'dave');
      await tester.tap(find.byKey(const Key('create-user')));
      await tester.pumpAndSettle();
      expect(find.text('temp-pass-0001'), findsOneWidget);
    });

    testWidgets('creates an invitation link', (tester) async {
      await pumpApp(tester);
      await signIn(tester, 'alice', 'correct horse');
      await tester.tap(find.byKey(const Key('open-admin')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tab-invitations')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('new-invitation')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('create-invitation')));
      await tester.pumpAndSettle();
      expect(find.text('https://poker.example.com/invite#newtok'), findsOneWidget);
    });
  });
}
