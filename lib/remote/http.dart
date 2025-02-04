import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:landscape/apis/apis.dart';
import 'package:landscape/apis/health_check.dart';
import 'package:landscape/apis/scroll_text.dart';
import 'package:landscape/notifiers/notifier.dart';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:landscape/constants/constants.dart';
import 'package:landscape/utils/utils.dart';
import 'package:flutter_logs/flutter_logs.dart';

Map<String, String> headers = {'Content-type': 'application/json'};
String _logTag = "HttpServer";

class RemoteHttpServerPage extends StatefulWidget {
  @override
  _RemoteHttpServerPageState createState() => _RemoteHttpServerPageState();
}

class _RemoteHttpServerPageState extends State<RemoteHttpServerPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  int _maxLogLength = 100;

  late HttpServer _server;
  bool _started = false;
  List<String> _logEntries = [];
  int _port = 8080;

  @override
  void initState() {
    super.initState();
  }

  void _log(String message) {
    if (_logEntries.length > _maxLogLength) {
      _logEntries.removeAt(0);
    }
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
            FlutterLogs.logInfo(_logTag, "", response.headers.toString());
            return response;
          },
        )
        .addHandler(service.handler);
    try {
      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, _port);
    } catch (e) {
      FlutterLogs.logError(_logTag, "", e.toString());
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
    super.build(context);
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
            heroTag: "http_settings",
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

  void _showServerConfiguration(BuildContext context) {
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
                      child: TextFormField(
                        decoration: InputDecoration(labelText: 'Port'),
                        initialValue: _port.toString(),
                        readOnly: _started,
                        onChanged: (value) {
                          innerSetState(() {
                            _port = int.tryParse(value) ?? 8080;
                          });
                          setState(() {
                            _port = _port;
                          });
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

  void _showSettingsDialog(BuildContext context) {
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
                        child: const Text('Server Configuration'),
                        onPressed: () {
                          _showServerConfiguration(context);
                        },
                      ),
                    ),
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

  Future<Response> _remoteApp(Request request) async {
    String body = await request.readAsString();
    try {
      RemoteAppState conf = RemoteAppState.fromJson(jsonDecode(body));
      notifier!.updateConfiguration(conf);
    } catch (e) {
      FlutterLogs.logError(_logTag, "", e.toString());
      return Response.badRequest(body: e.toString());
    }

    return Response.ok("remote app configuration successfully updated.");
  }

  Future<Response> _configDump(Request request) async {
    try {
      Map<String, dynamic> config = Map();
      for (var k in configDump.keys) {
        config[k] = configDump[k]!().toJson();
      }
      return Response.ok(encoding: utf8, headers: headers, jsonEncode(config));
    } catch (e) {
      FlutterLogs.logError(_logTag, "", e.toString());
      return Response.internalServerError(body: e.toString());
    }
  }

  Future<Response> _changeMode(Request request) async {
    try {
      if (request.requestedUri.queryParameters['mode'] == null) {
        return Response.badRequest(body: 'mode is not specified');
      }
      notifier!.updateMode(request.requestedUri.queryParameters['mode']!);
      return Response.ok(
          "mode successfully updated to ${request.requestedUri.queryParameters['mode']}");
    } catch (e) {
      FlutterLogs.logError(_logTag, "", e.toString());
      return Response.internalServerError(body: e.toString());
    }
  }

  shelf_router.Router get router {
    final router = shelf_router.Router();

    router.get('/', _messages);
    router.get('/config-dump', _configDump);

    router.post('/remote-app', _remoteApp);

    router.mount('/scroll-text', ScrollTextConfigurationApi().router.call);
    router.mount('/gif-player', GifConfigurationApi().router.call);
    router.mount('/app', AppConfigureApi().router.call);

    return router;
  }
}

class GifConfigurationApi {
  Future<Response> _messages(Request request) async {
    return Response.ok('Apis for configuring gif player.\n');
  }

  Future<Response> _gifPlayer(Request request) async {
    String body = await request.readAsString();
    try {
      GifConfiguration conf = GifConfiguration.fromJson(jsonDecode(body));
      gifNotifier!.updateGifConfig(conf);
    } catch (e) {
      FlutterLogs.logError(_logTag, "", e.toString());
      return Response.badRequest(body: e.toString());
    }

    return Response.ok("gif player configuration successfully updated.");
  }

  Future<Response> _play(Request request) async {
    try {
      gifNotifier!.play();
    } catch(e) {
      FlutterLogs.logError(_logTag, "", e.toString());
      return Response.badRequest(body: e.toString());
    }
    return Response.ok("gif player successfully played.");
  }

  Future<Response> _stop(Request request) async {
    try {
      gifNotifier!.stop();
    } catch(e) {
      FlutterLogs.logError(_logTag, "", e.toString());
      return Response.badRequest(body: e.toString());
    }
    return Response.ok("gif player successfully stopped.");
  }

  shelf_router.Router get router {
    final router = shelf_router.Router();

    router.get('/', _messages);

    router.post('/full', _gifPlayer);
    router.get('/play', _play);
    router.get('/stop', _stop);
    return router;
  }
}

class ScrollTextConfigurationApi {
  Future<Response> _messages(Request request) async {
    return Response.ok('Apis for configuring scroll text.\n');
  }

  Future<Response> _scrollText(Request request) async {
    String body = await request.readAsString();
    try {
      ScrollTextConfiguration conf =
          ScrollTextConfiguration.fromJson(jsonDecode(body));
      scrollTextNotifier!.updateScrollTextConfig(conf);
    } catch (e) {
      FlutterLogs.logError(_logTag, "", e.toString());
      return Response.badRequest(body: e.toString());
    }

    return Response.ok("scroll text configuration successfully updated.");
  }

  shelf_router.Router get router {
    final router = shelf_router.Router();

    router.get('/', _messages);

    router.post('/full', _scrollText);
    return router;
  }
}

class AppConfigureApi {
  Future<Response> _messages(Request request) async {
    return Response.ok('Apis for configuring landscape application.\n');
  }

  Future<Response> _app(Request request) async {
    String body = await request.readAsString();
    try {
      AppState conf = AppState.fromJson(jsonDecode(body));
      appNotifier!.updateAppState(conf);
    } catch (e) {
      FlutterLogs.logError(_logTag, "", e.toString());
      return Response.badRequest(body: e.toString());
    }

    return Response.ok("app configuration successfully updated.");
  }

  shelf_router.Router get router {
    final router = shelf_router.Router();

    router.get('/', _messages);

    router.post('/full', _app);
    return router;
  }
}
