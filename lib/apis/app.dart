import 'package:json_annotation/json_annotation.dart';

part 'app.g.dart';

@JsonSerializable()
class AppState extends JsonSerializable {
  String? currentPage;
  bool? keepScreenOn;
  bool? isDarkTheme;

  @JsonKey(includeFromJson: false, includeToJson: false)
  bool? underControl;

  AppState({this.currentPage, this.keepScreenOn, this.isDarkTheme, this.underControl}) {
    underControl = false;
  }

  factory AppState.fromJson(Map<String, dynamic> json) =>
      _$AppStateFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$AppStateToJson(this);
}
