// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scroll_text.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScrollTextConfiguration _$ScrollTextConfigurationFromJson(
        Map<String, dynamic> json) =>
    ScrollTextConfiguration(
      templates: (json['templates'] as List<dynamic>?)
              ?.map((e) => ScrollText.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    )..currentTemplate = (json['currentTemplate'] as num?)?.toInt();

Map<String, dynamic> _$ScrollTextConfigurationToJson(
        ScrollTextConfiguration instance) =>
    <String, dynamic>{
      'templates': instance.templates,
      'currentTemplate': instance.currentTemplate,
    };

ScrollText _$ScrollTextFromJson(Map<String, dynamic> json) => ScrollText(
      text: json['text'] as String?,
      direction: json['direction'] as String?,
      fontSize: (json['fontSize'] as num?)?.toDouble(),
      scrollSpeed: (json['scrollSpeed'] as num?)?.toDouble(),
      fontColor: (json['fontColor'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ScrollTextToJson(ScrollText instance) =>
    <String, dynamic>{
      'text': instance.text,
      'direction': instance.direction,
      'fontSize': instance.fontSize,
      'scrollSpeed': instance.scrollSpeed,
      'fontColor': instance.fontColor,
    };
