import 'package:flutter/material.dart';
import 'package:landscape/players/gif.dart';
import 'package:landscape/players/scroll_text.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:landscape/players/error.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Landscape',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: const Landscape(),
    );
  }
}

class Landscape extends StatefulWidget {
  const Landscape({super.key});
  @override
  _LandscapeState createState() => _LandscapeState();
}


List<Widget> _pages = [ErrorPage(), GifPage(), ScrollTextPage()];

Map<String, int> _pagesMap = {
  'GIF': 1,
  'Scroll Text': 2,
};

class _LandscapeState extends State<Landscape> {
  bool _isDarkTheme = false;
  bool _keepScreenOn = false;
  int pageIndex = 1;
  PageController _pageController = PageController();

  void _toggleTheme() {
    setState(() {
      _isDarkTheme = !_isDarkTheme;
    });
  }

  void _showPage(String page) {
    setState(() {
      pageIndex = _pagesMap[page] ?? 0;
      _pageController.jumpToPage(pageIndex);
    });
  }

  void _toggleKeepScreenOn(BuildContext context) {
    _keepScreenOn = !_keepScreenOn;
    WakelockPlus.toggle(enable: _keepScreenOn);
    setState(() {
      _keepScreenOn = _keepScreenOn;
    });
    final snackBar = SnackBar(
      content: Text(_keepScreenOn ? 'Wakelock Enabled' : 'Wakelock Disabled'),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  void initState() {
    _pageController = PageController(initialPage: pageIndex);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: _isDarkTheme ? Colors.grey : Colors.purple,
        brightness: _isDarkTheme ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: _isDarkTheme ? Colors.black : Colors.white,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Landscape'),
          actions: [
            IconButton(
              icon:
                  Icon(_isDarkTheme ? Icons.wb_sunny : Icons.nightlight_round),
              onPressed: _toggleTheme,
            ),
            Builder(
              builder: (context) => IconButton(
                icon: Icon(_keepScreenOn ? Icons.lock : Icons.lock_open),
                onPressed: () => _toggleKeepScreenOn(context),
              ),
            )
          ],
        ),
        body: PageView(
          physics: NeverScrollableScrollPhysics(),
          controller: _pageController,
          children: _pages,
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: _isDarkTheme ? Colors.grey[800] : Colors.purple,
                ),
                child: const Text('Players'),
              ),
              ListTile(
                title: const Text('GIF'),
                onTap: () {
                  _showPage("GIF");
                },
              ),
              ListTile(
                title: const Text('Scroll Text'),
                onTap: () {
                  _showPage("Scroll Text");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}