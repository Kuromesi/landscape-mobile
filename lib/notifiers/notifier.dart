import 'package:flutter/material.dart';
import 'package:landscape/apis/apis.dart';
import 'package:landscape/constants/constants.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'dart:io';
import 'dart:convert';
import 'package:landscape/utils/network_scanner.dart';
import 'package:landscape/app.dart';

bool remoteControlEnabled = false;

RemoteAppNotifier? notifier;

AppNotifier? appNotifier;

ScrollTextNotifier? scrollTextNotifier;

GifNotifier? gifNotifier;

class RemoteAppNotifier extends ChangeNotifier {
  RemoteAppState conf = RemoteAppState(mode: 'scrollText');

  RemoteAppState get configuration => conf;

  void updateConfiguration(RemoteAppState newConfig) {
    conf = newConfig;
    notifyListeners();
  }

  void updateGifConfiguration(GifConfiguration newConfig) {
    conf.gifConfig = newConfig;
    notifyListeners();
  }

  void updateScrollTextConfiguration(ScrollTextConfiguration newConfig) {
    conf.scrollTextConfig = newConfig;
    notifyListeners();
  }

  void updateMode(String newMode) {
    conf.mode = newMode;
    notifyListeners();
  }
}

class AppNotifier extends ChangeNotifier {
  AppState _appState = AppState();

  AppState get appState => _appState;

  set appState(AppState newState) {
    _appState = newState;
  }

  void updateAppState(AppState newState) {
    _appState = newState;
    notifyListeners();
  }
}

class ScrollTextNotifier extends ChangeNotifier {
  ScrollTextConfiguration _scrollTextConfig = ScrollTextConfiguration(
    text: defaultScrollText,
    direction: "rtl",
    fontSize: 80,
    scrollSpeed: 1.0,
    fontColor: 0x00000000,
    adaptiveColor: true,
  );

  ScrollTextConfiguration get scrollTextConfig => _scrollTextConfig;

  set scrollTextConfig(ScrollTextConfiguration newConfig) {
    _scrollTextConfig = newConfig;
  }

  void updateScrollTextConfig(ScrollTextConfiguration newConfig) {
    _scrollTextConfig = newConfig;
    notifyListeners();
  }
}

class GifNotifier extends ChangeNotifier {
  GifConfiguration _gifConfig = GifConfiguration(
    frameRate: 15.0,
    filePaths: [],
    loop: true,
  );

  GifConfiguration get gifConfig => _gifConfig;

  set gifConfig(GifConfiguration newConfig) {
    _gifConfig = newConfig;
  }

  void updateGifConfig(GifConfiguration newConfig) {
    _gifConfig = newConfig;
    notifyListeners();
  }
}

RemoteNotifier remoteNotifier = RemoteNotifier();

class RemoteNotifier {
  final String _logTag = "RemoteNotifier";
  final RemotePairer _pairer = remotePairer();

  HttpClientRequest _decorateRequest(
      HttpClientRequest request, Map<String, dynamic> body) {
    request.headers.set('content-type', 'application/json');
    request.write(jsonEncode(body));
    return request;
  }

  Future<bool> checkConnectivity() async {
    scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text('Something wrong with remote device'),
      ),
    );
    return _pairer.isDeviceAvailable(_pairer.pairedIp, _pairer.pairedPort);
  }

  Future<void> updateAppState(AppState newState) async {
    try {
      HttpClient client = HttpClient();
      client.connectionTimeout = Duration(seconds: 1);
      HttpClientRequest request = await client.post(
          _pairer.pairedIp, _pairer.pairedPort, '/configure/app/full');
      _decorateRequest(request, newState.toJson());
      HttpClientResponse response = await request.close();
      if (response.statusCode != 200) {
        throw Exception("failed to update app state");
      }
    } catch (e) {
      FlutterLogs.logError(_logTag, "", e.toString());
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text(
              'Failed to update app config, please check remote device connectivity'),
        ),
      );
    }
  }

  Future<void> updateGifConfig(GifConfiguration newConfig) async {
    try {
      HttpClient client = HttpClient();
      client.connectionTimeout = Duration(seconds: 1);
      HttpClientRequest request = await client.post(
          _pairer.pairedIp, _pairer.pairedPort, '/configure/gif-player/full');
      _decorateRequest(request, newConfig.toJson());
      HttpClientResponse response = await request.close();
      if (response.statusCode != 200) {
        throw Exception("failed to update gif config");
      }
    } catch (e) {
      FlutterLogs.logError(_logTag, "", e.toString());
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text(
              'Failed to update gif config, please check remote device connectivity'),
        ),
      );
    }
  }

  Future<void> updateScrollTextConfig(ScrollTextConfiguration newConfig) async {
    try {
      HttpClient client = HttpClient();
      client.connectionTimeout = Duration(seconds: 1);
      HttpClientRequest request = await client.post(
          _pairer.pairedIp, _pairer.pairedPort, '/configure/scroll-text/full');
      _decorateRequest(request, newConfig.toJson());
      HttpClientResponse response = await request.close();
      if (response.statusCode != 200) {
        throw Exception("failed to update scroll text config");
      }
    } catch (e) {
      FlutterLogs.logError(_logTag, "", e.toString());
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text(
              'Failed to update scroll text config, please check remote device connectivity'),
        ),
      );
    }
  }
}
