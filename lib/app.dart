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

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    return const Landscape();
  }
}

class Landscape extends StatefulWidget {
  const Landscape({super.key});
  @override
  State<Landscape> createState() => _LandscapeState();
}

const Map<String, int> routePageMap = {'/error': 0, '/gif': 1, '/scroll-text': 2, '/remote-server': 3, '/remote-client': 4};
const Map<int, String> pageRouteMap = {0: '/error', 1: '/gif', 2: '/scroll-text', 3: '/remote-server', 4: '/remote-client'};

class _LandscapeState extends State<Landscape> {
  late AppState _conf;
  late PageController _pageController;
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  @override
  void initState() {
    super.initState();
    _conf = AppState(currentPage: pageRouteMap[1], isDarkTheme: false, keepScreenOn: false);
    _pageController = PageController(initialPage: 1);
    _loadPreferences();
    configDump['landscape'] = exportState;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appNotifier = Provider.of<AppNotifier>(context, listen: false);
      appNotifier.addListener(listener);
      appNotifier.updateAppState(_conf);
    });
  }

  JsonSerializable exportState() => _conf;

  void listener() {
    if (!mounted) return;
    final appNotifier = Provider.of<AppNotifier>(context, listen: false);
    final newConf = appNotifier.appState;
    setState(() { _conf = newConf; });

    final pageIndex = routePageMap[newConf.currentPage] ?? 0;
    if (pageIndex != _pageController.page?.round()) {
      _pageController.animateToPage(pageIndex, duration: const Duration(milliseconds: 400), curve: Curves.easeInOutCubic);
    }
    WakelockPlus.toggle(enable: newConf.keepScreenOn ?? false);
  }

  Future<void> _loadPreferences() async {
    final isDark = await _prefs.getBool('isDarkTheme') ?? false;
    final screenOn = await _prefs.getBool('keepScreenOn') ?? false;
    final newState = AppState(currentPage: _conf.currentPage, isDarkTheme: isDark, keepScreenOn: screenOn);
    setState(() => _conf = newState);
    Provider.of<AppNotifier>(context, listen: false).updateAppState(newState);
  }

  /// Global state update wrapper
  void _updateGlobalState() {
    setState(() => _conf = appNotifier!.appState);
    if (remotePairer().remoteControlEnabled) remoteNotifier.updateAppState(appNotifier!.appState);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _conf.isDarkTheme ?? false;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: isDark ? Colors.cyanAccent : Colors.deepPurple,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      home: LandscapeHomeScreen(
        conf: _conf,
        pageController: _pageController,
        // Handlers that update the global Notifier
        onThemeToggle: () {
          appNotifier!.appState.isDarkTheme = !(appNotifier!.appState.isDarkTheme ?? false);
          appNotifier!.updateAppState(appNotifier!.appState);
          _prefs.setBool("isDarkTheme", appNotifier!.appState.isDarkTheme!);
          _updateGlobalState();
        },
        onKeepScreenToggle: () {
          final isOn = !(_conf.keepScreenOn ?? false);
          appNotifier!.appState.keepScreenOn = isOn;
          appNotifier!.updateAppState(appNotifier!.appState);
          _prefs.setBool("keepScreenOn", isOn);
          WakelockPlus.toggle(enable: isOn);
          _updateGlobalState();
        },
        onRemoteToggle: () {
          final pairer = remotePairer();
          if (!pairer.remoteControlEnabled && !pairer.paired) {
            scaffoldMessengerKey.currentState?.showSnackBar(const SnackBar(content: Text('No remote device paired'), behavior: SnackBarBehavior.floating));
            return;
          }
          pairer.remoteControlEnabled ? pairer.disableRemoteControl() : pairer.enableRemoteControl();
          setState(() {});
        },
        onPageSelect: (route) {
          appNotifier!.appState.currentPage = route;
          appNotifier!.updateAppState(appNotifier!.appState);
          _updateGlobalState();
        },
      ),
    );
  }
}

