import 'package:flutter/material.dart';
import 'package:landscape/apis/apis.dart';
import 'package:landscape/constants/constants.dart';

bool remoteControlEnabled = false;

RemoteAppNotifier? notifier;

AppNotifier? appNotifier;

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
  
  GifConfiguration _gifConfig = GifConfiguration(
    frameRate: 15.0,
    filePaths: [],
    loop: true,
  );

  ScrollTextConfiguration _scrollTextConfig = ScrollTextConfiguration(
    text: defaultScrollText,
    direction: "rtl",
    fontSize: 80,
    scrollSpeed: 1.0,
    fontColor: 0x00000000,
    adaptiveColor: true,
  );

  AppState get appState => _appState;
  GifConfiguration get gifConfig => _gifConfig;
  ScrollTextConfiguration get scrollTextConfig => _scrollTextConfig;

  set appState(AppState newState) {
    _appState = newState;
  }

  set gifConfig(GifConfiguration newConfig) {
    _gifConfig = newConfig;
  }

  set scrollTextConfig(ScrollTextConfiguration newConfig) {
    _scrollTextConfig = newConfig;
  }

  void updateAppState(AppState newState) {
    _appState = newState;
    notifyListeners();
  }

  void updateGifConfig(GifConfiguration newConfig) {
    _gifConfig = newConfig;
    notifyListeners();
  }

  void updateScrollTextConfig(ScrollTextConfiguration newConfig) {
    _scrollTextConfig = newConfig;
    notifyListeners();
  }

}