import 'package:flutter/material.dart';
import 'package:landscape/notifiers/notifier.dart';
import 'package:landscape/utils/utils.dart';
import 'package:landscape/app.dart';

class LandscapeClient extends StatefulWidget {
  const LandscapeClient({super.key});
  @override
  _LandscapeClientState createState() => _LandscapeClientState();
}

class _LandscapeClientState extends State<LandscapeClient> {
  RemotePairer _remotePairer = remotePairer();

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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Added Devices:'),
            Expanded(
              child: ListView.builder(
                itemCount: _remotePairer.availableDevices.length,
                itemBuilder: (context, index) {
                  final device = _remotePairer.availableDevices[index];
                  final isPaired = device['ip'] == _remotePairer.pairedIp &&
                      device['port'] == _remotePairer.pairedPort;
                  return InkWell(
                    onTap: () async {
                      if (isPaired) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Confirm Unpairing'),
                              content: const Text(
                                  'Are you sure you want to unpair this device?'),
                              actions: <Widget>[
                                TextButton(
                                    child: const Text('Unpair'),
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      _remotePairer.unpair();
                                      scaffoldMessengerKey.currentState
                                          ?.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Device unpaired successfully'),
                                        ),
                                      );
                                      appNotifier!.updateAppState(
                                          appNotifier!.appState);
                                      setState(() {});
                                    }),
                                TextButton(
                                  child: const Text('Cancel'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                        return;
                      }
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Device Control'),
                            content: const Text('Pair or delete the device'),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('Pair'),
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  if (!await _remotePairer.pair(
                                      device['ip'], device['port'])) {
                                    scaffoldMessengerKey.currentState
                                        ?.showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to pair device'),
                                      ),
                                    );
                                  } else {
                                    scaffoldMessengerKey.currentState
                                        ?.showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Device paired successfully'),
                                      ),
                                    );
                                    setState(() {});
                                  }
                                },
                              ),
                              TextButton(
                                child: const Text('Delete'),
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  _remotePairer.removeDevice(
                                      device['ip'], device['port']);
                                  setState(() {});
                                },
                              ),
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32.0),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey, width: 1.0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${device['ip']}:${device['port']}',
                            style: const TextStyle(fontSize: 16.0),
                          ),
                          if (isPaired)
                            const InkWell(
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                            ),
                        ],
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
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showPairDialog(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _showManualPairDialog(context);
                  },
                  child: const Text('Add Device'),
                ),
                // const SizedBox(height: 10),
                // ElevatedButton(
                //   onPressed: () {
                //     // _autoPair();
                //   },
                //   child: const Text('Auto Pair'),
                // ),
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
          title: const Text('Add Device'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'IP Address'),
                onChanged: (value) {
                  _manualIp = value;
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Port'),
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
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_manualIp.isNotEmpty && _manualPort > 0) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return const Dialog(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Adding device...'),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                  bool available = await _remotePairer.isDeviceAvailable(
                      _manualIp, _manualPort);
                  Navigator.of(context).pop();
                  if (available) {
                    _remotePairer.addDevice(_manualIp, _manualPort);
                    scaffoldMessengerKey.currentState?.showSnackBar(
                      SnackBar(
                        content: Text(
                            'Successfully add device $_manualIp:$_manualPort'),
                      ),
                    );
                    setState(() {});
                  } else {
                    scaffoldMessengerKey.currentState?.showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Failed to add device, please check connectivity first'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}
