import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:landscape/apis/gif.dart';
import 'package:landscape/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:landscape/constants/constants.dart';
import 'package:landscape/players/players.dart';
import 'package:landscape/apis/apis.dart';
import 'package:json_annotation/json_annotation.dart';


class GifPage extends StatefulWidget {
  @override
  _GifPageState createState() => _GifPageState();
}

class _GifPageState extends State<GifPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final GifConfiguration _conf = GifConfiguration(
    frameRate: 15.0,
    filePaths: [],
    loop: true,
  );

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  @override
  void initState() {
    super.initState();
    configDump[configGif] = exportState;
    _loadPreferences();
  }

  @override
  void dispose() {
    configDump.remove(configGif);
    _savePreferences();
    super.dispose();
  }

  JsonSerializable exportState() {
    return _conf;
  }

  Future<void> _loadPreferences() async {
    _conf.filePaths = await _prefs.getStringList("files") ?? [];
    _conf.frameRate = await _prefs.getDouble("frameRate") ?? 15.0;
    _conf.loop = await _prefs.getBool("loop") ?? true;
    setState(() {});
  }

  Future<void> _savePreferences() async {
    _prefs.setStringList("files", _conf.filePaths!);
    _prefs.setDouble("frameRate", _conf.frameRate!);
    _prefs.setBool("loop", _conf.loop!);
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
        _conf.filePaths!.remove(path);
        setState(() {});
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
            children: _buildImagesPreview(_conf.filePaths!, context),
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
            MultiGifPlayer(gifs: _conf.filePaths!, frameRate: _conf.frameRate!.round()),
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
                    Text("Frame Rate - ${_conf.frameRate!.round().toString()}"),
                    Slider(
                      value: _conf.frameRate!,
                      min: 5,
                      max: 60,
                      divisions: 55,
                      label: _conf.frameRate!.round().toString(),
                      onChanged: (value) {
                        innerSetState(() {
                          _conf.frameRate = value;
                        });
                        setState(() {});
                      },
                      onChangeEnd: (value) =>
                          _prefs.setDouble("frameRate", _conf.frameRate!),
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
    paths.insertAll(0, _conf.filePaths!);
    setState(() {
      _conf.filePaths = paths;
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
                            _conf.filePaths = [];
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
