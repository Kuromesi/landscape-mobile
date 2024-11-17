import 'package:flutter/material.dart';
import 'package:landscape/notifiers/notifier.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:landscape/players/players.dart';

import 'package:landscape/apis/apis.dart';
import 'package:landscape/utils/utils.dart';

class LandscapeRemote extends StatefulWidget {
  const LandscapeRemote({super.key});
  @override
  _LandscapeRemoteState createState() => _LandscapeRemoteState();
}

class _LandscapeRemoteState extends State<LandscapeRemote> {
  final RemoteAppState _conf = RemoteAppState(
      mode: configScrollText,
      scrollTextConfig: ScrollTextConfiguration(),
      gifConfig: GifConfiguration());

  @override
  void initState() {
    _addRemoteHttpListener();
    configDump[configRemoteApp] = exportState;
    if (configDump[configScrollText] != null) {
      _conf.scrollTextConfig = ScrollTextConfiguration.fromJson(
          configDump[configScrollText]!().toJson());
    }
    if (configDump[configGif] != null) {
      _conf.gifConfig =
          GifConfiguration.fromJson(configDump[configGif]!().toJson());
    }
    super.initState();
  }

  JsonSerializable exportState() {
    return _conf;
  }

  void _addRemoteHttpListener() {
    notifier!.addListener(() => mounted
        ? setState(() {
            _conf.gifConfig =
                notifier!.configuration.gifConfig ?? _conf.gifConfig;
            _conf.mode = notifier!.configuration.mode;
            _conf.scrollTextConfig = notifier!.configuration.scrollTextConfig ??
                _conf.scrollTextConfig;
          })
        : null);
  }

  @override
  void dispose() {
    configDump.remove(configRemoteApp);
    notifier!.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_conf.mode) {
      case configScrollText:
        return ScrollTextPlayer(
            conf: _conf.scrollTextConfig ?? ScrollTextConfiguration());
      case configGif:
        return MultiGifPlayer(
          gifs: _conf.gifConfig!.filePaths ?? [],
          frameRate: _conf.gifConfig!.frameRate == null
              ? 15
              : _conf.gifConfig!.frameRate!.round(),
        );
      default:
        return const Text('Invalid');
    }
  }
}
