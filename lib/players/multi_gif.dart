import 'dart:io';

import 'package:flutter/material.dart';
import 'package:landscape/gif_view/gif_view.dart';

// MultiGifPlayer assign controllers for different gif and loops
class MultiGifPlayer extends StatefulWidget {
  final List<String> gifs;
  final int? frameRate;

  MultiGifPlayer({Key? key, required this.gifs, this.frameRate})
      : super(key: key);

  @override
  State<MultiGifPlayer> createState() => _MultiGifPlayerState();
}

class _MultiGifPlayerState extends State<MultiGifPlayer> {
  late List<GifController> _gifControllerList;
  late int _frameRate;

  final List<GifView> _gifs = [];
  int _currentGif = 0;
  Duration _mustPlayAfter = Duration(seconds: 0);
  bool _next = true;

  late DateTime _startTime;
  @override
  void initState() {
    _gifControllerList = [];
    _frameRate = widget.frameRate ?? 15;
    for (int i = 0; i < widget.gifs.length; i++) {
      try {
        FileImage image = FileImage(
          File(widget.gifs[i]),
        );
        GifController controller = GifController(
          onStart: () {
            if (_next) {
              _startTime = DateTime.now();
              _next = false;
            }
          },
          onFinish: () {
            if (DateTime.now().difference(_startTime) < _mustPlayAfter) {
              // start controller
              _gifControllerList[_currentGif].play();
              return;
            }
            if (!mounted) return;
            _next = true;
            if (_gifs.length == 1) {
              _gifControllerList[_currentGif].play();
              return;
            }
            setState(
              () {
                _currentGif = (_currentGif + 1) % _gifs.length;
              },
            );
          },
          loop: false,
        );
        _gifs.add(
          GifView(
            image: image,
            controller: controller,
            fit: BoxFit.fitWidth,
            repeat: ImageRepeat.noRepeat,
            frameRate: _frameRate,
            withOpacityAnimation: false,
          ),
        );
        _gifControllerList.add(controller);
      } catch (e) {
        print(e);
      }
    }
    super.initState();
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
        child: _gifs.length != 0
            ? Container(
                key: ValueKey<int>(_currentGif),
                width: double.infinity,
                height: double.infinity,
                child: _gifs[_currentGif],
              )
            : Container(),
      ),
    );
  }
}
