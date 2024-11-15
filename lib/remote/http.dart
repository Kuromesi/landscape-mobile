import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:landscape/remote/apis/health_check.dart';
import 'package:landscape/remote/apis/scroll_text.dart';
import 'package:landscape/notifiers/notifier.dart';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:landscape/constants/constants.dart';

Map<String, String> headers = {'Content-type': 'application/json'};

class RemoteHttpServerPage extends StatefulWidget {
  @override
  _RemoteHttpServerPageState createState() => _RemoteHttpServerPageState();
}

class _RemoteHttpServerPageState extends State<RemoteHttpServerPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  late HttpServer _server;
  bool _started = false;
  List<String> _logEntries = [];

  @override
  void initState() {
    super.initState();
  }

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
    try {
      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 8080);
    } catch (e) {
      _log(e.toString());
      return;
    }

    // Enable content compression
    _server.autoCompress = true;

    setState(() {
      _started = true;
    });
    _log("Server running on IP : ${_server.address} On Port : ${_server.port}");
  }

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
    notifier!.updateConfiguration(ScrollTextConfiguration(text: "testttt"));
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return SingleChildScrollView(
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

    router.get('/', (Request request) {
      return Response.ok('Hi, this is Kuromesi speaking!\n');
    });

    router.mount('/configure', ConfigureApi().router.call);
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

class ConfigureApi {
  Future<Response> _messages(Request request) async {
    return Response.ok('Apis for configuring players.\n');
  }

  Future<Response> _scrollText(Request request) async {
    String body = await request.readAsString();
    try {
      ScrollTextConfiguration conf =
        ScrollTextConfiguration.fromJson(jsonDecode(body));
      notifier!.updateConfiguration(conf);
    } catch (e) {
      return Response.badRequest(body: e.toString());
    }
    
    return Response.ok(null);
  }

  shelf_router.Router get router {
    final router = shelf_router.Router();

    router.get('/', _messages);

    router.post('/scroll-text', _scrollText);

    return router;
  }
}
