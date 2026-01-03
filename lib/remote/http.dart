import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:landscape/apis/apis.dart';
import 'package:landscape/notifiers/notifier.dart';
import 'package:landscape/utils/utils.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;

// Global headers
const Map<String, String> _jsonHeaders = {'Content-type': 'application/json'};
const String _logTag = "HttpServer";

class RemoteHttpServerPage extends StatefulWidget {
  @override
  _RemoteHttpServerPageState createState() => _RemoteHttpServerPageState();
}

class _RemoteHttpServerPageState extends State<RemoteHttpServerPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final int _maxLogLength = 150;
  final ScrollController _scrollController = ScrollController();

  HttpServer? _server;
  bool _started = false;
  final List<String> _logEntries = [];
  int _port = 8080;
  String _localIp = "Detecting...";

  @override
  void initState() {
    super.initState();
    _getIpAddress();
  }

  @override
  void dispose() {
    _stopServer(); // Ensure server is closed when page is destroyed
    _scrollController.dispose();
    super.dispose();
  }

  /// Helper to get the local IP address of the Android device
  Future<void> _getIpAddress() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            setState(() => _localIp = addr.address);
            return;
          }
        }
      }
    } catch (e) {
      _log("Failed to get IP: $e");
    }
  }

  void _log(String message) {
    final timestamp =
        DateTime.now().toString().split('.').first.split(' ').last;
    if (_logEntries.length > _maxLogLength) _logEntries.removeAt(0);
    _logEntries.add("[$timestamp] $message");
    if (!mounted) return;
    setState(() {});

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startServer() async {
    final service = Service(_log);
    final handler = const Pipeline()
        .addMiddleware(logRequests(logger: (msg, isErr) => _log(msg)))
        .addHandler(service.handler);

    try {
      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, _port);
      _server!.autoCompress =
          true; // Optimization: compress large JSON responses
      setState(() => _started = true);
      _log("Server LIVE at http://$_localIp:$_port");
    } catch (e) {
      FlutterLogs.logError(_logTag, "StartError", e.toString());
      _log("Error: $e");
    }
  }

  void _stopServer() async {
    if (_server != null) {
      await _server!.close(force: true);
      setState(() => _started = false);
      _log("Server stopped.");
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("HTTP Server - $_localIp"),
        actions: [
          IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => setState(() => _logEntries.clear())),
        ],
      ),
      floatingActionButton: _buildFABs(),
      body: Container(
        color: Colors.black87, // Dark background for terminal-like logs
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          controller: _scrollController,
          itemCount: _logEntries.length,
          itemBuilder: (context, index) => Text(
            _logEntries[index],
            style: const TextStyle(
                color: Colors.greenAccent,
                fontFamily: 'monospace',
                fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildFABs() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: "startHttp",
          onPressed: _started ? _stopServer : _startServer,
          backgroundColor: _started ? Colors.red : Colors.green,
          child: Icon(_started ? Icons.stop : Icons.play_arrow),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          heroTag: "http_settings",
          onPressed: () => _showSettingsDialog(context),
          child: const Icon(Icons.settings),
        ),
      ],
    );
  }

  void _showServerConfiguration(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Port Configuration",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(
                  labelText: 'Port', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: _port.toString()),
              readOnly: _started,
              onChanged: (value) => _port = int.tryParse(value) ?? 8080,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.lan),
              title: const Text('Server Configuration'),
              onTap: () {
                Navigator.pop(ctx);
                _showServerConfiguration(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cleaning_services),
              title: const Text('Clear Logs'),
              onTap: () {
                setState(() => _logEntries.clear());
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// --- API Implementation ---

class Service {
  final void Function(String message) _log;

  Service(this._log);

  Handler get handler {
    final router = shelf_router.Router();
    router.get(
        '/', (Request request) => Response.ok('Display App Server Active\n'));

    // Maintain your exact route structure
    router.mount('/configure', ConfigureApi().router.call);
    router.mount('/', HealthCheck(_log).router.call);
    return router.call;
  }
}

class HealthCheck {
  late void Function(String message) _log;

  HealthCheck(this._log);
  Timer? _debounceTimer;
  int _pingCount = 0;

  shelf_router.Router get router {
    final router = shelf_router.Router();
    router.get(
        '/livez',
        (Request r) =>
            Response.ok(jsonEncode({'isAlive': true}), headers: _jsonHeaders));
    router.post('/ping', (Request r) async {
      final String bodyString = await r.readAsString();
      final remoteInfo =
          r.context['shelf.io.connection_info'] as HttpConnectionInfo?;
      final String remoteIp = remoteInfo?.remoteAddress.address ?? "Unknown";

      try {
        final Map<String, dynamic> data = jsonDecode(bodyString);

        if (_pingCount % 10 == 0) {
          // Format: [PING] 192.168.1.5 (Reported: 192.168.1.5)
          _log("[PING] $remoteIp (Reported: ${data['ip']})");
        }
        _pingCount++;

        _debounceTimer?.cancel();
        if (!appNotifier!.appState.underControl!) {
          appNotifier!.appState.underControl = true;
          appNotifier!.updateAppState(appNotifier!.appState);
        }
        _debounceTimer = Timer(const Duration(seconds: 10), () {
          appNotifier!.appState.underControl = false;
          appNotifier!.updateAppState(appNotifier!.appState);
        });
      } catch (e) {
        // Fallback if JSON is malformed
        _log("[PING] $remoteIp - No data");
      }

      return Response.ok("pong");
    });
    return router;
  }
}

class ConfigureApi {
  /// Internal helper to process Notifier updates to keep the code clean
  Future<Response> _updateNotifierConfig<T>(Request request, dynamic notifier,
      T Function(Map<String, dynamic>) fromJson) async {
    try {
      final body = await request.readAsString();
      if (notifier == null)
        return Response.internalServerError(body: "Notifier not initialized");

      final config = fromJson(jsonDecode(body));
      notifier.updateConfiguration(
          config); // Generic call (assuming updateConfiguration exists)
      return Response.ok("Configuration updated successfully");
    } catch (e) {
      FlutterLogs.logError(_logTag, "ApiError", e.toString());
      return Response.badRequest(body: e.toString());
    }
  }

  shelf_router.Router get router {
    final router = shelf_router.Router();

    router.get('/', (Request r) => Response.ok('Config APIs Active\n'));

    // Route: /configure/mode
    router.get('/mode', (Request request) async {
      final mode = request.requestedUri.queryParameters['mode'];
      if (mode == null) return Response.badRequest(body: 'mode missing');
      notifier?.updateMode(mode);
      return Response.ok("Mode updated to $mode");
    });

    // Route: /configure/config-dump
    router.get('/config-dump', (Request request) async {
      Map<String, dynamic> config = {};
      configDump.forEach((k, v) => config[k] = v().toJson());
      return Response.ok(jsonEncode(config), headers: _jsonHeaders);
    });

    // Route: /configure/remote-app (POST)
    router.post('/remote-app', (Request r) async {
      try {
        final body = await r.readAsString();
        notifier
            ?.updateConfiguration(RemoteAppState.fromJson(jsonDecode(body)));
        return Response.ok("Remote app updated");
      } catch (e) {
        return Response.badRequest(body: e.toString());
      }
    });

    // Sub-routes mounting (Exact same as before)
    router.mount('/scroll-text', ScrollTextConfigurationApi().router.call);
    router.mount('/gif-player', GifConfigurationApi().router.call);
    router.mount('/app', AppConfigureApi().router.call);

    return router;
  }
}

class GifConfigurationApi {
  shelf_router.Router get router {
    final router = shelf_router.Router();
    router.get('/', (Request r) => Response.ok('Gif API\n'));
    router.post('/full', (Request r) async {
      try {
        final body = await r.readAsString();
        gifNotifier
            ?.updateGifConfig(GifConfiguration.fromJson(jsonDecode(body)));
        return Response.ok("Gif configuration updated");
      } catch (e) {
        return Response.badRequest(body: e.toString());
      }
    });
    return router;
  }
}

class ScrollTextConfigurationApi {
  shelf_router.Router get router {
    final router = shelf_router.Router();
    router.get('/', (Request r) => Response.ok('ScrollText API\n'));
    router.post('/full', (Request r) async {
      try {
        final body = await r.readAsString();
        scrollTextNotifier?.updateScrollTextConfig(
            ScrollTextConfiguration.fromJson(jsonDecode(body)));
        return Response.ok("Scroll text updated");
      } catch (e) {
        return Response.badRequest(body: e.toString());
      }
    });
    return router;
  }
}

class AppConfigureApi {
  shelf_router.Router get router {
    final router = shelf_router.Router();
    router.get('/', (Request r) => Response.ok('App API\n'));
    router.post('/full', (Request r) async {
      try {
        final body = await r.readAsString();
        appNotifier?.updateAppState(AppState.fromJson(jsonDecode(body)));
        return Response.ok("App state updated");
      } catch (e) {
        return Response.badRequest(body: e.toString());
      }
    });
    return router;
  }
}
