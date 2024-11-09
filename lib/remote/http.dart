import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:landscape/remote/apis/health_check.dart';
import 'package:landscape/remote/apis/scroll_text.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;

void main() {
  runApp(MaterialApp(
    home: RemoteHttpServerPage(),
  ));
}

double optionsBarWidth = 0.6;
Map<String, String> headers = {'Content-type': 'application/json'};

class RemoteHttpServerPage extends StatefulWidget {
  // final StreamController httpController;
  // const Home({Key? key, required this.httpController}) : super(key: key);

  @override
  _RemoteHttpServerPageState createState() => _RemoteHttpServerPageState();
}

class _RemoteHttpServerPageState extends State<RemoteHttpServerPage> {
  late HttpServer _server;
  bool _started = false;
  List<String> _logEntries = [];

  void _log(String message) {
    _logEntries.add(message);
    if (!mounted) return;
    setState(() {
      _logEntries = _logEntries;
    });
  }

  void _clearLog() {
    setState(() {
      _logEntries = [];
    });
  }

  void _requestLog(String message, bool isErr) async {
    _log(message);
  }

  void _startServer() async {
    Service service = Service();
    var handler = const Pipeline()
        .addMiddleware(logRequests(logger: _requestLog))
        .addMiddleware(
          (handler) => (request) async {
            final response = await handler(request);
            print(response.headers);
            // you could read the body here, but you'd also need to
            // save the content and pipe it into a new response instance
            return response;
          },
        )
        .addHandler(service.handler);
    _server = await shelf_io.serve(handler, 'localhost', 8080);

    // Enable content compression
    _server.autoCompress = true;

    setState(() {
      _started = true;
    });
    _log("Server running on IP : ${_server.address} On Port : ${_server.port}");
  }

  Response _echoRequest(Request request) =>
      Response.ok('Request for "${request.url}"');

  void _stopServer() async {
    _log("stopping server");
    await _server.close();
    setState(() {
      _started = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildPage(context);
  }

  Widget _buildPage(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "startHttp",
            onPressed: _started ? _stopServer : _startServer,
            child: _started ? Icon(Icons.stop) : Icon(Icons.play_arrow),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "settings",
            onPressed: () => {_showSettingsDialog(context)},
            child: Icon(Icons.menu),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _logEntries.length,
                itemBuilder: (context, index) {
                  return Text(_logEntries[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showModalBottomSheet(
      // fix when using keyboard this panel will be hided
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          // fix when using keyboard this panel will be hided
          padding: MediaQuery.of(context).viewInsets,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter innerSetState) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width:
                          MediaQuery.of(context).size.width * optionsBarWidth,
                      child: ElevatedButton(
                        child: Text('Clear Log'),
                        onPressed: () {
                          _clearLog();
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class Service {
  Handler get handler {
    final router = shelf_router.Router();

    router.get('/', (Request request, String name) {
      return Response.ok('Hi, this is Kuromesi speaking!');
    });

    router.get('/wave', (Request request) async {
      await Future<void>.delayed(Duration(milliseconds: 100));
      return Response.ok('_o/');
    });

    router.mount('/configure', Api().router.call);
    router.mount('/', HealthCheck().router.call);

    return router.call;
  }
}

class HealthCheck {
  Future<Response> _livez(Request request) async {
    print(LivezResponse(isAlive: true).toJson().toString());
    return Response.ok(
        encoding: utf8,
        headers: headers,
        LivezResponse(isAlive: true).toJson().toString());
  }

  shelf_router.Router get router {
    final router = shelf_router.Router();

    router.get('/livez', _livez);

    return router;
  }
}

class Api {
  Future<Response> _messages(Request request) async {
    return Response.ok('[]');
  }

  Future<Response> _scrollText(Request request) async {
    String body = await request.readAsString();
    // ScrollTextConfiguration conf =
    // ScrollTextConfiguration.fromJson(jsonDecode(body));
    final ScrollTextNotifier notifer = ScrollTextNotifier();
    notifer.updateConfiguration(ScrollTextConfiguration(text: "test2"));
    return Response.ok('[]');
  }

  shelf_router.Router get router {
    final router = shelf_router.Router();

    router.get('/', _messages);

    router.get('/scroll-text', _scrollText);

    return router;
  }
}

class ScrollTextNotifier extends ChangeNotifier {
  ScrollTextConfiguration _configuration =
      ScrollTextConfiguration(text: 'test');

  String text = "test1";

  ScrollTextConfiguration get configuration => _configuration;

  void updateConfiguration(ScrollTextConfiguration newConfig) {
    text = newConfig.text;
    notifyListeners();
  }
}

// const httpPut = "PUT";
// const httpPost = "POST";
// const httpGet = "GET";

// class RemoteHttpServer {
//   final HttpServer server;
//   final StrubgC log;
//   const RemoteHttpServer({required this.server, required this.log});
//   void startServer() async {
//     log("starting server");

//     await for (var req in server) {
//       route(req);
//     }
//   }

//   void stopServer() async {
//     await server.close();
//   }

//   void route(HttpRequest request) async {
//     switch (request.uri.path) {
//       case '/':
//         request.response
//           ..headers.contentType =
//               new ContentType("application", "json", charset: "utf-8")
//     }
//   }

//   void registerRoutes(String path, method) {

//   }
// }

// class UserStore extends ChangeNotifier {
//   List<User> clientList = [];

//   void deleteUser(User list) {
//     clientList.remove(list);
//     notifyListeners();
//   }

//   void addClient(User list) {
//     clientList.add(list);
//     notifyListeners();
//   }

//   void updateUser(User user) {
//     clientList[clientList.indexWhere((element) => element.id == user.id)] =
//         user;
//     notifyListeners();
//   }
// }
