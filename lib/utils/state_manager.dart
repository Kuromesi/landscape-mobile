import 'dart:io';

StateManager stateManager = StateManager(hostIp: "", hostPort: 0);

const String modeLocal = "local";
const String modeRemote = "remote";

class StateManager {
  String mode = modeLocal;
  String hostIp = "";
  int hostPort = 0;
  HttpClient client = HttpClient();
  StateManager({required this.hostIp, required this.hostPort}) {
    client.connectionTimeout = const Duration(seconds: 1);
  }

  Future<bool> setMode(String mode) async {
    HttpClientRequest request = await client.get(hostIp, hostPort, '/livez');
    HttpClientResponse response = await request.close();
    this.mode = mode;
    return response.statusCode == 200;
  }
}
