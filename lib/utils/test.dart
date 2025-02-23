import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only call clearSavedSettings() during testing to reset internal values.
  await Upgrader.clearSavedSettings(); // REMOVE this for release builds

  // On Android, the default behavior will be to use the Google Play Store
  // version of the app.
  // On iOS, the default behavior will be to use the App Store version of
  // the app, so update the Bundle Identifier in example/ios/Runner with a
  // valid identifier already in the App Store.
  runApp(const MyApp());
}

const appcastURL =
    'https://raw.githubusercontent.com/larryaasen/upgrader/master/test/testappcast.xml';
final upgrader = Upgrader(
  storeController: UpgraderStoreController(
    onAndroid: () => UpgraderAppcastStore(appcastURL: appcastURL),
  ),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  

  @override
  Widget build(BuildContext context) {
  return MaterialApp(
    title: 'Upgrader Example',
    home: Scaffold(
        appBar: AppBar(title: Text('Upgrader Appcast Example')),
        body: UpgradeAlert(
          upgrader: upgrader,
          child: Center(child: Text('Checking...')),
        )),
  );
}
}