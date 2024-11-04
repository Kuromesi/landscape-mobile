import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// class MyFilePicker extends StatefulWidget {
//   @override
//   _MyFilePickerState createState() => _MyFilePickerState();
// }

// class _MyFilePickerState extends State<MyFilePicker> {
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//   final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
//   final _defaultFileNameController = TextEditingController();
//   final _dialogTitleController = TextEditingController();
//   final _initialDirectoryController = TextEditingController();
//   final _fileExtensionController = TextEditingController();
//   String? _fileName;
//   String? _saveAsFileName;
//   List<PlatformFile>? _paths;
//   String? _directoryPath;
//   String? _extension;
//   bool _isLoading = false;
//   bool _lockParentWindow = false;
//   bool _userAborted = false;
//   bool _multiPick = false;
//   FileType _pickingType = FileType.any;

//   @override
//   Widget build(BuildContext context) {}

//   void _pickFiles() async {
//     try {
//       _paths = (await FilePicker.platform.pickFiles(
//         compressionQuality: 30,
//         type: _pickingType,
//         allowMultiple: true,
//         onFileLoading: (FilePickerStatus status) => print(status),
//         allowedExtensions: (_extension?.isNotEmpty ?? false)
//             ? _extension?.replaceAll(' ', '').split(',')
//             : null,
//         dialogTitle: _dialogTitleController.text,
//         initialDirectory: _initialDirectoryController.text,
//         lockParentWindow: _lockParentWindow,
//       ))
//           ?.files;
//     } on PlatformException catch (e) {
//       _logException('Unsupported operation' + e.toString());
//     } catch (e) {
//       _logException(e.toString());
//     }
//   }

//   void _logException(String message) {
//     print(message);
//     _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
//     _scaffoldMessengerKey.currentState?.showSnackBar(
//       SnackBar(
//         content: Text(
//           message,
//           style: const TextStyle(
//             color: Colors.white,
//           ),
//         ),
//       ),
//     );
//   }

// }

class MyFilePicker {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final _defaultFileNameController = TextEditingController();
  final _dialogTitleController = TextEditingController();
  final _initialDirectoryController = TextEditingController();
  final _fileExtensionController = TextEditingController();
  String? _fileName;
  String? _saveAsFileName;
  List<PlatformFile>? _paths;
  String? _directoryPath;
  String? _extension;
  bool _isLoading = false;
  bool _lockParentWindow = false;
  bool _userAborted = false;
  bool _multiPick = false;
  FileType _pickingType = FileType.any;

  MyFilePicker(FileType _pickingType) {
    this._pickingType = _pickingType;
  }

  void pickFiles() async {
    try {
      _paths = (await FilePicker.platform.pickFiles(
        compressionQuality: 30,
        type: _pickingType,
        allowMultiple: true,
        onFileLoading: (FilePickerStatus status) => print(status),
        allowedExtensions: (_extension?.isNotEmpty ?? false)
            ? _extension?.replaceAll(' ', '').split(',')
            : null,
        dialogTitle: _dialogTitleController.text,
        initialDirectory: _initialDirectoryController.text,
        lockParentWindow: _lockParentWindow,
      )) ?.files;
    } on PlatformException catch (e) {
      _logException('Unsupported operation' + e.toString());
    } catch (e) {
      _logException(e.toString());
    }
  }

  void _logException(String message) {
    print(message);
    _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  List<PlatformFile>? getFiles() {
    return _paths;
  }
}
