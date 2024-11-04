import 'package:flutter/material.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:landscape/utils/utils.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ScrollTextPage extends StatefulWidget {
  @override
  _ScrollTextPageState createState() => _ScrollTextPageState();
}

class _ScrollTextPageState extends State<ScrollTextPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _text =
      'Hey! I\'m a RTL text, check me out. Hey! I\'m a RTL text, check me out. Hey! I\'m a RTL text, check me out. ';
  TextDirection _textDirection = TextDirection.ltr;
  double _fontSize = 80;
  double test = 100;
  Color? _fontColor = null;
  double _scrollSpeed = 1.0;
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
                                        _fontColor = _fontColor;
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
                    // ElevatedButton(
                    //   child: Text('应用设置'),
                    //   onPressed: () {
                    //     Navigator.of(context).pop();
                    //     setState(() {
                    //       _fontSize = _fontSize;
                    //       _scrollSpeed = _scrollSpeed;
                    //       _textDirection = _textDirection;
                    //     });
                    //   },
                    // ),
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
                      color: _fontColor,
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
