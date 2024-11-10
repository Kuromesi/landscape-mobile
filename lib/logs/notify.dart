import 'package:flutter/material.dart';

final _messangerKey = GlobalKey<ScaffoldMessengerState>();

void notify(String text) {
  final snackBar = SnackBar(
    content: Text(text),
    duration: const Duration(seconds: 2),
  );
  _messangerKey.currentState!.showSnackBar(snackBar);
}
