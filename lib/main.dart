import 'package:flutter/material.dart';
import 'package:landscape/app.dart';
import 'package:landscape/notifiers/notifier.dart';
import 'package:provider/provider.dart';
import 'package:flutter_logs/flutter_logs.dart';

void main() {
  setupLogs();
  runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => RemoteAppNotifier()),
        ChangeNotifierProvider(create: (context) => AppNotifier()),
        ChangeNotifierProvider(create: (context) => GifNotifier()),
        ChangeNotifierProvider(create: (context) => ScrollTextNotifier()),
      ],
      child: MyApp(),
    ),);
}

Future<void> setupLogs() async {
  WidgetsFlutterBinding.ensureInitialized();

     //Initialize Logging
     await FlutterLogs.initLogs(
     logLevelsEnabled: [
       LogLevel.INFO,
       LogLevel.WARNING,
       LogLevel.ERROR,
       LogLevel.SEVERE
     ],
     timeStampFormat: TimeStampFormat.TIME_FORMAT_READABLE,
     directoryStructure: DirectoryStructure.FOR_DATE,
     logTypesEnabled: ["device","network","errors"],
     logFileExtension: LogFileExtension.LOG,
     logsWriteDirectoryName: "LandscapeLogs",
     logsExportDirectoryName: "LandscapeLogs/Exported",
     debugFileOperations: true,
     isDebuggable: true,
             enabled: true);
}