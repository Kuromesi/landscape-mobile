import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:landscape/utils/utils.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';

String defaultScrollText =
    'Hey! I\'m a RTL text, check me out. Hey! I\'m a RTL text, check me out. Hey! I\'m a RTL text, check me out. ';

class ScrollTextPage extends StatefulWidget {
  @override
  _ScrollTextPageState createState() => _ScrollTextPageState();
}

class _ScrollTextPageState extends State<ScrollTextPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _text = defaultScrollText;
  TextDirection _textDirection = TextDirection.ltr;
  double _fontSize = 80;
  bool _adaptiveColor = true;
  Color? _fontColor = const Color(0x00000000);
  double _scrollSpeed = 1.0;
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _savePreferences();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    _text = await _prefs.getString("scrollText") ?? defaultScrollText;
    _textDirection = (await _prefs.getString("scrollTextDirection")) == 'rtl'
        ? TextDirection.rtl
        : TextDirection.ltr;
    _fontSize = await _prefs.getDouble("scrollTextFontSize") ?? 80;
    _fontColor =
        Color(await _prefs.getInt("scrollTextFontColor") ?? 0x00000000);
    _adaptiveColor = await _prefs.getBool("scrollTextAdaptiveColor") ?? true;
    _scrollSpeed = await _prefs.getDouble("scrollTextScrollSpeed") ?? 1.0;
    setState(() {
      _text = _text;
      _textDirection = _textDirection;
      _fontSize = _fontSize;
      _fontColor = _fontColor;
      _adaptiveColor = _adaptiveColor;
      _scrollSpeed = _scrollSpeed;
    });
  }

  Future<void> _savePreferences() async {
    await _prefs.setString("scrollText", _text);
    await _prefs.setString("scrollTextDirection", _textDirection.name);
    await _prefs.setDouble("scrollTextFontSize", _fontSize);
    await _prefs.setInt("scrollTextFontColor", _fontColor?.value ?? 0x00000000);
    await _prefs.setBool("scrollTextAdaptiveColor", _adaptiveColor);
    await _prefs.setDouble("scrollTextScrollSpeed", _scrollSpeed);
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
                      initialValue: _text,
                      onChanged: (value) {
                        innerSetState(() {
                          _text = value;
                        });
                        setState(() {
                          _text = _text;
                        });
                      },
                    ),
                    DropdownButtonFormField<TextDirection>(
                      value: _textDirection,
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
                          _textDirection = value!;
                        });
                        setState(() {
                          _textDirection = _textDirection;
                        });
                      },
                      decoration:
                          const InputDecoration(labelText: 'Scroll Direction'),
                    ),
                    Slider(
                      value: _fontSize,
                      min: 50,
                      max: 150,
                      divisions: 120,
                      label: _fontSize.round().toString(),
                      onChanged: (value) {
                        innerSetState(() {
                          _fontSize = value;
                        });
                        setState(() {
                          _fontSize = _fontSize;
                        });
                      },
                    ),
                    Text('Font Size: ${_fontSize.round()}'),
                    Slider(
                      value: _scrollSpeed,
                      min: 0,
                      max: 10,
                      divisions: 20,
                      label: (_scrollSpeed).toString(),
                      onChanged: (value) {
                        innerSetState(() {
                          _scrollSpeed = value;
                        });
                        setState(() {
                          _scrollSpeed = _scrollSpeed;
                        });
                      },
                    ),
                    Text('Scroll Speed: ${(_scrollSpeed)}'),
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
                                    pickerColor: _fontColor,
                                    onColorChanged: (color) {
                                      innerSetState(() {
                                        _fontColor = color;
                                      });
                                      setState(() {
                                        _fontColor = color;
                                        _adaptiveColor = false;
                                      });
                                    },
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    child: Text('Auto'),
                                    onPressed: () {
                                      innerSetState(() {
                                        _fontColor = null;
                                      });
                                      setState(() {
                                        _adaptiveColor = true;
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: FullScreenWrapper.wrap(
          Center(
            child: Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextScroll(
                    _text,
                    textDirection: _textDirection,
                    style: TextStyle(
                      fontSize: _fontSize,
                      color: _adaptiveColor ? null : _fontColor,
                    ),
                    velocity: Velocity(
                        pixelsPerSecond: Offset(_scrollSpeed * 100, 0)),
                  ),
                ],
              ),
            ),
          ),
          context),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSettingsDialog,
        child: Icon(Icons.settings),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
