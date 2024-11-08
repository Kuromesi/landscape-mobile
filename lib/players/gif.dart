import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gif_view/gif_view.dart';
import 'package:landscape/logs/notify.dart';

const double optionsBarWidth = 0.5;

class GifPage extends StatefulWidget {
  @override
  _GifPageState createState() => _GifPageState();
}

class _GifPageState extends State<GifPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<String> _filePaths = [];
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    FilePicker.platform.clearTemporaryFiles();
    _savePreferences();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    _filePaths = await _prefs.getStringList("files") ?? [];
    setState(() {
      _filePaths = _filePaths;
    });
  }

  Future<void> _savePreferences() async {
    _prefs.setStringList("files", _filePaths);
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
        floatingActionButton: FloatingActionButton(
          onPressed: () =>
              // {_pickFiles(), FilePicker.platform.clearTemporaryFiles()},
              {_showSettingsDialog(context)},
          child: Icon(Icons.add),
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
        notify(context, "File not found: $e");
        _filePaths.remove(e);
        continue;
      }
      Image image = Image.file(
        File(e),
        fit: BoxFit.fitWidth,
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
        builder: (context) => GifPlayer(gifs: _filePaths),
      ),
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
                        child: Text('Play Gifs'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _playGifs(context);
                        },
                      ),
                    ),
                    SizedBox(
                      width:
                          MediaQuery.of(context).size.width * optionsBarWidth,
                      child: ElevatedButton(
                        child: Text('Save Settings'),
                        onPressed: () {
                          _savePreferences();
                          notify(context, "Settings Saved");
                          Navigator.of(context).pop();
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

class GifPlayer extends StatefulWidget {
  final List<String> gifs;

  GifPlayer({Key? key, required this.gifs}) : super(key: key);

  @override
  State<GifPlayer> createState() => _GifPlayerState();
}

class _GifPlayerState extends State<GifPlayer> {
  late List<GifController> _gifControllerList;
  final List<GifView> _gifs = [];
  int _currentGif = 0;
  int _frameRate = 10;
  Duration _mustPlayAfter = Duration(seconds: 0);
  bool _next = true;

  late DateTime _startTime;
  @override
  void initState() {
    _gifControllerList = [];
    for (int i = 0; i < widget.gifs.length; i++) {
      try {
        FileImage image = FileImage(
          File(widget.gifs[i]),
        );
        GifController controller = GifController(
          onStart: () {
            if (_next) {
              _startTime = DateTime.now();
              _next = false;
            }
          },
          onFinish: () {
            if (DateTime.now().difference(_startTime) < _mustPlayAfter) {
              // start controller
              _gifControllerList[_currentGif].play();
              return;
            }
            if (!mounted) return;
            _next = true;
            setState(
              () {
                _currentGif = (_currentGif + 1) % _gifs.length;
              },
            );
          },
          loop: false,
        );
        _gifs.add(
          GifView(
            image: image,
            controller: controller,
            fit: BoxFit.fitWidth,
            repeat: ImageRepeat.noRepeat,
            frameRate: _frameRate,
          ),
        );
        _gifControllerList.add(controller);
      } catch (e) {
        print(e);
      }
    }
    super.initState();
  }

 // TODO: animation
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          Navigator.pop(
            context,
          );
        },
        child: _gifs.length != 0
            ? Container(
                key: ValueKey<int>(_currentGif),
                width: double.infinity,
                height: double.infinity,
                child: _gifs[_currentGif],
              )
            : Container(),
      ),
    );
  }
}
