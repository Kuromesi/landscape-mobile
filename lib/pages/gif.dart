import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:landscape/constants/constants.dart';
import 'package:landscape/players/players.dart';

class GifPage extends StatefulWidget {
  @override
  _GifPageState createState() => _GifPageState();
}

class _GifPageState extends State<GifPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<String> _filePaths = [];
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  // gif player configuration
  double _frameRate = 15.0;
  bool _loop = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _savePreferences();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    _filePaths = await _prefs.getStringList("files") ?? [];
    _frameRate = await _prefs.getDouble("frameRate") ?? 15.0;
    _loop = await _prefs.getBool("loop") ?? true;
    setState(() {
      _filePaths = _filePaths;
      _frameRate = _frameRate;
      _loop = _loop;
    });
  }

  Future<void> _savePreferences() async {
    _prefs.setStringList("files", _filePaths);
    _prefs.setDouble("frameRate", _frameRate);
    _prefs.setBool("loop", _loop);
  }

  Future<void> _resetPreferences() async {
    _prefs.setStringList("files", []);
  }

  GestureDetector _imagePreviewWrapper(
      Image image, String path, BuildContext context) {
    GestureDetector gd = GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              body: Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(
                      context,
                    );
                  },
                  child: Container(
                    child: image,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ),
          ),
        );
      },
      onDoubleTap: () {
        _filePaths.remove(path);
        setState(() {
          _filePaths = _filePaths;
        });
      },
      child: image,
    );
    return gd;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: "play_gif",
              onPressed: () => {_playGifs(context)},
              child: Icon(Icons.play_arrow),
            ),
            SizedBox(height: 16),
            FloatingActionButton(
              heroTag: "settings",
              onPressed: () => {_showSettingsDialog(context)},
              child: Icon(Icons.menu),
            ),
          ],
        ),
        body: OrientationBuilder(builder: (context, orientation) {
          return Center(
              child: ListView(
            scrollDirection: orientation == Orientation.landscape
                ? Axis.horizontal
                : Axis.vertical,
            children: _buildImagesPreview(_filePaths, context),
          ));
        }));
  }

  List<Widget> _buildImagesPreview(
      List<String> _filePaths, BuildContext context) {
    List<GestureDetector> images = [];
    List<String> filePaths = _filePaths.toList();
    for (String e in filePaths) {
      if (!File(e).existsSync()) {
        _filePaths.remove(e);
        continue;
      }
      Image image = Image.file(
        File(e),
        fit: MediaQuery.of(context).orientation == Orientation.landscape
            ? BoxFit.fitWidth
            : BoxFit.fitHeight,
      );
      GestureDetector gd = _imagePreviewWrapper(image, e, context);
      images.add(gd);
    }
    _prefs.setStringList("files", _filePaths);
    return images;
  }

  void _playGifs(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MultiGifPlayer(gifs: _filePaths, frameRate: _frameRate.round()),
      ),
    );
  }

  void _configureGifPlay(BuildContext context) {
    showModalBottomSheet(
      // fix when using keyboard this panel will be hided
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          // fix when using keyboard this panel will be hided
          padding: MediaQuery.of(context).viewInsets,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter innerSetState) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Frame Rate - ${_frameRate.round().toString()}"),
                    Slider(
                      value: _frameRate,
                      min: 5,
                      max: 60,
                      divisions: 55,
                      label: _frameRate.round().toString(),
                      onChanged: (value) {
                        innerSetState(() {
                          _frameRate = value;
                        });
                        setState(() {
                          _frameRate = _frameRate;
                        });
                      },
                      onChangeEnd: (value) => _prefs.setDouble("frameRate", _frameRate),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _pickFiles() async {
    List<PlatformFile>? files = (await FilePicker.platform.pickFiles(
      compressionQuality: 30,
      type: FileType.custom,
      allowMultiple: true,
      allowedExtensions: ['gif'],
      onFileLoading: (FilePickerStatus status) => print(status),
      lockParentWindow: false,
    ))
        ?.files;

    // filter empty files
    if (files == null) {
      return;
    }

    files = files.where((element) => element.path != null).toList();
    List<String> paths = files.map((e) => e.path!).toList();
    paths.insertAll(0, _filePaths);
    setState(() {
      _filePaths = paths;
    });
    _savePreferences();
  }

  void _showSettingsDialog(BuildContext context) {
    showModalBottomSheet(
      // fix when using keyboard this panel will be hided
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          // fix when using keyboard this panel will be hided
          padding: MediaQuery.of(context).viewInsets,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter innerSetState) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width:
                          MediaQuery.of(context).size.width * optionsBarWidth,
                      child: ElevatedButton(
                        child: Text('Load Files'),
                        onPressed: () {
                          _pickFiles();
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    SizedBox(
                      width:
                          MediaQuery.of(context).size.width * optionsBarWidth,
                      child: ElevatedButton(
                        child: Text('Clear All'),
                        onPressed: () {
                          FilePicker.platform.clearTemporaryFiles();
                          setState(() {
                            _filePaths = [];
                          });
                          _resetPreferences();
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    SizedBox(
                      width:
                          MediaQuery.of(context).size.width * optionsBarWidth,
                      child: ElevatedButton(
                        child: Text('Configuration'),
                        onPressed: () {
                          _configureGifPlay(context);
                          // Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
