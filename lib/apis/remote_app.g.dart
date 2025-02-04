// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_app.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RemoteAppState _$RemoteAppStateFromJson(Map<String, dynamic> json) =>
    RemoteAppState(
      mode: json['mode'] as String,
      scrollTextConfig: json['scrollTextConfig'] == null
          ? null
          : ScrollTextConfiguration.fromJson(
              json['scrollTextConfig'] as Map<String, dynamic>),
      gifConfig: json['gifConfig'] == null
          ? null
          : GifConfiguration.fromJson(
              json['gifConfig'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RemoteAppStateToJson(RemoteAppState instance) =>
    <String, dynamic>{
      'scrollTextConfig': instance.scrollTextConfig,
      'gifConfig': instance.gifConfig,
      'mode': instance.mode,
    };
