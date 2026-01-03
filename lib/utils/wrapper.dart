import 'package:flutter/material.dart';
import 'package:landscape/notifiers/notifier.dart';

class FullScreenWrapper extends StatefulWidget {
  const FullScreenWrapper({
    Key? key,
    this.child,
    this.fullScreen = false, // Added optional parameter
  }) : super(key: key);

  final Widget? child;
  final bool fullScreen;

  @override
  State<FullScreenWrapper> createState() => _FullScreenWrapperState();
}

class _FullScreenWrapperState extends State<FullScreenWrapper> {
  @override
  void initState() {
    super.initState();
    // If fullScreen is true, trigger the navigation after the first frame
    if (widget.fullScreen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _navigateToFullScreen(context);
        }
      });
    }
  }

  // @override
  // void didUpdateWidget(covariant FullScreenWrapper oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   // Case 2: The widget already existed, but fullScreen changed from false to true
  //   if (widget.fullScreen && !oldWidget.fullScreen) {
  //     _checkAndNavigate();
  //   }
  // }

  // void _checkAndNavigate() {
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     if (mounted && appNotifier!.appState.currentPage == '/scroll-text') {
  //       _navigateToFullScreen(context);
  //     }
  //   });
  // }

  /// Helper method to push the full-screen route
  void _navigateToFullScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          // Use black background for a better full-screen experience
          backgroundColor: Colors.black,
          body: Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToFullScreen(context),
      child: widget.child,
    );
  }
}
