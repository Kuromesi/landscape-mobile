import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:landscape/apis/gif.dart';
import 'package:landscape/notifiers/notifier.dart';
import 'package:landscape/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:landscape/players/players.dart';
import 'package:landscape/apis/apis.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:provider/provider.dart';

class GifPage extends StatefulWidget {
  @override
  _GifPageState createState() => _GifPageState();
}

class _GifPageState extends State<GifPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late GifConfiguration _conf;
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  @override
  void initState() {
    super.initState();
    // Default configuration initialization
    _conf = GifConfiguration(frameRate: 15.0, filePaths: [], loop: true);
    
    _loadPreferences();
    configDump[configGif] = exportState;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gifNotifier = Provider.of<GifNotifier>(context, listen: false);
      gifNotifier.addListener(_onNotifierUpdate);
      gifNotifier.updateGifConfig(_conf);
    });
  }

  @override
  void dispose() {
    configDump.remove(configGif);
    _savePreferences();
    Provider.of<GifNotifier>(context, listen: false).removeListener(_onNotifierUpdate);
    super.dispose();
  }

  JsonSerializable exportState() => _conf;

  void _onNotifierUpdate() {
    if (mounted) {
      setState(() {
        _conf = Provider.of<GifNotifier>(context, listen: false).gifConfig;
      });
    }
  }

  /// Updates provider and persists settings to local storage
  void _notifyAndSave() {
    final gifNotifier = Provider.of<GifNotifier>(context, listen: false);
    gifNotifier.updateGifConfig(_conf);
    _savePreferences();
  }

  Future<void> _loadPreferences() async {
    final paths = await _prefs.getStringList("files") ?? [];
    // Filter out non-existent files during load to keep the list clean
    final existingPaths = paths.where((p) => File(p).existsSync()).toList();
    
    setState(() {
      _conf.filePaths = existingPaths;
      _conf.frameRate = 15.0; // Fallback or handle separately
    });
    
    // Attempt to load numeric values safely
    final savedRate = await _prefs.getDouble("frameRate");
    final savedLoop = await _prefs.getBool("loop");
    
    setState(() {
      if (savedRate != null) _conf.frameRate = savedRate;
      if (savedLoop != null) _conf.loop = savedLoop;
    });
    
    _notifyAndSave();
  }

  Future<void> _savePreferences() async {
    if (remotePairer().remoteControlEnabled) {
      return;
    }
    await _prefs.setStringList("files", _conf.filePaths ?? []);
    await _prefs.setDouble("frameRate", _conf.frameRate ?? 15.0);
    await _prefs.setBool("loop", _conf.loop ?? true);
  }

  /// Opens file picker to select multiple GIF files
  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: true,
      allowedExtensions: ['gif'],
    );

    if (result == null || result.files.isEmpty) return;

    final newPaths = result.files
        .where((f) => f.path != null)
        .map((f) => f.path!)
        .toList();

    setState(() {
      // Append new paths to existing list, avoiding duplicates if necessary
      _conf.filePaths = [...?_conf.filePaths, ...newPaths].toSet().toList();
    });
    
    _notifyAndSave();
  }

  /// Removes all files and temporary cache
  void _clearAllFiles() {
    FilePicker.platform.clearTemporaryFiles();
    setState(() {
      _conf.filePaths = [];
    });
    _notifyAndSave();
  }

  // --- UI Components ---

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      body: _conf.filePaths == null || _conf.filePaths!.isEmpty
          ? _buildEmptyState()
          : _buildGallery(isLandscape),
      floatingActionButton: _buildActionButtons(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.gif_box_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text("No GIFs loaded", style: TextStyle(color: Colors.grey[600], fontSize: 18)),
          TextButton(onPressed: _pickFiles, child: const Text("Tap to select files")),
        ],
      ),
    );
  }

  Widget _buildGallery(bool isLandscape) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      scrollDirection: isLandscape ? Axis.horizontal : Axis.vertical,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isLandscape ? 1 : 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: _conf.filePaths!.length,
      itemBuilder: (context, index) => _buildImageTile(_conf.filePaths![index]),
    );
  }

  Widget _buildImageTile(String path) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _viewFullScreen(path),
          child: Hero(
            tag: path,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover),
              ),
            ),
          ),
        ),
        // Delete button overlay
        Positioned(
          top: 4, right: 4,
          child: GestureDetector(
            onTap: () {
              setState(() => _conf.filePaths!.remove(path));
              _notifyAndSave();
            },
            child: Container(
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  void _viewFullScreen(String path) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Center(
            child: Hero(tag: path, child: Image.file(File(path), fit: BoxFit.contain)),
          ),
        ),
      );
    }));
  }

  Widget _buildActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: "play_gif",
          onPressed: () {
            if (_conf.filePaths?.isNotEmpty == true) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => 
                MultiGifPlayer(gifs: _conf.filePaths!, frameRate: _conf.frameRate!.round())));
            }
          },
          child: const Icon(Icons.play_arrow),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          heroTag: "gif_settings",
          onPressed: () => _showMainSettings(),
          child: const Icon(Icons.menu),
        ),
      ],
    );
  }

  // --- Dialogs ---

  void _showMainSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: const Text("Load Files"),
              onTap: () { Navigator.pop(ctx); _pickFiles(); },
            ),
            ListTile(
              leading: const Icon(Icons.speed),
              title: const Text("Frame Rate Settings"),
              onTap: () { Navigator.pop(ctx); _showFrameRateSettings(); },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_sweep, color: Colors.red),
              title: const Text("Clear All", style: TextStyle(color: Colors.red)),
              onTap: () { Navigator.pop(ctx); _clearAllFiles(); },
            ),
          ],
        ),
      ),
    );
  }

  void _showFrameRateSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, innerSetState) => Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Frame Rate: ${_conf.frameRate!.round()} FPS", style: const TextStyle(fontSize: 18)),
              Slider(
                value: _conf.frameRate!,
                min: 5, max: 60, divisions: 55,
                label: _conf.frameRate!.round().toString(),
                onChanged: (val) {
                  innerSetState(() => _conf.frameRate = val);
                  setState(() {}); // Update parent for immediate preview
                  _notifyAndSave();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
