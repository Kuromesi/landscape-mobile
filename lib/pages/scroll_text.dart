import 'dart:async';

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:landscape/constants/constants.dart';
import 'package:landscape/notifiers/notifier.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:landscape/utils/utils.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:landscape/constants/text.dart';
import 'package:landscape/apis/apis.dart';
import 'package:landscape/players/players.dart';

class ScrollTextPage extends StatefulWidget {
  @override
  _ScrollTextPageState createState() => _ScrollTextPageState();
}

class _ScrollTextPageState extends State<ScrollTextPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ScrollTextConfiguration _conf = ScrollTextConfiguration(
    text: defaultScrollText,
    direction: "rtl",
    fontSize: 80,
    scrollSpeed: 1.0,
    fontColor: 0x00000000,
    adaptiveColor: true,
  );
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  @override
  void initState() {
    super.initState();
    configDump[configScrollText] = exportState;
    _loadPreferences();
  }

  @override
  void dispose() {
    _savePreferences();
    configDump.remove(configScrollText);
    super.dispose();
  }

  JsonSerializable exportState() {
    return _conf;
  }

  Future<void> _loadPreferences() async {
    _conf.text = await _prefs.getString("scrollText") ?? defaultScrollText;
    _conf.direction = await _prefs.getString("scrollTextDirection");
    _conf.fontSize = await _prefs.getDouble("scrollTextFontSize") ?? 80;
    _conf.fontColor = await _prefs.getInt("scrollTextFontColor");
    _conf.adaptiveColor =
        await _prefs.getBool("scrollTextAdaptiveColor") ?? true;
    _conf.scrollSpeed = await _prefs.getDouble("scrollTextScrollSpeed") ?? 1.0;
    setState(() {});
  }

  Future<void> _savePreferences() async {
    await _prefs.setString("scrollText", _conf.text!);
    await _prefs.setString("scrollTextDirection", _conf.direction!);
    await _prefs.setDouble("scrollTextFontSize", _conf.fontSize!);
    await _prefs.setInt("scrollTextFontColor", _conf.fontColor!);
    await _prefs.setBool("scrollTextAdaptiveColor", _conf.adaptiveColor!);
    await _prefs.setDouble("scrollTextScrollSpeed", _conf.scrollSpeed!);
  }

  void _showSettingsDialog() {
    showModalBottomSheet(
      // fix when using keyboard this panel will be hided
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          // fix when using keyboard this panel will be hided
          padding: MediaQuery.of(context).viewInsets,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter innerSetState) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Text'),
                      initialValue: _conf.text,
                      onChanged: (value) {
                        innerSetState(() {
                          _conf.text = value;
                        });
                        setState(() {});
                      },
                    ),
                    DropdownButtonFormField<TextDirection>(
                      value: _conf.direction == "rtl"
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      items: const [
                        DropdownMenuItem(
                          value: TextDirection.ltr,
                          child: Text('Left2Right'),
                        ),
                        DropdownMenuItem(
                          value: TextDirection.rtl,
                          child: Text('Right2Left'),
                        ),
                      ],
                      onChanged: (value) {
                        innerSetState(() {
                          _conf.direction = value!.name;
                        });
                        setState(() {});
                      },
                      decoration:
                          const InputDecoration(labelText: 'Scroll Direction'),
                    ),
                    Slider(
                      value: _conf.fontSize!,
                      min: 50,
                      max: 150,
                      divisions: 120,
                      label: _conf.fontSize!.round().toString(),
                      onChanged: (value) {
                        innerSetState(() {
                          _conf.fontSize = value;
                        });
                        setState(() {});
                      },
                    ),
                    Text('Font Size: ${_conf.fontSize!.round()}'),
                    Slider(
                      value: _conf.scrollSpeed!,
                      min: 0,
                      max: 10,
                      divisions: 20,
                      label: (_conf.scrollSpeed!).toString(),
                      onChanged: (value) {
                        innerSetState(() {
                          _conf.scrollSpeed = value;
                        });
                        setState(() {});
                      },
                    ),
                    Text('Scroll Speed: ${(_conf.scrollSpeed)}'),
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Font Color'),
                        ),
                        IconButton(
                          icon: Icon(Icons.color_lens),
                          onPressed: () async {
                            await showDialog<Color>(
                              context: context,
                              builder: (context) => AlertDialog(
                                content: SingleChildScrollView(
                                  child: BlockPicker(
                                    pickerColor: Color(_conf.fontColor!),
                                    onColorChanged: (color) {
                                      innerSetState(() {
                                        _conf.fontColor = color.value;
                                      });
                                      setState(() {
                                        _conf.adaptiveColor = false;
                                      });
                                    },
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    child: Text('Auto'),
                                    onPressed: () {
                                      innerSetState(() {
                                        _conf.fontColor = null;
                                      });
                                      setState(() {
                                        _conf.adaptiveColor = true;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    ElevatedButton(
                      child: const Text('Save Settings'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _savePreferences();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buttons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: "scroll_settings",
          onPressed: _showSettingsDialog,
          child: Icon(Icons.settings),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: FullScreenWrapper(
        child: ScrollTextPlayer(conf: _conf),
      ),
      floatingActionButton: _buttons(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}