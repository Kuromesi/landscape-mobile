import 'package:flutter/material.dart';
import 'package:landscape/apis/apis.dart';

RemoteAppNotifier? notifier;

class RemoteAppNotifier extends ChangeNotifier {

  RemoteAppState conf = RemoteAppState(
      mode: 'scrollText');

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
