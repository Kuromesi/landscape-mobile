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
  final RemotePairer _remotePairer = remotePairer();
  
  // Controllers
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _customPortController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _customPortController.text = "8080"; // Default initial value
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _customPortController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)),
    );
  }

  /// Core logic to execute scanning
  Future<void> _executeScan(int port) async {
    setState(() {}); // Trigger UI to show LinearProgressIndicator
    await _remotePairer.autoPairScan(port);
    setState(() {}); // Stop progress indicator
    _showSnackBar('Scan on port $port completed');
  }

  /// Show port selection menu before scanning
  void _showPortSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Scan Port', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Choose a common port or enter a custom one:'),
            const SizedBox(height: 12),
            // Quick selection for common ports
            Wrap(
              spacing: 10,
              children: [8080, 8000, 3000, 5000].map((port) {
                return ChoiceChip(
                  label: Text(port.toString()),
                  selected: _customPortController.text == port.toString(),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _customPortController.text = port.toString());
                      Navigator.pop(context); // Close menu
                      _executeScan(port); // Start scanning
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Custom port input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customPortController,
                    decoration: const InputDecoration(
                      labelText: 'Custom Port',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(fixedSize: const Size(80, 55)),
                  onPressed: () {
                    final p = int.tryParse(_customPortController.text);
                    if (p != null && p > 0) {
                      Navigator.pop(context);
                      _executeScan(p);
                    }
                  },
                  child: const Text('Go'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final devices = _remotePairer.availableDevices;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Remote Devices'),
        centerTitle: true,
        bottom: _remotePairer.isScanning 
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4), 
                child: LinearProgressIndicator()) 
            : null,
      ),
      body: devices.isEmpty && !_remotePairer.isScanning
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: devices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final device = devices[index];
                final bool isPaired = device['ip'] == _remotePairer.pairedIp && 
                                    device['port'] == _remotePairer.pairedPort;
                return _buildDeviceTile(device['ip'], device['port'], isPaired);
              },
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 扫描按钮：现在点击会弹出端口选择
          FloatingActionButton.extended(
            heroTag: "scan",
            onPressed: _remotePairer.isScanning ? null : _showPortSelectionSheet,
            icon: _remotePairer.isScanning 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.radar),
            label: Text(_remotePairer.isScanning ? 'Scanning...' : 'Scan Network'),
            backgroundColor: _remotePairer.isScanning ? Colors.grey : Colors.blueAccent,
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: "add",
            onPressed: () => _showManualPairDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Manually'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.radar, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No devices found', style: TextStyle(color: Colors.grey, fontSize: 16)),
          const Text('Tap "Scan Network" to search nearby displays', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDeviceTile(String ip, int port, bool isPaired) {
    return Card(
      elevation: isPaired ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPaired ? BorderSide(color: Theme.of(context).primaryColor, width: 2) : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isPaired ? Colors.green : Colors.grey[200],
          child: Icon(Icons.settings_remote, color: isPaired ? Colors.white : Colors.grey),
        ),
        title: Text('$ip:$port', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(isPaired ? 'Currently Paired' : 'Tap to manage'),
        trailing: isPaired 
            ? IconButton(icon: const Icon(Icons.link_off, color: Colors.orange), onPressed: _confirmUnpair)
            : const Icon(Icons.chevron_right),
        onTap: () => isPaired ? null : _showDeviceOptions(ip, port),
      ),
    );
  }

  void _showDeviceOptions(String ip, int port) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device Actions'),
        content: Text('Would you like to connect to $ip:$port?'),
        actions: [
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () {
              _remotePairer.removeDevice(ip, port);
              Navigator.pop(context);
              setState(() {});
            },
          ),
          ElevatedButton(
            child: const Text('Pair'),
            onPressed: () async {
              Navigator.pop(context);
              if (await _remotePairer.pair(ip, port)) {
                _showSnackBar('Paired successfully');
                appNotifier?.updateAppState(appNotifier!.appState);
                setState(() {});
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmUnpair() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unpair Device'),
        content: const Text('Disconnect from the current display?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _remotePairer.unpair();
              appNotifier?.updateAppState(appNotifier!.appState);
              setState(() {});
            },
            child: const Text('Unpair', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _showManualPairDialog(BuildContext context) {
    _ipController.clear();
    _portController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Manually'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _ipController, decoration: const InputDecoration(labelText: 'IP Address')),
            TextField(controller: _portController, decoration: const InputDecoration(labelText: 'Port'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: _handleAddDevice, child: const Text('Add')),
        ],
      ),
    );
  }

  Future<void> _handleAddDevice() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 0;
    if (ip.isEmpty || port <= 0) return;

    Navigator.pop(context);
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
    
    bool available = await _remotePairer.isDeviceAvailable(ip, port);
    if (mounted) Navigator.pop(context);

    if (available) {
      _remotePairer.addDevice(ip, port);
      setState(() {});
    } else {
      _showSnackBar('Device unreachable');
    }
  }
}
