import 'package:json_annotation/json_annotation.dart';

part 'gif.g.dart';

@JsonSerializable()
class GifConfiguration extends JsonSerializable {
  List<String>? filePaths = [];
  double? frameRate = 15.0;
  bool? loop = true;


  GifConfiguration(
      {this.filePaths, this.frameRate, this.loop});

  factory GifConfiguration.fromJson(Map<String, dynamic> json) =>
      _$GifConfigurationFromJson(json);

  Map<String, dynamic> toJson() => _$GifConfigurationToJson(this);
}
