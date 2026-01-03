import 'package:flutter/material.dart';
import 'package:landscape/constants/constants.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:landscape/constants/text.dart';
import 'package:landscape/apis/apis.dart';

class ScrollTextPlayer extends StatelessWidget {
  const ScrollTextPlayer({
    super.key,
    required this.conf,
  });

  final ScrollText conf;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Center(
            child:Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextScroll(
                    conf.text ?? defaultScrollText,
                    textDirection: conf.direction == 'rtl'
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    style: TextStyle(
                      fontSize: conf.fontSize ?? 80,
                      color: conf.fontColor != Colors.black.toARGB32() && conf.fontColor != null
                          ? Color(conf.fontColor!)
                          : null,
                    ),
                    velocity: Velocity(
                        pixelsPerSecond:
                            Offset((conf.scrollSpeed ?? 1.0) * 100, 0)),
                  ),
                ],
              ),
          ),
      ),
    );
  }
}
