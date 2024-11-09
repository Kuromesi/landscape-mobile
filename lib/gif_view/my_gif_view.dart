import 'package:flutter/material.dart';
import 'package:landscape/gif_view/gif_view.dart';

class MyGifView extends StatefulWidget {
  final GifController? controller;
  final int? frameRate;
  final double? height;
  final double? width;
  final Widget? progress;
  final BoxFit? fit;
  final Color? color;
  final BlendMode? colorBlendMode;
  final AlignmentGeometry alignment;
  final ImageRepeat repeat;
  final Rect? centerSlice;
  final bool matchTextDirection;
  final bool invertColors;
  final bool withOpacityAnimation;
  final FilterQuality filterQuality;
  final bool isAntiAlias;
  final Widget Function(Exception error)? onError;
  final Duration? fadeDuration;

  const MyGifView({
    Key? key,
    this.controller,
    this.frameRate = 15,
    this.height,
    this.width,
    this.progress,
    this.fit,
    this.color,
    this.colorBlendMode,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.invertColors = false,
    this.filterQuality = FilterQuality.low,
    this.isAntiAlias = false,
    this.withOpacityAnimation = true,
    this.onError,
    this.fadeDuration,
  }) : super(key: key);

  @override
  MyGifViewState createState() => MyGifViewState();
}

class MyGifViewState extends State<MyGifView> with TickerProviderStateMixin {
  late GifController controller;

  AnimationController? _animationController;

  @override
  void initState() {
    if (widget.withOpacityAnimation) {
      _animationController = AnimationController(
        vsync: this,
        duration: widget.fadeDuration ?? const Duration(milliseconds: 300),
      );
    }
    controller = widget.controller ?? GifController();
    controller.addListener(_listener);
    _animationController?.forward(from: 0);
    super.initState();
  }

  void _listener() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    controller.stop();
    controller.removeListener(_listener);
    _animationController?.dispose();
    _animationController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller.status == GifStatus.loading) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.progress,
      );
    }

    if (controller.status == GifStatus.error) {
      final errorWidget = widget.onError?.call(controller.exception!);
      if (errorWidget == null) {
        throw controller.exception!;
      }
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: errorWidget,
      );
    }

    return RawImage(
      image: controller.currentFrame.imageInfo.image,
      width: widget.width,
      height: widget.height,
      scale: controller.currentFrame.imageInfo.scale,
      fit: widget.fit,
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      alignment: widget.alignment,
      repeat: widget.repeat,
      centerSlice: widget.centerSlice,
      matchTextDirection: widget.matchTextDirection,
      invertColors: widget.invertColors,
      filterQuality: widget.filterQuality,
      isAntiAlias: widget.isAntiAlias,
      opacity: _animationController,
    );
  }
}
