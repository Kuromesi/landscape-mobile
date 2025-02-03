import 'package:flutter/material.dart';
import 'package:landscape/notifiers/notifier.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:landscape/players/players.dart';

import 'package:landscape/apis/apis.dart';
import 'package:landscape/utils/utils.dart';

final _messangerKey = GlobalKey<ScaffoldMessengerState>();

void notify(String text) {
  final snackBar = SnackBar(
    content: Text(text),
    duration: const Duration(seconds: 2),
  );
  if (_messangerKey.currentState != null) {
    _messangerKey.currentState!.showSnackBar(snackBar);
  } else {
    print("ScaffoldMessengerState is null, cannot show SnackBar.");
  }
}

class LandscapeClient extends StatefulWidget {
  const LandscapeClient({super.key});
  @override
  _LandscapeClientState createState() => _LandscapeClientState();
}

class _LandscapeClientState extends State<LandscapeClient> {
  final RemoteAppState _conf = RemoteAppState(
      mode: configScrollText,
      scrollTextConfig: ScrollTextConfiguration(),
      gifConfig: GifConfiguration());

  List<Map<String, dynamic>> _devices = [{'ip': '192.168.1.1', 'port': 8080},{'ip': '192.168.1.1', 'port': 8080},{'ip': '192.168.1.1', 'port': 8080},{'ip': '192.168.1.1', 'port': 8080},{'ip': '192.168.1.1', 'port': 8080}];

  RemotePairer _remotePairer = RemotePairer();

  bool _paired = false;
  bool _syncing = false;

  String _manualIp = '';
  int _manualPort = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _messangerKey,
     body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            Text('Paired Devices:'),
            Expanded(
              child: ListView.builder(
                itemCount: _devices.length,
                itemBuilder: (context, index) {
                  final device = _devices[index];
                  return InkWell(
                  onTap: () {
                    // 处理点击事件
                    print('Device clicked: ${device['ip']}:${device['port']}');
                  },
                  child: Container(
                    width: double.infinity, // 宽度与屏幕宽度相同
                    padding: EdgeInsets.all(32.0),

                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey, width: 1.0),
                      ),
                    ),
                    child: Center(
                      child: Text(
                      '${device['ip']}:${device['port']}',
                      style: TextStyle(fontSize: 16.0),
                    ),
                    ),
                    
                  ),
                );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
            heroTag: "pair",
            onPressed: () => {_showPairDialog(context)},
            child: Icon(Icons.add),
          ),
    );
  }

  void _showPairDialog(BuildContext context) {
  showModalBottomSheet(
    isScrollControlled: true,
    context: context,
    builder: (BuildContext context) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        child: SingleChildScrollView(
          padding: MediaQuery.of(context).viewInsets,
          child: Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  _showManualPairDialog(context);
                },
                child: Text('Manaul Pair'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  // _autoPair();
                },
                child: Text('Auto Pair'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  void _showManualPairDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Manual Pair'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'IP 地址'),
                onChanged: (value) {
                  _manualIp = value;
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: '端口'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _manualPort = int.tryParse(value) ?? 0;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_manualIp.isNotEmpty && _manualPort > 0) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return Dialog(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('pairing...'),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                  bool paired = await _remotePairer.isDeviceAvailable(
                      _manualIp, _manualPort);
                  if (paired) {
                    _devices.add({'ip': _manualIp, 'port': _manualPort});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('paired')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('pair failed')),
                    );
                  }
                  Navigator.of(context).pop();
                }
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}
