import 'package:flutter/material.dart';
import 'package:landscape/remote/apis/scroll_text.dart';

ScrollTextNotifier? notifier;

class ScrollTextNotifier extends ChangeNotifier {
  ScrollTextConfiguration _configuration =
      ScrollTextConfiguration(text: '');

  ScrollTextConfiguration get configuration => _configuration;

  void updateConfiguration(ScrollTextConfiguration newConfig) {
    _configuration = newConfig;
    notifyListeners();
  } 
}
