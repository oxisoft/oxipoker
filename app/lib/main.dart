import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:material_ui/material_ui.dart';

import 'l10n/app_localizations.dart';
import 'router.dart';
import 'state/locale.dart';
import 'state/session.dart';
import 'ui/appearance.dart';

void main() {
  usePathUrlStrategy();
  // The web app may be opened from an invitation link `<server>/invite#<token>`:
  // the token sits in the fragment so it never reaches a server log.
  final base = Uri.base;
  final invite = base.path == '/invite' && base.fragment.isNotEmpty ? base.fragment : null;
  runApp(ProviderScope(
    overrides: [initialInviteProvider.overrideWithValue(invite)],
    child: const OxiPokerApp(),
  ));
}

/// The app's strings plus the Material, Cupertino and widget texts of
/// material_ui for every language of the app.
final appLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];

class OxiPokerApp extends ConsumerWidget {
  const OxiPokerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: themeFor(ref.watch(sessionProvider.select((s) => s.user?.theme))),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: ref.watch(localeProvider),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
