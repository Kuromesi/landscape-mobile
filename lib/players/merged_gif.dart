import 'dart:io';

import 'package:flutter/material.dart';
import 'package:landscape/gif_view/src/gif_frame.dart';
import 'package:landscape/gif_view/gif_view.dart';
import 'package:landscape/players/gif_reader.dart';
import 'package:landscape/gif_view/my_gif_view.dart';

// MergedGifPlayer merge gifs into one and assign a single controller
class MergedGifPlayer extends StatefulWidget {
  final List<String> gifs;

  MergedGifPlayer({Key? key, required this.gifs}) : super(key: key);

  @override
  State<MergedGifPlayer> createState() => _MergedGifPlayerState();
}

class _MergedGifPlayerState extends State<MergedGifPlayer> {
  late GifController _gifController;
  late MyGifView _gif;
  int _frameRate = 10;
  bool _loading = true;
  String _status = "Loading...";

  @override
  void initState() {
    super.initState();
    _createMergedGifs();
  }

  void _createMergedGifs() async {
    if (widget.gifs.isEmpty) {
      _status = "No gifs selected";
      return;
    }
    List<GifFrame> frames = [];
    GifReader r = GifReader();

    for (String gif in widget.gifs) {
      try {
        FileImage image = FileImage(
          File(gif),
        );
        List<GifFrame> t = await r.getFrames(image);
        frames.addAll(t);
      } catch (e) {
        _status = e.toString();
        print(e);
      }
    }
    _gifController = GifController(loop: true, autoPlay: true);
    _gifController.configure(frames);
    _gif = MyGifView(
      controller: _gifController,
      fit: MediaQuery.of(context).orientation == Orientation.landscape ? BoxFit.fitWidth : BoxFit.fitHeight,
      frameRate: _frameRate,
    );
    setState(() {
      _loading = false;
      _gif = _gif;
      _gifController = _gifController;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          Navigator.pop(
            context,
          );
        },
        child: _loading
            ? Container(
                child: Center(
                child: Text(_status),
              ))
            : Container(
                width: double.infinity,
                height: double.infinity,
                child: _gif,
              ),
      ),
    );
  }
}
