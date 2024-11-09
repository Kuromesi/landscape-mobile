import 'package:json_annotation/json_annotation.dart';

part 'scroll_text.g.dart';

@JsonSerializable()
class ScrollTextConfiguration {
  final String text;
  final String? direction;
  final double? fontSize;
  final double? scrollSpeed;

  ScrollTextConfiguration({required this.text, this.direction, this.fontSize, this.scrollSpeed});

  factory ScrollTextConfiguration.fromJson(Map<String, dynamic> json) => _$ScrollTextConfigurationFromJson(json);

  Map<String, dynamic> toJson() => _$ScrollTextConfigurationToJson(this);
}
