import 'package:flutter/material.dart';
import 'package:landscape/app.dart';
import 'package:landscape/notifiers/notifier.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => RemoteAppNotifier()),
      ],
      child: MyApp(),
    ),);
}