import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oxipoker/main.dart';

void main() {
  testWidgets('home shows the name and the server version', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: HomePage(loader: () async => const ServerInfo(version: '0.1.0', media: true)),
    ));
    expect(find.text('Oxi Poker'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Server 0.1.0 · voice and video on'), findsOneWidget);
  });

  test('ServerInfo parses health JSON with defaults', () {
    final i = ServerInfo.fromJson({'status': 'ok', 'version': '1.2.3'});
    expect(i.version, '1.2.3');
    expect(i.media, isFalse);
  });
}
