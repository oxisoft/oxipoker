import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'state/session.dart';
import 'ui/account_screens.dart';
import 'ui/admin_screens.dart';
import 'ui/auth_screens.dart';
import 'ui/history_screens.dart';
import 'ui/lobby_screen.dart';
import 'ui/table_screen.dart';

/// Where the session state sends the player, or null to stay on [location].
@visibleForTesting
String? redirectFor(SessionState s, String location, {required bool native}) {
  if (s.loading) return location == '/splash' ? null : '/splash';
  if (s.server == null) return native ? (location == '/server' ? null : '/server') : '/splash';
  final user = s.user;
  if (user == null) {
    if (s.inviteToken != null) return location == '/invite' ? null : '/invite';
    return location == '/signin' ? null : '/signin';
  }
  if (user.mustChangePassword) return location == '/password' ? null : '/password';
  const public = {'/splash', '/server', '/signin', '/invite', '/password'};
  if (public.contains(location)) return '/';
  if (location.startsWith('/admin') && !user.isAdmin) return '/';
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);
  final native = ref.read(nativeProvider);
  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) => redirectFor(ref.read(sessionProvider), state.matchedLocation, native: native),
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/server', builder: (_, _) => const ServerScreen()),
      GoRoute(path: '/signin', builder: (_, _) => const SignInScreen()),
      GoRoute(path: '/invite', builder: (_, _) => const InviteScreen()),
      GoRoute(path: '/password', builder: (_, _) => const MustChangePasswordScreen()),
      GoRoute(path: '/', builder: (_, _) => const LobbyScreen()),
      GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
      GoRoute(path: '/admin', builder: (_, _) => const AdminScreen()),
      GoRoute(path: '/table/:id', builder: (_, st) => TableScreen(tableId: st.pathParameters['id']!)),
      GoRoute(path: '/hands', builder: (_, _) => const HandsScreen()),
      GoRoute(
          path: '/hands/:id', builder: (_, st) => ReplayScreen(handId: int.tryParse(st.pathParameters['id']!) ?? 0)),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
