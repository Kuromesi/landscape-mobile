import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:landscape/utils/utils.dart';

class GifPage extends StatefulWidget {
  @override
  _GifPageState createState() => _GifPageState();
}

class _GifPageState extends State<GifPage> with AutomaticKeepAliveClientMixin {
  List<PlatformFile>? _files = [];
  @override
  bool get wantKeepAlive => true;

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
            children: _files
                    ?.where((e) => e.path != null)
                    .map((e) => FullScreenWrapper.wrap(
                        Image.file(
                          File(e.path!),
                          fit: BoxFit.fitWidth,
                        ),
                        context))
                    .toList() ??
                [],
          ));
        }));
  }

  void _pickFiles() async {
    _files = (await FilePicker.platform.pickFiles(
      compressionQuality: 30,
      type: FileType.custom,
      allowMultiple: true,
      allowedExtensions: ['gif'],
      onFileLoading: (FilePickerStatus status) => print(status),
      lockParentWindow: false,
    ))
        ?.files;

    setState(() {
      _files = _files ?? [];
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
                          MediaQuery.of(context).size.width * 0.75, // 屏幕宽度的四分之三
                      child: ElevatedButton(
                        child: Text('Load Files'),
                        onPressed: () {
                          _pickFiles();
                        },
                      ),
                    ),
                    SizedBox(
                      width:
                          MediaQuery.of(context).size.width * 0.75, // 屏幕宽度的四分之三
                      child: ElevatedButton(
                        child: Text('Clear Cached Files'),
                        onPressed: () {
                          FilePicker.platform.clearTemporaryFiles();
                        },
                      ),
                    ),
                    SizedBox(
                      width:
                          MediaQuery.of(context).size.width * 0.75, // 屏幕宽度的四分之三
                      child: ElevatedButton(
                        child: Text('Play Gifs'),
                        onPressed: () {
                          print('Loading files...');
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
