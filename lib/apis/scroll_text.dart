import 'package:json_annotation/json_annotation.dart';
import 'package:landscape/constants/text.dart';

part 'scroll_text.g.dart';

@JsonSerializable()
class ScrollTextConfiguration extends JsonSerializable {
  List<ScrollText>? templates; 
  int? currentTemplate;

  ScrollTextConfiguration({this.templates, this.currentTemplate}) {
    templates ??= [ScrollText(text: defaultScrollText)];
    currentTemplate ??= 0;
  }

  factory ScrollTextConfiguration.fromJson(Map<String, dynamic> json) =>
      _$ScrollTextConfigurationFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ScrollTextConfigurationToJson(this);

  ScrollText getCurrentTemplate() {
    if (currentTemplate == null || templates == null || templates!.isEmpty || currentTemplate! >= templates!.length) {
      return ScrollText(text: defaultScrollText);
    }
    return templates![currentTemplate!];
  }
}

@JsonSerializable()
class ScrollText extends JsonSerializable {
  String? text;
  String? direction;
  double? fontSize;
  double? scrollSpeed;
  int? fontColor;

  ScrollText(
      {this.text, this.direction, this.fontSize, this.scrollSpeed, this.fontColor}) {
        text ??= defaultScrollText;
        direction ??= 'rtl';
        fontSize ??= 80;
        scrollSpeed ??= 1.0;
      }

  factory ScrollText.fromJson(Map<String, dynamic> json) =>
      _$ScrollTextFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ScrollTextToJson(this);
}