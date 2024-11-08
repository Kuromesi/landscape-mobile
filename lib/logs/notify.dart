import 'package:flutter/material.dart';


void notify(BuildContext context, String text) {
  final snackBar = SnackBar(
      content: Text(text),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
