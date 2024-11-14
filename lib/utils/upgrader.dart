import 'package:upgrader/upgrader.dart';

const appcastURL =
    'https://raw.githubusercontent.com/kuromesi/landscape-mobile/master/appcast.xml';

final upgrader = Upgrader(
  storeController: UpgraderStoreController(
    onAndroid: () => UpgraderAppcastStore(appcastURL: appcastURL),
  ),
);