class LandscapeHomeScreen extends StatelessWidget {
  final AppState conf;
  final PageController pageController;
  final VoidCallback onThemeToggle;
  final VoidCallback onKeepScreenToggle;
  final VoidCallback onRemoteToggle;
  final Function(String) onPageSelect;

  const LandscapeHomeScreen({super.key, required this.conf, required this.pageController, required this.onThemeToggle, required this.onKeepScreenToggle, required this.onRemoteToggle, required this.onPageSelect});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isRemoteActive = remotePairer().remoteControlEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LANDSCAPE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 18)),
        actions: [
          _buildRemoteCapsule(colorScheme, isRemoteActive),
          
          // POPUP MENU
          PopupMenuButton<int>(
            icon: const Icon(Icons.tune_rounded),
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            // We use itembuilder but the items themselves will listen to the Notifier
            itemBuilder: (context) => [
              _buildReactivePopupItem(
                context: context,
                title: "Keep Screen On",
                iconOn: Icons.lightbulb,
                iconOff: Icons.lightbulb_outline,
                // Check state from Notifier directly
                selector: (s) => s.keepScreenOn ?? false,
                onTap: onKeepScreenToggle,
              ),
              _buildReactivePopupItem(
                context: context,
                title: "Dark Theme",
                iconOn: Icons.dark_mode,
                iconOff: Icons.light_mode,
                selector: (s) => s.isDarkTheme ?? false,
                onTap: onThemeToggle,
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(context, colorScheme.primary),
      body: UpgradeAlert(
        upgrader: upgrader,
        child: PageView(
          physics: const BouncingScrollPhysics(),
          controller: pageController,
          children: [ErrorPage(), GifPage(), ScrollTextPage(), RemoteHttpServerPage(), LandscapeClient()],
        ),
      ),
    );
  }

  /// This creates a PopupMenuItem that internally "listens" to the AppNotifier.
  /// This is the ONLY way to make switches move inside an already-open menu.
  PopupMenuItem<int> _buildReactivePopupItem({
    required BuildContext context,
    required String title,
    required IconData iconOn,
    required IconData iconOff,
    required bool Function(AppState) selector,
    required VoidCallback onTap,
  }) {
    return PopupMenuItem<int>(
      enabled: false, // Allows us to handle the tap on the Row/Switch manually
      child: Consumer<AppNotifier>(
        builder: (context, notifier, _) {
          final bool isActive = selector(notifier.appState);
          return InkWell(
            onTap: onTap, // Toggle the state
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(isActive ? iconOn : iconOff, size: 20, color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
                  // Switch follows the state from the Notifier
                  Switch.adaptive(
                    value: isActive,
                    onChanged: (_) => onTap(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRemoteCapsule(ColorScheme colorScheme, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: InkWell(
        onTap: onRemoteToggle,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isActive ? colorScheme.primaryContainer : colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isActive ? colorScheme.primary : colorScheme.outline.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(isActive ? Icons.wifi_tethering : Icons.wifi_tethering_off, size: 16, color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(isActive ? "REMOTE ON" : "REMOTE OFF", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, Color primaryColor) {
    return Drawer(
      child: Column(
        children: [
          _drawerHeader(primaryColor),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _drawerItem(context, Icons.gif_box_outlined, 'GIF Player', "/gif"),
                _drawerItem(context, Icons.text_fields_rounded, 'Scroll Text', "/scroll-text"),
                const Divider(height: 32),
                _drawerItem(context, Icons.dns_outlined, 'Remote Server', "/remote-server"),
                _drawerItem(context, Icons.devices_other_rounded, 'Remote Client', "/remote-client"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerHeader(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withOpacity(0.8)])),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.landscape, color: Colors.white)),
          SizedBox(height: 12),
          Text('Landscape', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text('System Control', style: TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String title, String route) {
    final isSelected = conf.currentPage == route;
    return ListTile(
      selected: isSelected,
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () { Navigator.pop(context); onPageSelect(route); },
    );
  }
}
