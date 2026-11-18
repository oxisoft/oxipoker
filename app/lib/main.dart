import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const OxiPokerApp());

/// Felt green of the classic table theme.
const felt = Color(0xFF0B5D3B);

class OxiPokerApp extends StatelessWidget {
  const OxiPokerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oxi Poker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: felt, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

/// Server health as reported by GET /api/v1/health.
class ServerInfo {
  const ServerInfo({required this.version, required this.media});

  final String version;
  final bool media;

  factory ServerInfo.fromJson(Map<String, dynamic> j) =>
      ServerInfo(version: j['version'] as String? ?? '?', media: j['media'] as bool? ?? false);
}

/// The web app is served by the server itself, so the API lives at the same
/// origin. Native apps get a server address picker in M1.
Future<ServerInfo?> fetchServerInfo({http.Client? client}) async {
  if (!kIsWeb) return null;
  final c = client ?? http.Client();
  try {
    final res = await c.get(Uri.base.resolve('/api/v1/health'));
    if (res.statusCode != 200) return null;
    return ServerInfo.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  } catch (_) {
    return null;
  } finally {
    if (client == null) c.close();
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.loader = fetchServerInfo});

  final Future<ServerInfo?> Function() loader;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Future<ServerInfo?> _info = widget.loader();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: felt,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('♠ ♥ ♦ ♣', style: text.displaySmall?.copyWith(color: Colors.white70)),
            const SizedBox(height: 16),
            Text('Oxi Poker', style: text.displayMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Self-hosted No-Limit Hold\'em for friends', style: text.titleMedium?.copyWith(color: Colors.white70)),
            const SizedBox(height: 32),
            FutureBuilder<ServerInfo?>(
              future: _info,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2));
                }
                final info = snap.data;
                final label = info == null
                    ? (kIsWeb ? 'Server not reachable' : 'Server connection arrives in the next milestone')
                    : 'Server ${info.version}${info.media ? ' · voice and video on' : ''}';
                return Text(label, key: const Key('server-status'), style: text.bodyMedium?.copyWith(color: Colors.white60));
              },
            ),
          ],
        ),
      ),
    );
  }
}
