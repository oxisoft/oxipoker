import 'package:flutter_localizations/flutter_localizations.dart' show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:material_ui/material_ui.dart';

import 'l10n/app_localizations.dart';
import 'router.dart';
import 'state/session.dart';
import 'ui/common.dart';

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

ThemeData oxiTheme() => ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: felt, brightness: Brightness.dark),
      useMaterial3: true,
      fontFamily: appFont,
      fontFamilyFallback: appFontFallback,
    );

/// Bundled fonts (see pubspec.yaml): text in Noto Sans, card suits from a subset of
/// Noto Sans Symbols 2. Nothing is fetched from a font CDN.
const appFont = 'NotoSans';
const appFontFallback = ['NotoSansSuits'];

class OxiPokerApp extends ConsumerWidget {
  const OxiPokerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: oxiTheme(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
