import 'package:web_socket_channel/web_socket_channel.dart';

/// The browser sends the session cookie and the Origin header itself.
WebSocketChannel connect(Uri uri, String? token) => WebSocketChannel.connect(uri);
