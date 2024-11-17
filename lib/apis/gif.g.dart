// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gif.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GifConfiguration _$GifConfigurationFromJson(Map<String, dynamic> json) =>
    GifConfiguration(
      filePaths: (json['filePaths'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      frameRate: (json['frameRate'] as num?)?.toDouble(),
      loop: json['loop'] as bool?,
    );

Map<String, dynamic> _$GifConfigurationToJson(GifConfiguration instance) =>
    <String, dynamic>{
      'filePaths': instance.filePaths,
      'frameRate': instance.frameRate,
      'loop': instance.loop,
    };
