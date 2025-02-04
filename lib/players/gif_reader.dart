import 'dart:async';
import 'dart:math';
// ignore: unnecessary_import
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:landscape/gif_view/src/gif_controller.dart';
import 'package:landscape/gif_view/src/gif_frame.dart';
import 'package:http/http.dart' as http;

final Map<String, List<GifFrame>> _cache = {};

class GifReader {
  final double? frameRate;

  GifReader({
    this.frameRate,
  });

  String _getKeyImage(ImageProvider provider) {
    return provider is NetworkImage
        ? provider.url
        : provider is AssetImage
            ? provider.assetName
            : provider is MemoryImage
                ? provider.bytes.toString().substring(0, 100)
                : provider is FileImage
                    ? provider.file.path
                    : Random().nextDouble().toString();
  }

  Future<List<GifFrame>> _fetchGif(ImageProvider provider) async {
    List<GifFrame> frameList = [];
    try {
      String key = _getKeyImage(provider);

      if (_cache.containsKey(key)) {
        frameList = _cache[key]!;
        return frameList;
      }

      Uint8List? data = await _loadImageBytes(provider);

      if (data == null) {
        return [];
      }

      frameList.addAll(await _buildFrames(data));

      _cache.putIfAbsent(key, () => frameList);
    } catch (e) {
      print(e);
    }
    return frameList;
  }

  FutureOr getFrames(ImageProvider image, {bool updateFrames = false}) async {
    return await _fetchGif(image);
  }

  Future<Uint8List?> _loadImageBytes(ImageProvider<Object> provider) {
    if (provider is NetworkImage) {
      final Uri resolved = Uri.base.resolve(provider.url);
      return http
          .get(resolved, headers: provider.headers)
          .then((value) => value.bodyBytes);
    } else if (provider is AssetImage) {
      return provider.obtainKey(const ImageConfiguration()).then(
        (value) async {
          final d = await value.bundle.load(value.name);
          return d.buffer.asUint8List();
        },
      );
    } else if (provider is FileImage) {
      return provider.file.readAsBytes();
    } else if (provider is MemoryImage) {
      return Future.value(provider.bytes);
    }
    return Future.value(null);
  }

  Future<Iterable<GifFrame>> _buildFrames(Uint8List data) async {
    Codec codec = await instantiateImageCodec(
      data,
      allowUpscaling: false,
    );

    List<GifFrame> list = [];

    for (int i = 0; i < codec.frameCount; i++) {
      FrameInfo frameInfo = await codec.getNextFrame();
      Duration duration = frameInfo.duration;
      if (frameRate != null) {
        duration = Duration(milliseconds: (1000 / frameRate!).ceil());
      }
      list.add(
        GifFrame(
          ImageInfo(image: frameInfo.image),
          duration,
        ),
      );
    }
    return list;
  }
}
