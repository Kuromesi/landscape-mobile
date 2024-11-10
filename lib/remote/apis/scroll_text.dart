import 'package:json_annotation/json_annotation.dart';

part 'scroll_text.g.dart';

@JsonSerializable()
class ScrollTextConfiguration {
  final String text;
  final String? direction;
  final double? fontSize;
  final double? scrollSpeed;
  final int? fontColor;
  final bool? adaptiveColor;

  ScrollTextConfiguration(
      {required this.text, this.direction, this.fontSize, this.scrollSpeed, this.fontColor, this.adaptiveColor});

  factory ScrollTextConfiguration.fromJson(Map<String, dynamic> json) =>
      _$ScrollTextConfigurationFromJson(json);

  Map<String, dynamic> toJson() => _$ScrollTextConfigurationToJson(this);
}
