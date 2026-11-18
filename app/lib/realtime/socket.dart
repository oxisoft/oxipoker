import 'package:web_socket_channel/web_socket_channel.dart';

import 'socket_io.dart' if (dart.library.js_interop) 'socket_web.dart' as impl;

/// One open realtime connection: text frames in, text frames out.
abstract class PokerSocket {
  /// Completes when the connection is open; throws when it could not open.
  Future<void> get ready;
  Stream<String> get messages;
  void send(String text);
  Future<void> close();
}

/// Opens a socket to [uri]. Native apps send [token] as a bearer token; the
/// web app relies on its session cookie and the browser's Origin header.
typedef SocketFactory = PokerSocket Function(Uri uri, String? token);

PokerSocket openSocket(Uri uri, String? token) => ChannelSocket(impl.connect(uri, token));

class ChannelSocket implements PokerSocket {
  ChannelSocket(this._ch);

  final WebSocketChannel _ch;

  @override
  Future<void> get ready => _ch.ready;

  @override
  Stream<String> get messages => _ch.stream.where((m) => m is String).cast<String>();

  @override
  void send(String text) => _ch.sink.add(text);

  @override
  Future<void> close() => _ch.sink.close();
}
