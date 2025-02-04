import 'package:flutter/material.dart';

final messangerKey = GlobalKey<ScaffoldMessengerState>();

void notify(String text) {
  final snackBar = SnackBar(
    content: Text(text),
    duration: const Duration(seconds: 2),
  );
  messangerKey.currentState!.showSnackBar(snackBar);
}
