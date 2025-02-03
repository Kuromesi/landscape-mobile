import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';

StateManager stateManager = StateManager(hostIp: "", hostPort: 0);

const String modeLocal = "local";
const String modeRemote = "remote";

class StateManager {
  String mode = modeLocal;
  String hostIp = "";
  int hostPort = 0;
  HttpClient client = HttpClient();
  StateManager({required this.hostIp, required this.hostPort}) {
    client.connectionTimeout = Duration(seconds: 1);
  }

  Future<bool> setMode(String mode) async {
    HttpClientRequest request = await client.get(hostIp, hostPort, '/livez');
    HttpClientResponse response = await request.close();
    this.mode = mode;
    return response.statusCode == 200;
  }
}
