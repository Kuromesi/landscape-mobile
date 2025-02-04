import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:landscape/pages/gif.dart';
import 'package:landscape/pages/scroll_text.dart';
import 'package:landscape/remote/http.dart';
import 'package:landscape/remote/remote.dart';
import 'package:upgrader/upgrader.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:landscape/pages/error.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:landscape/notifiers/notifier.dart';
import 'package:landscape/utils/utils.dart';
import 'apis/apis.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    notifier = Provider.of<RemoteAppNotifier>(context, listen: false);
    appNotifier = Provider.of<AppNotifier>(context, listen: false);
    gifNotifier = Provider.of<GifNotifier>(context, listen: false);
    scrollTextNotifier = Provider.of<ScrollTextNotifier>(context, listen: false);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    return const Landscape();
  }
}

class Landscape extends StatefulWidget {
  const Landscape({super.key});
  @override
  _LandscapeState createState() => _LandscapeState();
}

Map<String, int> routePageMap = {
  '/gif': 1,
  '/scroll-text': 2,
  '/remote-server': 3,
  '/remote-client': 4,
};

Map<int, String> pageRouteMap = {
  1: '/gif',
  2: '/scroll-text',
  3: '/remote-server',
  4: '/remote-client',
};

class _LandscapeState extends State<Landscape> {
  AppState _conf = AppState();
  int _pageIndex = 1;
  final List<Widget> _pages = [
    ErrorPage(),
    GifPage(),
    ScrollTextPage(),
    RemoteHttpServerPage(),
    LandscapeClient(),
  ];

  PageController _pageController = PageController(initialPage: 1);
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  @override
  void initState() {
    _loadPreferences();
    _conf.isDarkTheme = false;
    _conf.keepScreenOn = false;
    _conf.currentPage = pageRouteMap[_pageIndex];
    configDump['landscape'] = exportState;
    appNotifier!.addListener(listener);
    appNotifier!.appState = _conf;
    super.initState();
  }

  JsonSerializable exportState() {
    return _conf;
  }

  @override
  void dispose() {
    _savePreferences();
    // remove key from config dump map
    configDump.remove('landscape');
    _pageController.dispose();
    appNotifier!.removeListener(listener);
    super.dispose();
  }

  void listener() {
    if (mounted) {
      setState(() {
        _conf = appNotifier!.appState;
      });
      _pageIndex = routePageMap[_conf.currentPage] ?? 0;
      _pageController.jumpToPage(_pageIndex);
      WakelockPlus.toggle(enable: _conf.keepScreenOn!);
    }
  }

  Future<void> _loadPreferences() async {
    _conf.isDarkTheme = await _prefs.getBool('isDarkTheme') ?? false;
    _conf.keepScreenOn = await _prefs.getBool('keepScreenOn') ?? false;
    _conf.isDarkTheme = _conf.isDarkTheme;
    _conf.keepScreenOn = _conf.keepScreenOn;
    appNotifier!.updateAppState(_conf);
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isDarkTheme", _conf.isDarkTheme!);
    await prefs.setBool("keepScreenOn", _conf.keepScreenOn!);
  }

  void _toggleTheme() {
    _conf.isDarkTheme = !_conf.isDarkTheme!;
    rerender();
    _prefs.setBool("isDarkTheme", _conf.isDarkTheme!);
  }

  void rerender() {
    appNotifier!.updateAppState(_conf);
    if (remotePairer().remoteControlEnabled) {
      remoteNotifier.updateAppState(_conf);
    }
  }

  void _showPage(String page) {
    _pageIndex = routePageMap[page] ?? 0;
    _conf.currentPage = pageRouteMap[_pageIndex];
    rerender();
  }

  void _toggleKeepScreenOn(BuildContext context) {
    _conf.keepScreenOn = !_conf.keepScreenOn!;
    WakelockPlus.toggle(enable: _conf.keepScreenOn!);
    _conf.keepScreenOn = _conf.keepScreenOn;
    rerender();
    final snackBar = SnackBar(
      content:
          Text(_conf.keepScreenOn! ? 'Wakelock Enabled' : 'Wakelock Disabled'),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _toggleRemoteControl() {
    RemotePairer p = remotePairer();
    if (!p.remoteControlEnabled) {
      if (!p.paired) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Must pair a remote device first'),
          ),
        );
        return;
      }
      p.enableRemoteControl();
    } else {
      p.disableRemoteControl();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: ThemeData(
        primarySwatch: _conf.isDarkTheme! ? Colors.grey : Colors.purple,
        brightness: _conf.isDarkTheme! ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor:
            _conf.isDarkTheme! ? Colors.black : Colors.white,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Landscape'),
          actions: [
            GestureDetector(
              onLongPress: () {
                final pairedIp = remotePairer().pairedIp;
                final pairedPort = remotePairer().pairedPort;
                final snackBar = SnackBar(
                  content: Text('Paired device: $pairedIp:$pairedPort'),
                  duration: const Duration(seconds: 3),
                );
                scaffoldMessengerKey.currentState?.showSnackBar(snackBar);
              },
              child: IconButton(
                icon: remotePairer().remoteControlEnabled
                    ? Icon(Icons.wifi)
                    : Icon(Icons.wifi_off),
                onPressed: _toggleRemoteControl,
              ),
            ),
            IconButton(
              icon: Icon(
                  _conf.isDarkTheme! ? Icons.wb_sunny : Icons.nightlight_round),
              onPressed: _toggleTheme,
            ),
            Builder(
              builder: (context) => IconButton(
                icon: Icon(_conf.keepScreenOn! ? Icons.lock : Icons.lock_open),
                onPressed: () => _toggleKeepScreenOn(context),
              ),
            ),
          ],
        ),
        body: UpgradeAlert(
          upgrader: upgrader,
          child: PageView(
            physics: NeverScrollableScrollPhysics(),
            controller: _pageController,
            children: _pages,
          ),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: _conf.isDarkTheme! ? Colors.grey[800] : Colors.purple,
                ),
                child: const Text('Players'),
              ),
              ListTile(
                title: const Text('GIF'),
                onTap: () {
                  _showPage("/gif");
                },
              ),
              ListTile(
                title: const Text('Scroll Text'),
                onTap: () {
                  _showPage("/scroll-text");
                },
              ),
              ListTile(
                title: const Text('Remote Server'),
                onTap: () {
                  _showPage("/remote-server");
                },
              ),
              ListTile(
                title: const Text('Remote Client'),
                onTap: () {
                  _showPage("/remote-client");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
