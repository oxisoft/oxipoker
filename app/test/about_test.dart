import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oxipoker/api/models.dart';
import 'package:oxipoker/l10n/app_localizations.dart';
import 'package:oxipoker/main.dart' show appLocalizationsDelegates;
import 'package:oxipoker/media/call.dart';
import 'package:oxipoker/ui/account_screens.dart';

Future<void> _pump(WidgetTester tester, ServerInfo info) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [serverInfoProvider.overrideWith((ref) async => info)],
    child: MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: AboutInfo()),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  test('health without an api level is an old server', () {
    expect(ServerInfo.fromJson({'version': '0.9.0'}).tooOld, isTrue);
    expect(ServerInfo.fromJson({'version': '1.0.0', 'api': 1}).tooOld, isFalse);
    expect(ServerInfo.fromJson({'version': '1.2.0', 'api': 2}).api, 2);
  });

  testWidgets('about shows app and server versions', (tester) async {
    await _pump(tester, const ServerInfo(version: '1.0.0', media: false, api: requiredServerApi));
    expect(find.text('App $appVersion'), findsOneWidget);
    expect(find.text('Server 1.0.0'), findsOneWidget);
    expect(find.byKey(const Key('server-too-old')), findsNothing);
  });

  testWidgets('about warns when the server is older than the app needs', (tester) async {
    await _pump(tester, const ServerInfo(version: '0.9.0', media: false, api: 0));
    expect(find.byKey(const Key('server-too-old')), findsOneWidget);
  });
}
