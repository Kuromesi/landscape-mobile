import 'package:json_annotation/json_annotation.dart';

part 'app.g.dart';

@JsonSerializable()
class AppState extends JsonSerializable {
  String? currentPage;
  bool? keepScreenOn;
  bool? isDarkTheme;

  AppState(
      {this.currentPage, this.keepScreenOn, this.isDarkTheme});

  factory AppState.fromJson(Map<String, dynamic> json) =>
      _$AppStateFromJson(json);

  Map<String, dynamic> toJson() => _$AppStateToJson(this);
}
