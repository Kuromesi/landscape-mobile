// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppState _$AppStateFromJson(Map<String, dynamic> json) => AppState(
      currentPage: json['currentPage'] as String?,
      keepScreenOn: json['keepScreenOn'] as bool?,
      isDarkTheme: json['isDarkTheme'] as bool?,
    );

Map<String, dynamic> _$AppStateToJson(AppState instance) => <String, dynamic>{
      'currentPage': instance.currentPage,
      'keepScreenOn': instance.keepScreenOn,
      'isDarkTheme': instance.isDarkTheme,
    };
