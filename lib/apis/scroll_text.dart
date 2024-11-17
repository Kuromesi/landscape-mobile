import 'package:json_annotation/json_annotation.dart';

part 'scroll_text.g.dart';

@JsonSerializable()
class ScrollTextConfiguration extends JsonSerializable {
  String? text;
  String? direction;
  double? fontSize;
  double? scrollSpeed;
  int? fontColor;
  bool? adaptiveColor;

  ScrollTextConfiguration(
      {this.text, this.direction, this.fontSize, this.scrollSpeed, this.fontColor, this.adaptiveColor});

  factory ScrollTextConfiguration.fromJson(Map<String, dynamic> json) =>
      _$ScrollTextConfigurationFromJson(json);

  Map<String, dynamic> toJson() => _$ScrollTextConfigurationToJson(this);
}
