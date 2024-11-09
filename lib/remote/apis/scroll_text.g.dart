// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scroll_text.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScrollTextConfiguration _$ScrollTextConfigurationFromJson(
        Map<String, dynamic> json) =>
    ScrollTextConfiguration(
      text: json['text'] as String,
      direction: json['direction'] as String?,
      fontSize: (json['fontSize'] as num?)?.toDouble(),
      scrollSpeed: (json['scrollSpeed'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ScrollTextConfigurationToJson(
        ScrollTextConfiguration instance) =>
    <String, dynamic>{
      'text': instance.text,
      'direction': instance.direction,
      'fontSize': instance.fontSize,
      'scrollSpeed': instance.scrollSpeed,
    };
