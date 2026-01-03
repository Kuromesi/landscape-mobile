import 'package:flutter/material.dart';
import 'package:landscape/app.dart';
import 'package:landscape/notifiers/notifier.dart';
import 'package:provider/provider.dart';
import 'package:flutter_logs/flutter_logs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLogs();

  final remoteAppNotifier = RemoteAppNotifier();
  final appNotifierInstance = AppNotifier();
  final gifNotifierInstance = GifNotifier();
  final scrollTextNotifierInstance = ScrollTextNotifier();

  // Set the global variables before initializing the app
  notifier = remoteAppNotifier;
  appNotifier = appNotifierInstance;
  gifNotifier = gifNotifierInstance;
  scrollTextNotifier = scrollTextNotifierInstance;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: remoteAppNotifier),
        ChangeNotifierProvider.value(value: appNotifierInstance),
        ChangeNotifierProvider.value(value: gifNotifierInstance),
        ChangeNotifierProvider.value(value: scrollTextNotifierInstance),
      ],
      child: MyApp(),
    ),
  );
}

Future<void> setupLogs() async {
  // Initialize Logging
  await FlutterLogs.initLogs(
    logLevelsEnabled: [
      LogLevel.INFO,
      LogLevel.WARNING,
      LogLevel.ERROR,
      LogLevel.SEVERE
    ],
    timeStampFormat: TimeStampFormat.TIME_FORMAT_READABLE,
    directoryStructure: DirectoryStructure.FOR_DATE,
    logTypesEnabled: ["device", "network", "errors"],
    logFileExtension: LogFileExtension.LOG,
    logsWriteDirectoryName: "LandscapeLogs",
    logsExportDirectoryName: "LandscapeLogs/Exported",
    debugFileOperations: true,
    isDebuggable: true,
    enabled: true,
  );
}