import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oxipoker/api/api.dart';
import 'package:oxipoker/l10n/app_localizations.dart';
import 'package:oxipoker/main.dart' show appLocalizationsDelegates;
import 'package:oxipoker/state/locale.dart';
import 'package:oxipoker/ui/account_screens.dart';
import 'package:oxipoker/ui/common.dart';
import 'package:oxipoker/ui/table_screen.dart';

class MemoryLocaleStore implements LocaleStore {
  String? code;

  @override
  Future<String?> load() async => code;

  @override
  Future<void> save(String? c) async => code = c;
}

/// Error codes the HTTP API can send: every writeError(..., "code") in the server.
Set<String> serverHttpCodes() {
  final re = RegExp(r'writeError\([^,]+,[^,]+,\s*"([a-z_]+)"\)');
  final codes = <String>{};
  for (final f in Directory('../server/internal').listSync(recursive: true)) {
    if (f is File && f.path.endsWith('.go') && !f.path.endsWith('_test.go')) {
      codes.addAll(re.allMatches(f.readAsStringSync()).map((m) => m.group(1)!));
    }
  }
  return codes;
}

/// Error codes of the realtime protocol (server/internal/realtime and table).
const realtimeCodes = [
  'not_your_turn', 'seat_taken', 'already_seated', 'illegal_action', 'bad_amount', 'rate_limited',
  'spectators_off', 'sng_started', 'too_few_players', 'host_or_admin_only', 'muted', 'removed', 'is_player',
  'not_seated', 'not_in_hand', 'no_table', 'not_sng', 'bad_chat', 'bad_seat', 'not_watching', 'bad_intent',
  'bad_settings', 'internal',
];

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  test('every HTTP error code of the server has its own sentence', () {
    final codes = serverHttpCodes();
    expect(codes.length, greaterThan(30));
    final generic = [for (final c in codes) if (errorText(en, ApiException(400, c)) == en.errGeneric(c)) c];
    expect(generic, isEmpty, reason: 'add these codes to errorText in lib/ui/common.dart');
  });

  test('every realtime error code has its own sentence', () {
    final generic = [for (final c in realtimeCodes) if (intentError(en, c) == en.errGeneric(c)) c];
    expect(generic, isEmpty, reason: 'add these codes to intentError in lib/ui/table_screen.dart');
  });

  test('every language has every string of the English template', () {
    final template = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, dynamic>;
    final keys = template.keys.where((k) => !k.startsWith('@')).toSet();
    expect(AppLocalizations.supportedLocales.length, appLanguages.length);
    for (final code in appLanguages.keys) {
      final arb = jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync()) as Map<String, dynamic>;
      expect(arb['@@locale'], code);
      final missing = keys.difference(arb.keys.toSet());
      expect(missing, isEmpty, reason: 'app_$code.arb misses $missing');
      final t = lookupAppLocalizations(Locale(code));
      expect(t.errGeneric('x'), contains('x'), reason: code);
      if (code != 'en') expect(t.language, isNot(en.language), reason: code);
    }
  });

  testWidgets('the language picker switches the app and remembers the choice', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = MemoryLocaleStore();
    await tester.pumpWidget(ProviderScope(
      overrides: [localeStoreProvider.overrideWithValue(store)],
      child: Consumer(builder: (context, ref, _) => MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: ref.watch(localeProvider),
        home: Scaffold(body: Builder(builder: (context) => Column(children: [
          Text(context.l.language, key: const Key('heading')),
          const LanguagePicker(),
        ]))),
      )),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);

    await tester.tap(find.byKey(const Key('language-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-de')).last);
    await tester.pumpAndSettle();
    expect(find.text('Sprache'), findsOneWidget);
    expect(store.code, 'de');

    await tester.tap(find.byKey(const Key('language-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-ja')).last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('heading')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('heading'))).data, lookupAppLocalizations(const Locale('ja')).language);
    expect(store.code, 'ja');

    await tester.tap(find.byKey(const Key('language-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-device')).last);
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);
    expect(store.code, isNull);
  });
}
