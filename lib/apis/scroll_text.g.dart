// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scroll_text.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScrollTextConfiguration _$ScrollTextConfigurationFromJson(
        Map<String, dynamic> json) =>
    ScrollTextConfiguration(
      text: json['text'] as String?,
      direction: json['direction'] as String?,
      fontSize: (json['fontSize'] as num?)?.toDouble(),
      scrollSpeed: (json['scrollSpeed'] as num?)?.toDouble(),
      fontColor: (json['fontColor'] as num?)?.toInt(),
      adaptiveColor: json['adaptiveColor'] as bool?,
    );

Map<String, dynamic> _$ScrollTextConfigurationToJson(
        ScrollTextConfiguration instance) =>
    <String, dynamic>{
      'text': instance.text,
      'direction': instance.direction,
      'fontSize': instance.fontSize,
      'scrollSpeed': instance.scrollSpeed,
      'fontColor': instance.fontColor,
      'adaptiveColor': instance.adaptiveColor,
    };
