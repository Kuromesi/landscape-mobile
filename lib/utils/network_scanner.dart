import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';

// class NetworkScanner extends StatefulWidget {
//   @override
//   _NetworkScannerState createState() => _NetworkScannerState();
// }

// class _NetworkScannerState extends State<NetworkScanner> {
//   List<String> ipAddresses = [];
//   List<String> responses = [];

//   @override
//   void initState() {
//     super.initState();
//     _getSubnetIPs();
//   }

//   Future<void> _getSubnetIPs() async {
//     String? wifiIP = await _getWiFiIP();
//     if (wifiIP == null) {
//       print("无法获取 WiFi IP 地址");
//       return;
//     }

//     String subnet = wifiIP.substring(0, wifiIP.lastIndexOf('.'));
//     for (int i = 1; i <= 254; i++) {
//       ipAddresses.add('$subnet.$i');
//     }
//     setState(() {});
//     _sendRequests();
//   }

//   Future<String?> _getWiFiIP() async {
//     try {
//       final info = NetworkInfo();
//       final wifiIP = await info.getWifiIP();
//       return wifiIP;
//     } catch (e) {
//       print("获取 WiFi IP 地址失败: $e");
//       return null;
//     }
//   }

//   Future<void> _sendRequests() async {
//     for (String ipAddress in ipAddresses) {
//       try {
//         final response = await http.get(Uri.http(ipAddress, '/'));
//         if (response.statusCode == 200) {
//           responses.add('$ipAddress: ${response.body}');
//         } else {
//           responses.add('$ipAddress: 请求失败，状态码: ${response.statusCode}');
//         }
//       } catch (e) {
//         responses.add('$ipAddress: 请求失败, 错误: $e');
//       }
//       setState(() {});
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('子网扫描'),
//       ),
//       body: ListView.builder(
//         itemCount: responses.length,
//         itemBuilder: (context, index) {
//           return ListTile(
//             title: Text(responses[index]),
//           );
//         },
//       ),
//     );
//   }
// }

class RemotePairer {
  Future<List<String>> autoPair() async {
    List<String> devices = [];
    try {
      List<String>? ipAddresses = await getSubnetIPs();
      List<String>? tmp = await availableDevices(ipAddresses!);
      if (tmp != null) {
        devices = tmp;
      }
    } catch (e) {
      print(e);
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

  Future<List<String>?> availableDevices(List<String> ips) async {
    List<String> devices = [];
    for (var ip in ips) {
        if (await isDeviceAvailable(ip, 8080)) {
          devices.add(ip);
        }
    }
    return devices;
  }

  Future<bool> isDeviceAvailable(String ip, int port) async {
    try {
      // timeout 1s
      HttpClient client = HttpClient();
      client.connectionTimeout = Duration(seconds: 1);
      HttpClientRequest  request = await client.get(ip, port, '/livez');
      HttpClientResponse response = await request.close();
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print(e);
    }
    return false;
  }
}
