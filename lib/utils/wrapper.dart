import 'package:flutter/material.dart';

class FullScreenWrapper {
  static GestureDetector wrap<T extends Widget>(T obj, BuildContext context,
      {List<void Function()> enter = const [],
      List<void Function()> exit = const []}) {
    return GestureDetector(
        onTap: () {
          enter.forEach((fn) => fn());
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Scaffold(
                      body: Center(
                        child: GestureDetector(
                            onTap: () {
                              exit.forEach((fn) => fn());
                              Navigator.pop(
                                context,
                              );
                            },
                            child: Container(
                              child: obj,
                              width: double.infinity,
                              height: double.infinity,
                            )),
                      ),
                    )),
          );
        },
        child: obj);
  }
}

GestureDetector fullScreenWrap<T extends Widget>(T obj, BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: GestureDetector(
                  onTap: () {
                    Navigator.pop(
                      context,
                    );
                  },
                  child: Container(
                    child: obj,
                    width: double.infinity,
                    height: double.infinity,
                  )),
            ),
          ),
        ),
      );
    },
    child: obj,
  );
}