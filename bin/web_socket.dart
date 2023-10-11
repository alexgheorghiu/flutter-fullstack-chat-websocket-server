import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

List<Message> messages = <Message>[];
List<WebSocketChannel> webSockets = <WebSocketChannel>[];

class Message {
  String message;

  String author;

  DateTime? date;

  Message(String this.message, String this.author, DateTime? this.date);

  factory Message.fromJson(Map<String, dynamic> json) => Message(json['message'], json['author'], DateTime.tryParse(json['date']));

  Map<String, dynamic> toJson() => {
    'message': message,
    'author': author,
    'date': date!.toIso8601String()
  };
}

void dispatch(String message, List<WebSocketChannel> webSockets){
  for(WebSocketChannel webSocket in webSockets ){
    webSocket.sink.add(message);
  }
}

String packMessages(List<Message> messages){
  return jsonEncode(messages.reversed.toList());
}

void main(List<String> arguments) {
  var handler = webSocketHandler((WebSocketChannel webSocket) {
    webSockets.add(webSocket);
    print("New connection ${webSocket.protocol}");
    // webSocket.sink.add("[Server] New connection. Welcome to our chat.");

    String package = packMessages(messages);
    dispatch(package, webSockets);

    webSocket.stream.listen((message) {
      print('Received ${message}');
      messages.add(Message.fromJson(jsonDecode(message)));

      String package = packMessages(messages);
      print("Package ${package}");
      // webSocket.sink.add(package);
      dispatch(package, webSockets);
    });
  });

  shelf_io.serve(handler, '192.168.100.73', 10000).then((server) {
    print('Serving at ws://${server.address.host}:${server.port}');
  });
}
