import 'package:json_annotation/json_annotation.dart';
import 'package:landscape/apis/gif.dart';
import 'scroll_text.dart';

part 'remote_app.g.dart';

@JsonSerializable()
class RemoteAppState extends JsonSerializable {
  ScrollTextConfiguration? scrollTextConfig;
  GifConfiguration ? gifConfig;
  String mode;

  RemoteAppState({required this.mode, this.scrollTextConfig, this.gifConfig});

  factory RemoteAppState.fromJson(Map<String, dynamic> json) =>
      _$RemoteAppStateFromJson(json);

  Map<String, dynamic> toJson() => _$RemoteAppStateToJson(this);
}
