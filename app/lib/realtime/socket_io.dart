import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

WebSocketChannel connect(Uri uri, String? token) =>
    IOWebSocketChannel.connect(uri, headers: {if (token != null) 'Authorization': 'Bearer $token'});
