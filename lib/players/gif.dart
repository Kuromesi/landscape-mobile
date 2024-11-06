import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:landscape/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GifPage extends StatefulWidget {
  @override
  _GifPageState createState() => _GifPageState();
}

class _GifPageState extends State<GifPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<PlatformFile>? _files = [];
  List<String> _fileNames = [];
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
    _fileNames = await _prefs.getStringList("files") ?? [];
    setState(() {
      _fileNames = _fileNames;
    });
  }

  Future<void> _savePreferences() async {
    _prefs.setStringList("files", _fileNames);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: FloatingActionButton(
          onPressed: () =>
              // {_pickFiles(), FilePicker.platform.clearTemporaryFiles()},
              {_showSettingsDialog()},
          child: Icon(Icons.add),
        ),
        body: OrientationBuilder(builder: (context, orientation) {
          return Center(
              child: ListView(
            scrollDirection: orientation == Orientation.landscape
                ? Axis.horizontal
                : Axis.vertical,
            children: _fileNames
                    .map((e) => FullScreenWrapper.wrap(
                        Image.file(
                          File(e),
                          fit: BoxFit.fitWidth,
                        ),
                        context))
                    .toList() ??
                [],
          ));
        }));
  }

  Future<void> _pickFiles() async {
    _files = (await FilePicker.platform.pickFiles(
      compressionQuality: 30,
      type: FileType.custom,
      allowMultiple: true,
      allowedExtensions: ['gif'],
      onFileLoading: (FilePickerStatus status) => print(status),
      lockParentWindow: false,
    ))
        ?.files;

    _fileNames = [];
    if (_files != null) {
      for (var file in _files!) {
        if (file.path != null) {
          _fileNames.add(file.path!);
        }
      }
    }
    setState(() {
      _fileNames = _fileNames;
    });
  }

  void _showSettingsDialog() {
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
                          MediaQuery.of(context).size.width * 0.75,
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
                          MediaQuery.of(context).size.width * 0.75,
                      child: ElevatedButton(
                        child: Text('Clear Cached Files'),
                        onPressed: () {
                          FilePicker.platform.clearTemporaryFiles();
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    SizedBox(
                      width:
                          MediaQuery.of(context).size.width * 0.75,
                      child: ElevatedButton(
                        child: Text('Play Gifs'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          print('Loading files...');
                        },
                      ),
                    ),
                    SizedBox(
                      width:
                          MediaQuery.of(context).size.width * 0.75,
                      child: ElevatedButton(
                        child: Text('Save Settings'),
                        onPressed: () {
                          _savePreferences();
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
