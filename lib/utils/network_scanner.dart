import 'dart:io';
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
  String? _pairedIp;
  int? _pairedPort;

  List<Map<String, dynamic>> _availableDevices = [];
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  get remoteControlEnabled => _remoteControlEnabled;
  get paired => _paired;
  get pairedIp => _pairedIp;
  get pairedPort => _pairedPort;
  get availableDevices => _availableDevices;

  // construct method of the class
  RemotePairer() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    List<String>? devices = await _prefs.getStringList('availableDevices');
    if (devices != null) {
      for (var device in devices) {
        List<String> parts = device.split(':');
        if (parts.length == 2) {
          _availableDevices.add({'ip': parts[0], 'port': int.parse(parts[1])});
        }
      }
    }
  }

  Future<List<String>> autoPair() async {
    List<String> devices = [];
    try {
      List<String>? ipAddresses = await getSubnetIPs();
      List<String>? tmp = await filterAvailableDevices(ipAddresses!, 8080);
      if (tmp != null) {
        devices = tmp;
      }
    } catch (e) {
      FlutterLogs.logError(_logTag, "", e.toString());
    }
    return devices;
  }

  Future<List<String>?> getSubnetIPs() async {
    NetworkInfo info = NetworkInfo();
    String? wifiIP = await info.getWifiIP();
    if (wifiIP == null) {
      Exception("failed to get wifi ip");
    }

    String? wifiSubmask = await info.getWifiSubmask();
    if (wifiSubmask == null) {
      Exception("failed to get wifi submask");
    }
    List<String> ipAddresses = calculateSubnetIPs(wifiIP!, wifiSubmask!);
    return ipAddresses;
  }

  List<String> calculateSubnetIPs(String ip, String submask) {
    List<int> ipParts = ip.split('.').map(int.parse).toList();
    List<int> maskParts = submask.split('.').map(int.parse).toList();

    int ipInt = (ipParts[0] << 24) |
        (ipParts[1] << 16) |
        (ipParts[2] << 8) |
        ipParts[3];
    int maskInt = (maskParts[0] << 24) |
        (maskParts[1] << 16) |
        (maskParts[2] << 8) |
        maskParts[3];

    int networkInt = ipInt & maskInt;
    int broadcastInt = networkInt | (~maskInt);

    List<String> ipAddresses = [];
    for (int i = networkInt + 1; i < broadcastInt; i++) {
      List<int> parts = [
        (i >> 24) & 0xFF,
        (i >> 16) & 0xFF,
        (i >> 8) & 0xFF,
        i & 0xFF
      ];
      ipAddresses.add(parts.join('.'));
    }

    return ipAddresses;
  }

  Future<List<String>?> filterAvailableDevices(
      List<String> ips, int port) async {
    List<String> devices = [];
    for (var ip in ips) {
      if (await isDeviceAvailable(ip, port)) {
        devices.add(ip);
      }
    }
    return devices;
  }

  Future<bool> isDeviceAvailable(String ip, int port) async {
    try {
      HttpClient client = HttpClient();
      client.connectionTimeout = Duration(seconds: 1);
      HttpClientRequest request = await client.get(ip, port, '/livez');
      HttpClientResponse response = await request.close();
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      FlutterLogs.logError(_logTag, "", e.toString());
    }
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('Device not available, $ip:$port'),
      ),
    );
    return false;
  }

  void addDevice(String ip, int port) {
    if (!_availableDevices
        .any((element) => element['ip'] == ip && element['port'] == port)) {
      _availableDevices.add({'ip': ip, 'port': port});
    }
    _prefs.setStringList('availableDevices',
        _availableDevices.map((e) => '${e['ip']}:${e['port']}').toList());
  }

  void removeDevice(String ip, int port) {
    if (_pairedIp == ip && _pairedPort == port) {
      unpair();
      _remoteControlEnabled = false;
    }
    _availableDevices.removeWhere(
        (element) => element['ip'] == ip && element['port'] == port);
    _prefs.setStringList('availableDevices',
        _availableDevices.map((e) => '${e['ip']}:${e['port']}').toList());
  }

  Future<bool> pair(String ip, int port) async {
    if (!await isDeviceAvailable(ip, port)) {
      return false;
    }
    if (!_availableDevices
        .any((element) => element['ip'] == ip && element['port'] == port)) {
      _availableDevices.add({'ip': ip, 'port': port});
    }
    _paired = true;
    _pairedIp = ip;
    _pairedPort = port;
    return true;
  }

  void unpair() {
    _remoteControlEnabled = false;
    _paired = false;
    _pairedIp = null;
    _pairedPort = null;
  }

  void enableRemoteControl() {
    _remoteControlEnabled = true;
  }

  void disableRemoteControl() {
    _remoteControlEnabled = false;
  }
}
