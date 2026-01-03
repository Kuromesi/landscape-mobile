import 'dart:io';
import 'dart:async';
import 'dart:convert'; // Added for jsonEncode
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:landscape/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _logTag = "NetworkScanner";
RemotePairer? _pairer;

RemotePairer remotePairer() {
  _pairer ??= RemotePairer();
  return _pairer!;
}

class RemotePairer {
  bool _paired = false;
  bool _remoteControlEnabled = false;
  bool _isScanning = false;
  String? _pairedIp;
  int? _pairedPort;

  // Timer for the 10s heartbeat
  Timer? _heartbeatTimer;

  List<Map<String, dynamic>> _availableDevices = [];
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  // Getters
  bool get remoteControlEnabled => _remoteControlEnabled;
  bool get paired => _paired;
  bool get isScanning => _isScanning;
  String? get pairedIp => _pairedIp;
  int? get pairedPort => _pairedPort;
  List<Map<String, dynamic>> get availableDevices => _availableDevices;

  RemotePairer() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final List<String>? devices = await _prefs.getStringList('availableDevices');
    if (devices != null) {
      _availableDevices = devices.map((d) {
        final parts = d.split(':');
        return {'ip': parts[0], 'port': int.parse(parts[1])};
      }).toList();
    }
  }

  /// Heartbeat Logic: Sends POST /ping every 10 seconds
  void _startHeartbeat() {
    _stopHeartbeat(); // Ensure no duplicate timers
    void checkAndPing() {
      if (_remoteControlEnabled && _paired && _pairedIp != null) {
        _sendPing();
      } else {
        _stopHeartbeat();
      }
    }
    checkAndPing();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      checkAndPing();
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _sendPing() async {
    HttpClient? client;
    try {
      final String? myIp = await NetworkInfo().getWifiIP();
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      final request = await client.post(_pairedIp!, _pairedPort!, '/ping');
      
      // Set headers and body
      request.headers.contentType = ContentType.json;
      final Map<String, dynamic> body = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'ip': myIp ?? 'unknown',
      };
      
      request.write(jsonEncode(body));
      
      final response = await request.close();
      if (response.statusCode != 200) {
        FlutterLogs.logWarn(_logTag, "Ping", "Server returned ${response.statusCode}");
      }
    } catch (e) {
      FlutterLogs.logError(_logTag, "PingFailed", e.toString());
    } finally {
      client?.close();
    }
  }

  // --- Scanning Logic ---

  Future<void> autoPairScan([int? targetPort]) async {
    if (_isScanning) return;
    _isScanning = true;

    try {
      final String? wifiIP = await NetworkInfo().getWifiIP();
      final String? wifiSubmask = await NetworkInfo().getWifiSubmask();

      if (wifiIP == null || wifiSubmask == null) return;

      final List<String> ips = _calculateSubnetIPs(wifiIP, wifiSubmask);
      targetPort ??= 8080;

      const int batchSize = 30;
      for (int i = 0; i < ips.length; i += batchSize) {
        final end = (i + batchSize < ips.length) ? i + batchSize : ips.length;
        final batch = ips.sublist(i, end);

        final results = await Future.wait(
          batch.map((ip) => isDeviceAvailable(ip, targetPort!, silent: true))
        );

        for (int j = 0; j < results.length; j++) {
          if (results[j]) addDevice(batch[j], targetPort);
        }
      }
    } catch (e) {
      FlutterLogs.logError(_logTag, "autoPair", e.toString());
    } finally {
      _isScanning = false;
    }
  }

  List<String> _calculateSubnetIPs(String ip, String submask) {
    final ipParts = ip.split('.').map(int.parse).toList();
    final maskParts = submask.split('.').map(int.parse).toList();
    final int ipInt = (ipParts[0] << 24) | (ipParts[1] << 16) | (ipParts[2] << 8) | ipParts[3];
    final int maskInt = (maskParts[0] << 24) | (maskParts[1] << 16) | (maskParts[2] << 8) | maskParts[3];
    final int networkInt = ipInt & maskInt;
    final int broadcastInt = networkInt | (~maskInt & 0xffffffff);

    return List.generate(broadcastInt - networkInt - 1, (i) {
      final addr = networkInt + i + 1;
      return "${(addr >> 24) & 0xFF}.${(addr >> 16) & 0xFF}.${(addr >> 8) & 0xFF}.${addr & 0xFF}";
    });
  }

  Future<bool> isDeviceAvailable(String ip, int port, {bool silent = false}) async {
    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(milliseconds: 800);
      final request = await client.get(ip, port, '/livez');
      final response = await request.close();
      return response.statusCode == 200;
    } catch (e) {
      return false;
    } finally {
      client?.close();
    }
  }

  // --- Device Management ---

  void addDevice(String ip, int port) {
    if (!_availableDevices.any((d) => d['ip'] == ip && d['port'] == port)) {
      _availableDevices.add({'ip': ip, 'port': port});
      _prefs.setStringList('availableDevices', _availableDevices.map((e) => '${e['ip']}:${e['port']}').toList());
    }
  }

  void removeDevice(String ip, int port) {
    if (_pairedIp == ip && _pairedPort == port) unpair();
    _availableDevices.removeWhere((d) => d['ip'] == ip && d['port'] == port);
    _prefs.setStringList('availableDevices', 
        _availableDevices.map((e) => '${e['ip']}:${e['port']}').toList());
  }

  Future<bool> pair(String ip, int port) async {
    if (!await isDeviceAvailable(ip, port)) return false;
    addDevice(ip, port);
    _paired = true;
    _pairedIp = ip;
    _pairedPort = port;
    enableRemoteControl(); // This will start the heartbeat
    return true;
  }

  void unpair() {
    disableRemoteControl(); // This will stop the heartbeat
    _paired = false;
    _pairedIp = null;
    _pairedPort = null;
  }

  void enableRemoteControl() {
    _remoteControlEnabled = true;
    _startHeartbeat();
  }

  void disableRemoteControl() {
    _remoteControlEnabled = false;
    _stopHeartbeat();
  }
}
