import 'package:flutter/material.dart';

class FullScreenWrapper extends StatelessWidget {
  const FullScreenWrapper({Key? key, this.child}) : super(key: key);
  final Widget? child;

  @override
  Widget build(BuildContext context) {
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
                      child: child,
                      width: double.infinity,
                      height: double.infinity,
                    )),
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}